
-- Лабораторная работа № 1
-- Тема № 10. Онлайн-курсы
-- Проверка ограничений базы данных

-- 1. Проверка UNIQUE: повторяющийся email автора
-- expect: error unique
INSERT INTO authors (full_name, email)
VALUES ('Тестовый автор', 'author01@example.test');

-- 2. Проверка CHECK: отрицательная стоимость курса
-- expect: error check
INSERT INTO courses (author_id, title, price, level)
VALUES (1, 'Курс с ошибочной ценой', -100, 'beginner');

-- 3. Проверка FOREIGN KEY: несуществующий автор
-- expect: error fk
INSERT INTO courses (author_id, title, price, level)
VALUES (999999, 'Курс без существующего автора', 1500, 'beginner');
