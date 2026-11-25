-- Лабораторная работа № 3. Онлайн-курсы.
-- Два обычных представления и материализованный отчёт (звезда).

CREATE OR REPLACE VIEW v_course_card AS
SELECT
    c.id AS course_id,
    c.title AS course_title,
    a.full_name AS author_name,
    c.level AS course_level,
    c.price,
    COUNT(DISTINCT l.id) AS lessons_count,
    COUNT(DISTINCT e.id) AS enrollments_count
FROM courses c
JOIN authors a ON a.id = c.author_id
LEFT JOIN lessons l ON l.course_id = c.id
LEFT JOIN enrollments e ON e.course_id = c.id
GROUP BY c.id, c.title, a.full_name, c.level, c.price;

CREATE OR REPLACE VIEW v_student_progress AS
SELECT
    e.id AS enrollment_id,
    s.full_name AS student_name,
    c.title AS course_title,
    e.status AS enrollment_status,
    COUNT(DISTINCT l.id) AS total_lessons,
    COUNT(lp.id) FILTER (WHERE lp.status = 'completed') AS completed_lessons
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.id = e.course_id
LEFT JOIN lessons l ON l.course_id = c.id
LEFT JOIN lesson_progress lp
    ON lp.enrollment_id = e.id AND lp.lesson_id = l.id
GROUP BY e.id, s.full_name, c.title, e.status;

-- ★ Материализованное представление для отчёта по курсам.
CREATE MATERIALIZED VIEW mv_course_report AS
SELECT
    course_id,
    course_title,
    author_name,
    course_level,
    price,
    lessons_count,
    enrollments_count
FROM v_course_card;
