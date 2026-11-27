-- ЛР 4. REPEATABLE READ

-- [setup] Создаём тестового ученика
DELETE FROM students
WHERE email = 'lab4-isolation@example.test';

INSERT INTO students (full_name, email)
VALUES ('Тестовый ученик 100', 'lab4-isolation@example.test');


-- [A] Первое чтение
-- expect: value 100
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT RIGHT(full_name, 3)::integer AS version
FROM students
WHERE email = 'lab4-isolation@example.test';


-- [B] Меняем данные и сохраняем
BEGIN;

UPDATE students
SET full_name = 'Тестовый ученик 200'
WHERE email = 'lab4-isolation@example.test';

COMMIT;


-- [A] Второе чтение показывает прежнее значение
-- expect: value 100
SELECT RIGHT(full_name, 3)::integer AS version
FROM students
WHERE email = 'lab4-isolation@example.test';

COMMIT;


-- [check] Проверяем сохранённое изменение
-- expect: true
SELECT full_name = 'Тестовый ученик 200'
FROM students
WHERE email = 'lab4-isolation@example.test';


-- [cleanup] Удаляем тестовые данные
DELETE FROM students
WHERE email = 'lab4-isolation@example.test';