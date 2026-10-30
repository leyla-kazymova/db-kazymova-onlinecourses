
-- Лабораторная работа № 1
-- Тема № 10. Онлайн-курсы
-- Генерация более 1000 записей

-- 1. Создаём 1200 дополнительных учеников
INSERT INTO students (full_name, email)
SELECT
    'Тестовый ученик ' || n,
    'generated-student-' || n || '@example.test'
FROM generate_series(1, 1200) AS g(n);

-- 2. Записываем каждого нового ученика на один курс
-- Создаём ещё 1200 записей на курсы
INSERT INTO enrollments (student_id, course_id, status)
SELECT
    s.id,
    ((s.id - 1) % 10) + 1,
    'active'
FROM students s
WHERE s.email LIKE 'generated-student-%@example.test';
