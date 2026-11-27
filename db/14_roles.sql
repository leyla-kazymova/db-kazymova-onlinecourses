-- ЛР 4. Роли и права доступа.

\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD

-- Создание ролей.
SELECT 'CREATE ROLE app_reader LOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'app_reader'
)
\gexec

SELECT 'CREATE ROLE app_writer LOGIN'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'app_writer'
)
\gexec

ALTER ROLE app_reader LOGIN PASSWORD :'reader_password';
ALTER ROLE app_writer LOGIN PASSWORD :'writer_password';

GRANT app_reader TO app_writer;

-- Запрет прямого доступа к таблицам.
REVOKE ALL ON ALL TABLES IN SCHEMA public
FROM app_reader, app_writer;

REVOKE ALL ON ALL SEQUENCES IN SCHEMA public
FROM app_reader, app_writer;

-- Запрет вызова функций всем пользователям по умолчанию.
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;

ALTER DEFAULT PRIVILEGES
REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public
FROM app_reader, app_writer;

-- Доступ к схеме.
GRANT USAGE ON SCHEMA public
TO app_reader, app_writer;

-- app_reader может читать только представления.
GRANT SELECT ON v_course_card, v_student_progress
TO app_reader;

-- app_writer выполняет бизнес-операцию через функцию.
ALTER FUNCTION complete_lesson(integer, integer)
SECURITY DEFINER;

ALTER FUNCTION complete_lesson(integer, integer)
SET search_path = public, pg_temp;

GRANT EXECUTE ON FUNCTION complete_lesson(integer, integer)
TO app_writer;