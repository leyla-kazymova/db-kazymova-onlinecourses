-- Лабораторная работа № 3. Тема 10 «Онлайн-курсы».
-- Все демонстрационные изменения будут отменены dbcheck после выполнения.

-- 1. VIEW: карточка курса, объединённая из нескольких таблиц.
-- expect: rows
SELECT * FROM v_course_card ORDER BY course_id LIMIT 5;

-- 2. VIEW: прогресс учеников по урокам курсов.
-- expect: rows
SELECT * FROM v_student_progress ORDER BY enrollment_id LIMIT 5;

-- 3. Функция: сколько учеников записалось на первый курс?
-- expect: rows
SELECT course_enrollments(1) AS students_count;

-- 4. Бизнес-операция: завершить первый урок для тестовой записи на курс.
-- expect: rows
SELECT complete_lesson(e.id, l.id) AS progress_id
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN lessons l ON l.course_id = e.course_id
WHERE s.email = 'generated-student-1@example.test'
  AND l.lesson_number = 1
LIMIT 1;

-- 5. Проверка: первый урок действительно завершён.
-- expect: rows
SELECT e.id AS enrollment_id, l.lesson_number, p.status, p.completed_at
FROM lesson_progress p
JOIN enrollments e ON e.id = p.enrollment_id
JOIN students s ON s.id = e.student_id
JOIN lessons l ON l.id = p.lesson_id
WHERE s.email = 'generated-student-1@example.test'
  AND l.lesson_number = 1;

-- 6. ★ Функция с необязательными фильтрами: начальные курсы от 4000 до 6000.
-- expect: rows
SELECT * FROM filter_courses('beginner', 4000, 6000);

-- 7. ★ Обновление материала отчёта и его просмотр.
-- expect: rows
REFRESH MATERIALIZED VIEW mv_course_report;
SELECT * FROM mv_course_report ORDER BY enrollments_count DESC, course_id LIMIT 5;

-- 8. Служебные триггеры: обновить цену курса и увидеть запись в журнале.
-- expect: rows
UPDATE courses SET price = price + 10 WHERE id = 1;
SELECT course_id, operation,
       old_data ->> 'price' AS old_price,
       new_data ->> 'price' AS new_price,
       changed_by, changed_at
FROM course_audit
WHERE course_id = 1
ORDER BY id DESC LIMIT 1;

-- 9. ★★ Состояние курса на текущий момент из журнала изменений.
-- expect: rows
SELECT course_state_at(1, clock_timestamp()) AS course_state;

-- 10. Проверка бизнес-правила: запрещено открывать второй урок,
-- если первый ещё не пройден (ожидаем осмысленную ошибку триггера).
-- expect: error "Предыдущий урок"
INSERT INTO lesson_progress (enrollment_id, lesson_id, status)
SELECT e.id, l.id, 'available'
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN lessons l ON l.course_id = e.course_id
WHERE s.email = 'generated-student-2@example.test'
  AND l.lesson_number = 2
LIMIT 1;
