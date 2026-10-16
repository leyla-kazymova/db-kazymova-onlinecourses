
-- Лабораторная работа № 1
-- Тема № 10. Онлайн-курсы
-- Заполнение базы тестовыми данными

-- 1. Авторы курсов: 10 записей
INSERT INTO authors (full_name, email) VALUES
('Анна Иванова', 'author01@example.test'),
('Максим Петров', 'author02@example.test'),
('Елена Смирнова', 'author03@example.test'),
('Дмитрий Волков', 'author04@example.test'),
('Мария Соколова', 'author05@example.test'),
('Алексей Кузнецов', 'author06@example.test'),
('Ольга Морозова', 'author07@example.test'),
('Иван Попов', 'author08@example.test'),
('Наталья Васильева', 'author09@example.test'),
('Сергей Павлов', 'author10@example.test');

-- 2. Ученики: 10 записей
INSERT INTO students (full_name, email) VALUES
('Алина Сергеева', 'student01@example.test'),
('Кирилл Орлов', 'student02@example.test'),
('София Белова', 'student03@example.test'),
('Артём Николаев', 'student04@example.test'),
('Виктория Фёдорова', 'student05@example.test'),
('Михаил Егоров', 'student06@example.test'),
('Дарья Андреева', 'student07@example.test'),
('Никита Захаров', 'student08@example.test'),
('Полина Романова', 'student09@example.test'),
('Даниил Лебедев', 'student10@example.test');

-- 3. Курсы: 10 записей
-- Каждый курс связан с автором по author_id
INSERT INTO courses
(author_id, title, description, price, level)
VALUES
(1, 'Основы Python', 'Программирование на Python с нуля', 4990.00, 'beginner'),
(2, 'SQL и базы данных', 'Работа с реляционными базами данных', 5990.00, 'beginner'),
(3, 'Веб-разработка', 'Создание сайтов на HTML и CSS', 3990.00, 'beginner'),
(4, 'JavaScript', 'Основы программирования на JavaScript', 5490.00, 'intermediate'),
(5, 'Дизайн интерфейсов', 'Проектирование интерфейсов в Figma', 4490.00, 'beginner'),
(6, 'Разработка на Java', 'Объектно-ориентированное программирование', 6990.00, 'intermediate'),
(7, 'Анализ данных', 'Обработка и анализ данных', 7990.00, 'advanced'),
(8, 'Компьютерные сети', 'Основы сетевых технологий', 4590.00, 'beginner'),
(9, 'Мобильная разработка', 'Создание приложений для Android', 8990.00, 'advanced'),
(10, 'Основы Git', 'Контроль версий и работа с GitHub', 0.00, 'beginner');

-- 4. Уроки: 20 записей
-- Для каждого курса создаём два урока
INSERT INTO lessons
(course_id, title, lesson_number, duration_minutes)
SELECT
    c.id,
    CASE g.lesson_no
        WHEN 1 THEN 'Введение в курс: ' || c.title
        WHEN 2 THEN 'Практическое занятие: ' || c.title
    END,
    g.lesson_no,
    CASE g.lesson_no
        WHEN 1 THEN 35
        WHEN 2 THEN 60
    END
FROM courses c
CROSS JOIN generate_series(1, 2) AS g(lesson_no);

-- 5. Записи на курсы: 20 записей
-- Каждый ученик записывается на два курса
-- При чистом запуске ученики и курсы получают ID от 1 до 10
INSERT INTO enrollments
(student_id, course_id, status)
SELECT
    s.id,
    c.id,
    CASE
        WHEN c.id = s.id AND s.id % 3 = 0
            THEN 'completed'
        ELSE 'active'
    END
FROM students s
JOIN courses c
    ON c.id = s.id
    OR c.id = (s.id % 10) + 1;

-- 6. Прогресс учеников: 40 записей
-- У каждого зачисления есть прогресс по двум урокам
INSERT INTO lesson_progress
(enrollment_id, lesson_id, status, completed_at)
SELECT
    e.id,
    l.id,
    CASE
        WHEN l.lesson_number = 1 OR e.status = 'completed'
            THEN 'completed'
        ELSE 'available'
    END,
    CASE
        WHEN l.lesson_number = 1 OR e.status = 'completed'
            THEN now()
        ELSE NULL
    END
FROM enrollments e
JOIN lessons l ON l.course_id = e.course_id;
