
-- ЛР 4. Взаимоблокировка двух транзакций.

-- [setup] Создаём две тестовые записи.
DELETE FROM students
WHERE email IN (
    'lab4-deadlock-1@example.test',
    'lab4-deadlock-2@example.test'
);

INSERT INTO students (full_name, email)
VALUES
    ('Тестовая запись 1', 'lab4-deadlock-1@example.test'),
    ('Тестовая запись 2', 'lab4-deadlock-2@example.test');


-- [A] Окно A блокирует первую запись.
BEGIN;

UPDATE students
SET full_name = 'Окно A: первая запись'
WHERE email = 'lab4-deadlock-1@example.test';


-- [B] Окно B блокирует вторую запись.
BEGIN;

UPDATE students
SET full_name = 'Окно B: вторая запись'
WHERE email = 'lab4-deadlock-2@example.test';


-- [A] Окно A пытается изменить вторую запись.
-- expect: blocked
UPDATE students
SET full_name = 'Окно A: вторая запись'
WHERE email = 'lab4-deadlock-2@example.test';


-- [B] Окно B пытается изменить первую запись.
-- expect: error deadlock
UPDATE students
SET full_name = 'Окно B: первая запись'
WHERE email = 'lab4-deadlock-1@example.test';


-- [B] Отменяем транзакцию B.
ROLLBACK;


-- [A] Завершаем транзакцию A.
COMMIT;


-- [check] Проверяем, что изменения окна A сохранились.
-- expect: true
SELECT COUNT(*) = 2
   AND BOOL_AND(full_name LIKE 'Окно A:%') AS deadlock_resolved
FROM students
WHERE email IN (
    'lab4-deadlock-1@example.test',
    'lab4-deadlock-2@example.test'
);


-- [cleanup] Удаляем тестовые записи.
DELETE FROM students
WHERE email IN (
    'lab4-deadlock-1@example.test',
    'lab4-deadlock-2@example.test'
);