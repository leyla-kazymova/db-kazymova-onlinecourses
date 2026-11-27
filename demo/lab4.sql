-- ЛР 4. Транзакции и доступ

-- 1. Проверяем первоначальную цену курса.
-- expect: rows
SELECT price
FROM courses
WHERE id = 1;

-- 2. Изменяем цену, затем специально вызываем ошибку CHECK.
-- expect: error check
BEGIN;

UPDATE courses
SET price = price + 100
WHERE id = 1;

UPDATE courses
SET price = -1
WHERE id = 1;

-- 3. Отменяем транзакцию и проверяем исходную цену.
-- expect: same 1
ROLLBACK;

SELECT price
FROM courses
WHERE id = 1;

-- 4. Проверяем успешное завершение транзакции.
-- expect: rows
BEGIN;

SELECT price
FROM courses
WHERE id = 1;

COMMIT;
-- 5. Переключаемся на роль app_reader.
SET ROLE app_reader;

-- 6. Чтение представления разрешено.
-- expect: rows
SELECT * FROM v_course_card LIMIT 2;

-- 7. Чтение обычной таблицы запрещено.
-- expect: error permission
SELECT * FROM courses LIMIT 1;

-- 8. Изменение таблицы запрещено.
-- expect: error permission
UPDATE courses SET price = price + 1 WHERE id = -1;

-- 9. Возвращаем права администратора.
RESET ROLE;

-- 10. Переключаемся на роль app_writer.
SET ROLE app_writer;

-- 11. Прямое чтение таблицы запрещено.
-- expect: error permission
SELECT * FROM lesson_progress LIMIT 1;

-- 12. Прямое изменение таблицы запрещено.
-- expect: error permission
DELETE FROM lesson_progress WHERE id = -1;

-- 13. Возвращаем права администратора.
RESET ROLE;