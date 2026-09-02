@echo off
setlocal

echo =========================================================================
echo  Stopping Mathos Local Auth & Database Engine
echo =========================================================================

set SCRIPT_DIR=%~dp0
set REPO_ROOT=%SCRIPT_DIR%..
set SERVER_DIR=%REPO_ROOT%\server

cd /d "%SERVER_DIR%"
docker compose down

echo.
echo [OK] Mathos backend services stopped cleanly. Database volume preserved.
echo.
