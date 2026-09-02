@echo off
setlocal

echo =========================================================================
echo  Mathos Local Auth ^& Database Engine Status
echo =========================================================================

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
set "SERVER_DIR=%REPO_ROOT%\server"

cd /d "%SERVER_DIR%"
echo --- Container Status ---
docker compose ps

echo.
echo --- Healthcheck Status ---
curl -s http://127.0.0.1:8080/api/v1/health
if %errorlevel% neq 0 (
    echo [OFFLINE] API is not responding on http://127.0.0.1:8080
)

echo.
echo =========================================================================
echo  Local Service URLs:
echo  - API:         http://127.0.0.1:8080/api/v1/health
echo  - API Docs:    http://127.0.0.1:8080/api/v1/docs
echo  - Mailpit UI:  http://127.0.0.1:8025
echo =========================================================================
echo.
