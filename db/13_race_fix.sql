-- ЛР 4. Исправление гонки через блокировку записи на курс.

CREATE OR REPLACE FUNCTION safe_open_lesson(
    p_enrollment_id integer,
    p_lesson_id integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_progress_id integer;
BEGIN
    PERFORM 1
    FROM enrollments
    WHERE id = p_enrollment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Enrollment not found';
    END IF;

    INSERT INTO lesson_progress
        (enrollment_id, lesson_id, status)
    VALUES
        (p_enrollment_id, p_lesson_id, 'available')
    ON CONFLICT (enrollment_id, lesson_id)
    DO UPDATE SET
        status = 'available',
        completed_at = NULL
    RETURNING id INTO v_progress_id;

    RETURN v_progress_id;
END;
$$;


CREATE OR REPLACE FUNCTION safe_uncomplete_lesson(
    p_enrollment_id integer,
    p_lesson_id integer
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    v_lesson_number integer;
BEGIN
    PERFORM 1
    FROM enrollments
    WHERE id = p_enrollment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Enrollment not found';
    END IF;

    SELECT l.lesson_number
    INTO v_lesson_number
    FROM lessons l
    JOIN enrollments e ON e.course_id = l.course_id
    WHERE e.id = p_enrollment_id
      AND l.id = p_lesson_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lesson not found in course';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM lesson_progress p
        JOIN lessons l ON l.id = p.lesson_id
        WHERE p.enrollment_id = p_enrollment_id
          AND l.lesson_number > v_lesson_number
    ) THEN
        RETURN FALSE;
    END IF;

    UPDATE lesson_progress
    SET status = 'available',
        completed_at = NULL
    WHERE enrollment_id = p_enrollment_id
      AND lesson_id = p_lesson_id;

    RETURN FOUND;
END;
$$;