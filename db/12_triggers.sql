-- Лабораторная работа № 3. Правило последовательного прохождения уроков
-- и журнал изменений таблицы courses.

-- 1. Бизнес-правило: следующий урок доступен только после завершения предыдущего.
CREATE OR REPLACE FUNCTION check_lesson_order()
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_enrollment_course_id integer;
    v_lesson_course_id integer;
    v_lesson_number integer;
BEGIN
    SELECT e.course_id, l.course_id, l.lesson_number
      INTO v_enrollment_course_id, v_lesson_course_id, v_lesson_number
    FROM enrollments e
    CROSS JOIN lessons l
    WHERE e.id = NEW.enrollment_id
      AND l.id = NEW.lesson_id;

    -- Если родительской записи нет, внешние ключи вернут свою ошибку.
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    IF v_enrollment_course_id <> v_lesson_course_id THEN
        RAISE EXCEPTION 'Урок не относится к курсу записи';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM lessons prev
        WHERE prev.course_id = v_lesson_course_id
          AND prev.lesson_number < v_lesson_number
          AND NOT EXISTS (
              SELECT 1
              FROM lesson_progress p
              WHERE p.enrollment_id = NEW.enrollment_id
                AND p.lesson_id = prev.id
                AND p.status = 'completed'
          )
    ) THEN
        RAISE EXCEPTION 'Предыдущий урок не завершён';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_lesson_order
BEFORE INSERT OR UPDATE ON lesson_progress
FOR EACH ROW EXECUTE FUNCTION check_lesson_order();

-- 2. Служебный триггер: ставит время обновления курса.
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS updated_at timestamptz;
UPDATE courses SET updated_at = created_at WHERE updated_at IS NULL;

CREATE OR REPLACE FUNCTION set_course_updated_at()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_course_updated_at
BEFORE UPDATE ON courses
FOR EACH ROW EXECUTE FUNCTION set_course_updated_at();

-- 3. ★★ Журнал изменений курсов: старое/новое состояние, пользователь, время.
CREATE OR REPLACE FUNCTION audit_course_change()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO course_audit
            (course_id, operation, old_data, new_data, changed_by, changed_at)
        VALUES (NEW.id, TG_OP, NULL::jsonb, to_jsonb(NEW), session_user, clock_timestamp());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO course_audit
            (course_id, operation, old_data, new_data, changed_by, changed_at)
        VALUES (NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW), session_user, clock_timestamp());
        RETURN NEW;
    ELSE
        INSERT INTO course_audit
            (course_id, operation, old_data, new_data, changed_by, changed_at)
        VALUES (OLD.id, TG_OP, to_jsonb(OLD), NULL::jsonb, session_user, clock_timestamp());
        RETURN OLD;
    END IF;
END;
$$;

CREATE TRIGGER trg_audit_courses
AFTER INSERT OR UPDATE OR DELETE ON courses
FOR EACH ROW EXECUTE FUNCTION audit_course_change();

-- Исходное состояние курсов, существовавших до установки триггера.
INSERT INTO course_audit
    (course_id, operation, old_data, new_data, changed_by, changed_at)
SELECT c.id, 'INSERT', NULL::jsonb, to_jsonb(c), session_user, clock_timestamp()
FROM courses c;
