# Mathos Local Backend & Authentication Infrastructure

Production-ready local development backend for Mathos using FastAPI, SQLAlchemy 2, Alembic, PostgreSQL 16, and Mailpit.

## Architecture

- **mathos-api**: Python 3.11 + FastAPI + Uvicorn + SQLAlchemy 2 + Alembic + Pydantic v2 Settings.
- **mathos-db**: PostgreSQL 16 (internal Compose network only).
- **mathos-mailpit**: Mailpit local SMTP & Web UI for testing emails without external network calls.

## Quick Start (Windows)

To start all services automatically in the background:

1. Double-click `scripts/Start_Mathos_Server.bat`.
2. Access local API docs at `http://127.0.0.1:8080/api/v1/docs`.
3. Access local Mailpit email UI at `http://127.0.0.1:8025`.

To stop services (preserving database volume):

- Double-click `scripts/Stop_Mathos_Server.bat`.

To view status:

- Double-click `scripts/Mathos_Server_Status.bat`.

## Godot Integration Contract

Local API Base Endpoint:

```
http://127.0.0.1:8080
```

Future Godot HTTPClient services will consume endpoints under `/api/v1/`.

## Endpoints

- `GET /api/v1/health`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `GET /api/v1/auth/google` (returns `NOT_CONFIGURED`)
- `GET /api/v1/me/profile`
- `PATCH /api/v1/me/profile`
