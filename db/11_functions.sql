-- Лабораторная работа № 3. Функции.

-- ★★ Таблица журнала нужна для функции восстановления состояния курса.
CREATE TABLE IF NOT EXISTS course_audit (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id integer NOT NULL,
    operation text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_by text NOT NULL,
    changed_at timestamptz NOT NULL
);

-- Простая функция: сколько учеников записано на курс.
CREATE OR REPLACE FUNCTION course_enrollments(p_course_id integer)
RETURNS bigint
LANGUAGE sql STABLE AS $$
    SELECT COUNT(*) FROM enrollments WHERE course_id = p_course_id;
$$;

-- Бизнес-операция одной командой: ученик завершает урок.
-- Триггер (из файла 12_triggers.sql) проверяет порядок прохождения.
CREATE OR REPLACE FUNCTION complete_lesson(
    p_enrollment_id integer,
    p_lesson_id integer
)
RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_progress_id integer;
BEGIN
    INSERT INTO lesson_progress (enrollment_id, lesson_id, status, completed_at)
    VALUES (p_enrollment_id, p_lesson_id, 'completed', clock_timestamp())
    ON CONFLICT (enrollment_id, lesson_id)
    DO UPDATE SET
        status = 'completed',
        completed_at = clock_timestamp()
    RETURNING id INTO v_progress_id;

    RETURN v_progress_id;
END;
$$;

-- ★ Функция с необязательными параметрами-фильтрами.
CREATE OR REPLACE FUNCTION filter_courses(
    p_level text DEFAULT NULL,
    p_min_price numeric DEFAULT NULL,
    p_max_price numeric DEFAULT NULL
)
RETURNS TABLE (
    course_id integer,
    course_title text,
    course_level text,
    price numeric,
    enrollments_count bigint
)
LANGUAGE sql STABLE AS $$
    SELECT
        v.course_id,
        v.course_title,
        v.course_level,
        v.price,
        v.enrollments_count
    FROM v_course_card v
    WHERE (p_level IS NULL OR v.course_level = p_level)
      AND (p_min_price IS NULL OR v.price >= p_min_price)
      AND (p_max_price IS NULL OR v.price <= p_max_price)
    ORDER BY v.price DESC, v.course_id;
$$;

-- ★★ Восстановление состояния курса на указанный момент по журналу.
CREATE OR REPLACE FUNCTION course_state_at(
    p_course_id integer,
    p_moment timestamptz
)
RETURNS jsonb
LANGUAGE sql STABLE AS $$
    SELECT CASE
               WHEN a.operation = 'DELETE' THEN NULL::jsonb
               ELSE a.new_data
           END
    FROM course_audit a
    WHERE a.course_id = p_course_id
      AND a.changed_at <= p_moment
    ORDER BY a.changed_at DESC, a.id DESC
    LIMIT 1;
$$;
