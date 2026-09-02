@echo off
setlocal

echo =========================================================================
echo  [WARNING] RESET MATHOS LOCAL DEVELOPMENT DATABASE
echo =========================================================================
echo  This script will PERMANENTLY DESTROY all local user accounts,
echo  profiles, and database tables in your local Docker volume!
echo =========================================================================
echo.
set /p CONFIRM="Are you sure you want to PURGE all local database data? (y/N): "

if /i "%CONFIRM%" neq "y" (
    echo Reset cancelled. No data was deleted.
    exit /b 0
)

set SCRIPT_DIR=%~dp0
set REPO_ROOT=%SCRIPT_DIR%..
set SERVER_DIR=%REPO_ROOT%\server

cd /d "%SERVER_DIR%"
echo Purging containers and named Docker database volumes...
docker compose down -v

echo.
echo [OK] Local database volume purged successfully.
echo Run Start_Mathos_Server.bat to initialize a fresh empty database.
echo.
