@echo off
setlocal enabledelayedexpansion

echo =========================================================================
echo  Mathos Local Auth ^& Database Engine Startup
echo =========================================================================

REM 1. Check if Docker CLI exists
where docker >nul 2>nul
if %errorlevel% neq 0 goto NO_DOCKER

REM 2. Check if Docker Engine is running
docker info >nul 2>nul
if %errorlevel% equ 0 goto DOCKER_READY

echo [NOTICE] Docker Engine is not currently running. Attempting to start Docker Desktop...
if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
) else (
    echo [WARNING] Docker Desktop executable not found at default location.
    echo Please launch Docker Desktop manually.
)

echo Waiting for Docker Engine to initialize (timeout 60 seconds)...
set /a RETRIES=0

:WAIT_DOCKER
ping 127.0.0.1 -n 4 >nul
docker info >nul 2>nul
if %errorlevel% equ 0 goto DOCKER_READY

set /a RETRIES+=3
if !RETRIES! geq 60 (
    echo [ERROR] Bounded timeout reached (60s). Docker Engine did not start in time.
    echo Please ensure Docker Desktop is running and try again.
    pause
    exit /b 1
)
echo Waiting for Docker Engine (!RETRIES!s / 60s)...
goto WAIT_DOCKER

:DOCKER_READY
echo [OK] Docker Engine is ready!

REM 3. Initialize local .env if missing on first launch
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
set "SERVER_DIR=%REPO_ROOT%\server"

if not exist "%SERVER_DIR%\.env" (
    echo [INFO] First launch detected. Initializing local .env from .env.example...
    copy "%SERVER_DIR%\.env.example" "%SERVER_DIR%\.env" >nul
    echo [OK] Generated local .env file.
)

REM 4. Build and start containers in background
echo Starting Mathos backend services in background...
cd /d "%SERVER_DIR%"
docker compose up -d --build
if %errorlevel% neq 0 (
    echo [ERROR] Docker compose failed to start services.
    pause
    exit /b 1
)

REM 5. Wait for API and DB health checks
echo Waiting for API ^& PostgreSQL health checks (timeout 45 seconds)...
set /a HEALTH_RETRIES=0

:WAIT_HEALTH
ping 127.0.0.1 -n 3 >nul
curl -s http://127.0.0.1:8080/api/v1/health | findstr /i "healthy" >nul 2>nul
if %errorlevel% equ 0 goto HEALTH_SUCCESS

set /a HEALTH_RETRIES+=2
if !HEALTH_RETRIES! geq 45 goto HEALTH_TIMEOUT
echo Waiting for API healthcheck (!HEALTH_RETRIES!s / 45s)...
goto WAIT_HEALTH

:HEALTH_SUCCESS
echo.
echo =========================================================================
echo [SUCCESS] Mathos Local Services are HEALTHY ^& RUNNING IN BACKGROUND!
echo =========================================================================
echo  API Endpoint:  http://127.0.0.1:8080/api/v1/health
echo  API Docs:      http://127.0.0.1:8080/api/v1/docs
echo  Mailpit Web:   http://127.0.0.1:8025
echo =========================================================================
echo.
exit /b 0

:HEALTH_TIMEOUT
echo [WARNING] API healthcheck did not complete within 45s.
echo Checking container status...
docker compose ps
exit /b 0

:NO_DOCKER
echo [ERROR] Docker CLI was not found on your PATH.
echo.
echo PREREQUISITE REQUIRED:
echo Please install Docker Desktop for Windows from https://www.docker.com/products/docker-desktop/
echo After installing, restart your computer and run this script again.
echo.
pause
exit /b 1
