-- ЛР 4. Row Level Security.
-- Ученики видят только свои записи на курсы.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'lab4_student_1'
    ) THEN
        CREATE ROLE lab4_student_1 NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'lab4_student_2'
    ) THEN
        CREATE ROLE lab4_student_2 NOLOGIN;
    END IF;
END;
$$;

GRANT USAGE ON SCHEMA public
TO lab4_student_1, lab4_student_2;

GRANT SELECT ON enrollments
TO lab4_student_1, lab4_student_2;

ALTER TABLE enrollments
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS enrollments_only_own
ON enrollments;

CREATE POLICY enrollments_only_own
ON enrollments
FOR SELECT
TO lab4_student_1, lab4_student_2
USING (
    (current_user = 'lab4_student_1' AND student_id = 1)
    OR
    (current_user = 'lab4_student_2' AND student_id = 2)
);