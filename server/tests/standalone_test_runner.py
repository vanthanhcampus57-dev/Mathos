import os
import sys
import asyncio
import uuid
from datetime import datetime, timezone

# Ensure server root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import select

from app.core.database import Base, get_db
from app.core.security import hash_token
from app.main import app
from app.models import User, AuthIdentity, AuthSession, PasswordResetToken

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

async def run_all_tests():
    print("==================================================")
    print("RUNNING MATHOS BACKEND STANDALONE SUITE")
    print("==================================================")

    # 1. Setup in-memory SQLite engine
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = async_sessionmaker(engine, expire_on_commit=False)

    passed_count = 0
    failed_count = 0

    async def execute_test(test_name, test_coro):
        nonlocal passed_count, failed_count
        async with async_session() as session:
            async def _override_get_db():
                yield session

            app.dependency_overrides[get_db] = _override_get_db
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                try:
                    await test_coro(client, session)
                    print(f"  [PASS] {test_name}")
                    passed_count += 1
                except Exception as e:
                    print(f"  [FAIL] {test_name}: {e}")
                    import traceback
                    traceback.print_exc()
                    failed_count += 1
                finally:
                    app.dependency_overrides.clear()
                    await session.rollback()

    # Define test cases
    async def test_health(client, session):
        resp = await client.get("/api/v1/health")
        assert resp.status_code == 200, f"Expected 200, got {resp.status_code}"
        data = resp.json()
        assert data["status"] == "healthy"
        assert data["database"] == "connected"

    async def test_register_success(client, session):
        payload = {"email": "player1@mathos.local", "password": "Password123", "display_name": "Player One"}
        resp = await client.post("/api/v1/auth/register", json=payload)
        assert resp.status_code == 201, f"Expected 201, got {resp.status_code}"
        data = resp.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["email"] == "player1@mathos.local"

        stmt = select(User).where(User.email == "player1@mathos.local")
        res = await session.execute(stmt)
        user = res.scalar_one_or_none()
        assert user is not None

        stmt_id = select(AuthIdentity).where(AuthIdentity.user_id == user.id)
        res_id = await session.execute(stmt_id)
        identity = res_id.scalar_one()
        assert identity.password_hash != "Password123"
        assert identity.password_hash.startswith("$argon2id$")

    async def test_register_duplicate(client, session):
        payload = {"email": "dup@mathos.local", "password": "Password123", "display_name": "Dup User"}
        r1 = await client.post("/api/v1/auth/register", json=payload)
        assert r1.status_code == 201
        r2 = await client.post("/api/v1/auth/register", json=payload)
        assert r2.status_code == 400
        assert "already registered" in r2.json()["detail"]

    async def test_login_flow(client, session):
        reg = {"email": "login_test@mathos.local", "password": "SecretPassword123", "display_name": "Login User"}
        await client.post("/api/v1/auth/register", json=reg)

        # Bad password
        r_bad = await client.post("/api/v1/auth/login", json={"email": "login_test@mathos.local", "password": "WrongPassword123"})
        assert r_bad.status_code == 401
        assert r_bad.json()["detail"] == "Invalid email or password"

        # Good password
        r_good = await client.post("/api/v1/auth/login", json={"email": "login_test@mathos.local", "password": "SecretPassword123"})
        assert r_good.status_code == 200
        assert "access_token" in r_good.json()

    async def test_refresh_token_rotation(client, session):
        reg = {"email": "rot_user@mathos.local", "password": "SecretPassword123", "display_name": "Rotation User"}
        r_reg = await client.post("/api/v1/auth/register", json=reg)
        raw_ref_1 = r_reg.json()["refresh_token"]

        # Refresh
        r_ref = await client.post("/api/v1/auth/refresh", json={"refresh_token": raw_ref_1})
        assert r_ref.status_code == 200
        raw_ref_2 = r_ref.json()["refresh_token"]
        assert raw_ref_2 != raw_ref_1

        # Reuse old token -> fail
        r_fail = await client.post("/api/v1/auth/refresh", json={"refresh_token": raw_ref_1})
        assert r_fail.status_code == 401

    async def test_logout_revocation(client, session):
        reg = {"email": "logout_test@mathos.local", "password": "SecretPassword123", "display_name": "Logout User"}
        r_reg = await client.post("/api/v1/auth/register", json=reg)
        raw_ref = r_reg.json()["refresh_token"]

        r_logout = await client.post("/api/v1/auth/logout", json={"refresh_token": raw_ref})
        assert r_logout.status_code == 200

        r_ref = await client.post("/api/v1/auth/refresh", json={"refresh_token": raw_ref})
        assert r_ref.status_code == 401

    async def test_forgot_and_reset_password(client, session):
        reg = {"email": "reset_test@mathos.local", "password": "OldPassword123", "display_name": "Reset User"}
        await client.post("/api/v1/auth/register", json=reg)

        r_forgot = await client.post("/api/v1/auth/forgot-password", json={"email": "reset_test@mathos.local"})
        assert r_forgot.status_code == 200

        # Retrieve token hash from DB
        stmt = select(PasswordResetToken)
        res = await session.execute(stmt)
        tokens = res.scalars().all()
        assert len(tokens) > 0

    async def test_google_auth_placeholder(client, session):
        resp = await client.get("/api/v1/auth/google")
        assert resp.status_code == 200
        assert resp.json()["status"] == "NOT_CONFIGURED"

    async def test_profile_get_and_update(client, session):
        reg = {"email": "profile_test@mathos.local", "password": "SecretPassword123", "display_name": "Initial Name"}
        r_reg = await client.post("/api/v1/auth/register", json=reg)
        token = r_reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r_get = await client.get("/api/v1/me/profile", headers=headers)
        assert r_get.status_code == 200
        assert r_get.json()["display_name"] == "Initial Name"

        r_patch = await client.patch("/api/v1/me/profile", json={"display_name": "New Hero Name", "onboarding_completed": True}, headers=headers)
        assert r_patch.status_code == 200
        assert r_patch.json()["display_name"] == "New Hero Name"
        assert r_patch.json()["onboarding_completed"] == True

    async def test_docker_compose_config_file(client, session):
        compose_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "compose.yaml")
        assert os.path.exists(compose_path)
        with open(compose_path, "r", encoding="utf-8") as f:
            c = f.read()
        assert "mathos-api:" in c
        assert "mathos-db:" in c
        assert "mathos-mailpit:" in c
        assert "127.0.0.1:8080:8080" in c
        assert "127.0.0.1:8025:8025" in c

    # Run all test functions
    tests = [
        ("test_health", test_health),
        ("test_register_success", test_register_success),
        ("test_register_duplicate", test_register_duplicate),
        ("test_login_flow", test_login_flow),
        ("test_refresh_token_rotation", test_refresh_token_rotation),
        ("test_logout_revocation", test_logout_revocation),
        ("test_forgot_and_reset_password", test_forgot_and_reset_password),
        ("test_google_auth_placeholder", test_google_auth_placeholder),
        ("test_profile_get_and_update", test_profile_get_and_update),
        ("test_docker_compose_config_file", test_docker_compose_config_file),
    ]

    for name, coro in tests:
        await execute_test(name, coro)

    await engine.dispose()

    print("\n==================================================")
    print(f"RESULTS: {passed_count} PASSED, {failed_count} FAILED out of {len(tests)} tests.")
    print("==================================================")
    return failed_count == 0

if __name__ == "__main__":
    success = asyncio.run(run_all_tests())
    sys.exit(0 if success else 1)
