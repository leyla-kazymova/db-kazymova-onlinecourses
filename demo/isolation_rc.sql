-- ЛР 4. READ COMMITTED

-- [setup] Создаём тестового ученика
DELETE FROM students
WHERE email = 'lab4-isolation@example.test';

INSERT INTO students (full_name, email)
VALUES ('Тестовый ученик 100', 'lab4-isolation@example.test');


-- [A] Первое чтение
-- expect: value 100
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT RIGHT(full_name, 3)::integer AS version
FROM students
WHERE email = 'lab4-isolation@example.test';


-- [B] Меняем данные и сохраняем
BEGIN;

UPDATE students
SET full_name = 'Тестовый ученик 200'
WHERE email = 'lab4-isolation@example.test';

COMMIT;


-- [A] Второе чтение показывает новое значение
-- expect: value 200
SELECT RIGHT(full_name, 3)::integer AS version
FROM students
WHERE email = 'lab4-isolation@example.test';

COMMIT;


-- [check] Проверяем результат
-- expect: true
SELECT full_name = 'Тестовый ученик 200'
FROM students
WHERE email = 'lab4-isolation@example.test';


-- [cleanup] Удаляем тестовые данные
DELETE FROM students
WHERE email = 'lab4-isolation@example.test';