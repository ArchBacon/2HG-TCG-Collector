@echo off
rem First time setup for the API: dependencies, database, schema, first admin login and CSS.
rem Set DATABASE_URL, ADMIN_USERNAME and ADMIN_PASSWORD in .env.local before running this.
setlocal
cd /d "%~dp0"

call composer install || goto :error
call npm install || goto :error

php bin/console doctrine:database:create --if-not-exists || goto :error
php bin/console doctrine:migrations:migrate --no-interaction || goto :error
rem --append, otherwise the fixtures purge the whole database first.
php bin/console doctrine:fixtures:load --append --no-interaction || goto :error

php bin/console tailwind:build || goto :error

echo Setup done.
pause
exit /b 0

:error
echo Setup failed, see the error above.
pause
exit /b 1
