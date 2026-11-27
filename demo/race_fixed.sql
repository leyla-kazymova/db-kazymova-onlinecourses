-- ЛР 4. Гонка с защитой.

-- [setup] Подготавливаем тестовые данные.
DELETE FROM lesson_progress
WHERE enrollment_id IN (
    SELECT e.id
    FROM enrollments e
    JOIN students s ON s.id = e.student_id
    WHERE s.email = 'generated-student-1@example.test'
);

INSERT INTO lesson_progress
    (enrollment_id, lesson_id, status, completed_at)
SELECT e.id, l.id, 'completed', clock_timestamp()
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN lessons l ON l.course_id = e.course_id
WHERE s.email = 'generated-student-1@example.test'
  AND l.lesson_number = 1;


-- [A] Окно A начинает транзакцию.
BEGIN;

-- [A] Открываем второй урок с блокировкой.
SELECT safe_open_lesson(e.id, l.id)
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN lessons l ON l.course_id = e.course_id
WHERE s.email = 'generated-student-1@example.test'
  AND l.lesson_number = 2;


-- [B] Окно B начинает транзакцию.
BEGIN;

-- [B] Пытаемся отменить первый урок. Ожидаем блокировку.
-- expect: blocked
SELECT safe_uncomplete_lesson(e.id, l.id)
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN lessons l ON l.course_id = e.course_id
WHERE s.email = 'generated-student-1@example.test'
  AND l.lesson_number = 1;


-- [A] Завершаем первую транзакцию.
COMMIT;

-- [B] Завершаем вторую транзакцию.
COMMIT;


-- [check] Проверяем, что правило не нарушено.
-- expect: true
SELECT NOT EXISTS (
    SELECT 1
    FROM enrollments e
    JOIN students s ON s.id = e.student_id
    JOIN lessons l1 ON l1.course_id = e.course_id
                   AND l1.lesson_number = 1
    JOIN lessons l2 ON l2.course_id = e.course_id
                   AND l2.lesson_number = 2
    JOIN lesson_progress p1
        ON p1.enrollment_id = e.id AND p1.lesson_id = l1.id
    JOIN lesson_progress p2
        ON p2.enrollment_id = e.id AND p2.lesson_id = l2.id
    WHERE s.email = 'generated-student-1@example.test'
      AND p1.status <> 'completed'
) AS lesson_order_ok;


-- [cleanup] Удаляем тестовые изменения.
DELETE FROM lesson_progress
WHERE enrollment_id IN (
    SELECT e.id
    FROM enrollments e
    JOIN students s ON s.id = e.student_id
    WHERE s.email = 'generated-student-1@example.test'
);