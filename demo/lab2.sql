-- 1. Какие ученики записаны на какие курсы и каков статус их обучения?
-- expect: rows

SELECT
    s.full_name AS student_name,
    c.title AS course_title,
    e.status
FROM enrollments AS e
JOIN students AS s ON s.id = e.student_id
JOIN courses AS c ON c.id = e.course_id
ORDER BY s.id, c.id
LIMIT 10;

-- 2. Кто является автором каждого курса и сколько стоит этот курс?
-- expect: rows

SELECT
    c.title AS course_title,
    a.full_name AS author_name,
    c.price
FROM courses AS c
JOIN authors AS a ON a.id = c.author_id
ORDER BY c.id;

-- 3. Какие уроки входят в каждый курс и сколько минут они длятся?
-- expect: rows

SELECT
    c.title AS course_title,
    l.lesson_number,
    l.title AS lesson_title,
    l.duration_minutes
FROM courses AS c
JOIN lessons AS l ON l.course_id = c.id
ORDER BY c.id, l.lesson_number;

-- 4. Сколько учеников записано на каждый курс?
-- expect: rows

SELECT
    c.title AS course_title,
    COUNT(e.id) AS students_count
FROM courses AS c
LEFT JOIN enrollments AS e ON e.course_id = c.id
GROUP BY c.id, c.title
ORDER BY students_count DESC, c.id;

-- 5. Какие статусы обучения встречаются более 100 раз?
-- expect: rows

SELECT
    status,
    COUNT(*) AS enrollments_count
FROM enrollments
GROUP BY status
HAVING COUNT(*) > 100
ORDER BY enrollments_count DESC;


-- 6. Какие записи на курсы пока не имеют данных о прохождении уроков?
-- expect: rows

SELECT
    s.full_name AS student_name,
    c.title AS course_title
FROM enrollments AS e
JOIN students AS s ON s.id = e.student_id
JOIN courses AS c ON c.id = e.course_id
LEFT JOIN lesson_progress AS lp ON lp.enrollment_id = e.id
WHERE lp.id IS NULL
ORDER BY e.id
LIMIT 10;


-- 7. Какие ученики уже завершили хотя бы один курс?
-- expect: rows

SELECT
    s.id,
    s.full_name
FROM students AS s
WHERE s.id IN (
    SELECT e.student_id
    FROM enrollments AS e
    WHERE e.status = 'completed'
)
ORDER BY s.id;


-- 8. Какие курсы стоят дороже средней стоимости всех курсов?
-- expect: rows

SELECT
    c.title,
    c.price
FROM courses AS c
WHERE c.price > (
    SELECT AVG(c2.price)
    FROM courses AS c2
)
ORDER BY c.price DESC;


-- 9. Как добавить нового автора и проверить результат?
-- expect: rows

BEGIN;

SELECT COUNT(*) AS before_insert
FROM authors
WHERE email = 'lab2-insert@example.test';

INSERT INTO authors (full_name, email)
VALUES ('Тестовый автор ЛР2', 'lab2-insert@example.test');

SELECT id, full_name, email
FROM authors
WHERE email = 'lab2-insert@example.test';

ROLLBACK;


-- 10. Как изменить стоимость курса и проверить результат?
-- expect: rows

BEGIN;

SELECT id, title, price
FROM courses
WHERE id = 1;

UPDATE courses
SET price = price + 100
WHERE id = 1;

SELECT id, title, price
FROM courses
WHERE id = 1;

ROLLBACK;


-- 11. Как удалить тестового ученика и убедиться, что он удалён?
-- expect: value 0

BEGIN;

INSERT INTO students (full_name, email)
VALUES ('Ученик для удаления', 'lab2-delete@example.test');

SELECT id, full_name, email
FROM students
WHERE email = 'lab2-delete@example.test';

DELETE FROM students
WHERE email = 'lab2-delete@example.test';

SELECT COUNT(*) AS after_delete
FROM students
WHERE email = 'lab2-delete@example.test';

ROLLBACK;


-- 12. Сколько завершённых уроков приходится на каждый курс?
-- expect: rows

SELECT
    c.title AS course_title,
    COUNT(lp.id) AS completed_lessons
FROM courses AS c
JOIN lessons AS l ON l.course_id = c.id
LEFT JOIN lesson_progress AS lp
    ON lp.lesson_id = l.id AND lp.status = 'completed'
GROUP BY c.id, c.title
ORDER BY completed_lessons DESC, c.id;


-- 13. Какие три самых дорогих курса в каждом уровне сложности?
-- expect: rows

WITH ranked_courses AS (
    SELECT
        title,
        level,
        price,
        ROW_NUMBER() OVER (
            PARTITION BY level
            ORDER BY price DESC, id
        ) AS course_rank
    FROM courses
)
SELECT
    level,
    title,
    price,
    course_rank
FROM ranked_courses
WHERE course_rank <= 3
ORDER BY level, course_rank;


-- 14. Как накапливается общая стоимость курсов по их номерам?
-- expect: rows

SELECT
    id,
    title,
    price,
    SUM(price) OVER (
        ORDER BY id
    ) AS cumulative_price
FROM courses
ORDER BY id;


-- 15. Как менялось количество записей на курсы по месяцам?
-- expect: rows

WITH months AS (
    SELECT generate_series(
        date_trunc('month', CURRENT_DATE) - interval '5 months',
        date_trunc('month', CURRENT_DATE),
        interval '1 month'
    ) AS month
),
monthly_counts AS (
    SELECT
        date_trunc('month', enrolled_at) AS month,
        COUNT(*) AS enrollments_count
    FROM enrollments
    GROUP BY date_trunc('month', enrolled_at)
),
monthly_data AS (
    SELECT
        m.month,
        COALESCE(mc.enrollments_count, 0) AS enrollments_count
    FROM months AS m
    LEFT JOIN monthly_counts AS mc ON mc.month = m.month
),
monthly_growth AS (
    SELECT
        month,
        enrollments_count,
        LAG(enrollments_count) OVER (
            ORDER BY month
        ) AS previous_month
    FROM monthly_data
)
SELECT
    month,
    enrollments_count,
    previous_month,
    CASE
        WHEN previous_month > 0 THEN
            ROUND(
                (enrollments_count - previous_month) * 100.0
                / previous_month,
                2
            )
        ELSE NULL
    END AS growth_percent
FROM monthly_growth
ORDER BY month;


-- 16. Сколько учеников записывалось на курсы по дням
-- текущего месяца, включая дни без записей?
-- expect: rows

WITH RECURSIVE calendar AS (
    SELECT date_trunc('month', CURRENT_DATE)::date AS day

    UNION ALL

    SELECT day + 1
    FROM calendar
    WHERE day < CURRENT_DATE
),
daily_counts AS (
    SELECT
        enrolled_at::date AS day,
        COUNT(*) AS enrollments_count
    FROM enrollments
    GROUP BY enrolled_at::date
)
SELECT
    c.day,
    COALESCE(d.enrollments_count, 0) AS enrollments_count
FROM calendar AS c
LEFT JOIN daily_counts AS d ON d.day = c.day
ORDER BY c.day;
