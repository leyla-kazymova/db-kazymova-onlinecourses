-- ЛР 4. Проверка RLS.

-- 1. Первый ученик видит только свои записи.
SET ROLE lab4_student_1;

-- expect: true
SELECT COUNT(*) > 0
   AND BOOL_AND(student_id = 1) AS only_my_enrollments
FROM enrollments;

RESET ROLE;

-- 2. Второй ученик видит только свои записи.
SET ROLE lab4_student_2;

-- expect: true
SELECT COUNT(*) > 0
   AND BOOL_AND(student_id = 2) AS only_my_enrollments
FROM enrollments;

RESET ROLE;

-- 3. Проверяем, что RLS включён.
-- expect: true
SELECT relrowsecurity
FROM pg_class
WHERE oid = 'public.enrollments'::regclass;

-- 4. Проверяем наличие политики.
-- expect: true
SELECT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'enrollments'
      AND policyname = 'enrollments_only_own'
);