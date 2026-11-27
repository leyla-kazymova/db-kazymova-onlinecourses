# ЛР 4. Резервное копирование и восстановление PostgreSQL.
# Основная база app не удаляется и не изменяется.

# 1. Создаём резервную копию основной базы.
docker compose exec -T db pg_dump -U postgres -d app -Fc -f /tmp/lab4_backup.dump
if ($LASTEXITCODE -ne 0) { throw "Ошибка pg_dump" }

# 2. Сохраняем копию на компьютер вне Git-репозитория.
docker compose cp db:/tmp/lab4_backup.dump ../lab4_backup.dump
if ($LASTEXITCODE -ne 0) { throw "Ошибка копирования" }

# 3. Удаляем только тестовую базу прошлого восстановления.
docker compose exec -T db dropdb -U postgres --if-exists lab4_restore_test
if ($LASTEXITCODE -ne 0) { throw "Ошибка удаления тестовой базы" }

# 4. Создаём новую пустую тестовую базу.
docker compose exec -T db createdb -U postgres lab4_restore_test
if ($LASTEXITCODE -ne 0) { throw "Ошибка создания тестовой базы" }

# 5. Восстанавливаем данные из резервной копии.
docker compose exec -T db pg_restore -U postgres -d lab4_restore_test --exit-on-error /tmp/lab4_backup.dump
if ($LASTEXITCODE -ne 0) { throw "Ошибка pg_restore" }

# 6. Проверяем восстановленные данные.
docker compose exec -T db psql -U postgres -d lab4_restore_test -c "SELECT (SELECT COUNT(*) FROM students) AS students, (SELECT COUNT(*) FROM courses) AS courses, (SELECT COUNT(*) FROM enrollments) AS enrollments;"
if ($LASTEXITCODE -ne 0) { throw "Ошибка проверки данных" }

Write-Output "Backup and restore completed successfully."