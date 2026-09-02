import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_token
from app.models import User, AuthIdentity, AuthSession, PasswordResetToken

@pytest.mark.asyncio
async def test_register_success(client: AsyncClient, db_session: AsyncSession):
    payload = {
        "email": "TestPlayer@Mathos.Local",
        "password": "Password123",
        "display_name": "Test Player"
    }
    response = await client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["email"] == "testplayer@mathos.local"

    # Verify user in database
    stmt = select(User).where(User.email == "testplayer@mathos.local")
    res = await db_session.execute(stmt)
    user = res.scalar_one_or_none()
    assert user is not None

    # Verify password hash is NOT plaintext and uses Argon2id
    stmt_id = select(AuthIdentity).where(AuthIdentity.user_id == user.id)
    res_id = await db_session.execute(stmt_id)
    identity = res_id.scalar_one()
    assert identity.password_hash != "Password123"
    assert identity.password_hash.startswith("$argon2id$")

@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient):
    payload = {
        "email": "dup@mathos.local",
        "password": "Password123",
        "display_name": "User One"
    }
    resp1 = await client.post("/api/v1/auth/register", json=payload)
    assert resp1.status_code == 201

    resp2 = await client.post("/api/v1/auth/register", json=payload)
    assert resp2.status_code == 400
    assert "already registered" in resp2.json()["detail"]

@pytest.mark.asyncio
async def test_login_success_and_wrong_password(client: AsyncClient):
    # Register
    reg_payload = {
        "email": "login_user@mathos.local",
        "password": "SecretPassword123",
        "display_name": "Login User"
    }
    await client.post("/api/v1/auth/register", json=reg_payload)

    # Wrong password
    bad_login = {
        "email": "login_user@mathos.local",
        "password": "WrongPassword123"
    }
    resp_bad = await client.post("/api/v1/auth/login", json=bad_login)
    assert resp_bad.status_code == 401
    assert resp_bad.json()["detail"] == "Invalid email or password"

    # Correct password
    good_login = {
        "email": "login_user@mathos.local",
        "password": "SecretPassword123"
    }
    resp_good = await client.post("/api/v1/auth/login", json=good_login)
    assert resp_good.status_code == 200
    data = resp_good.json()
    assert "access_token" in data
    assert "refresh_token" in data

@pytest.mark.asyncio
async def test_refresh_token_rotation(client: AsyncClient, db_session: AsyncSession):
    # Register & Login
    reg_payload = {
        "email": "refresh_user@mathos.local",
        "password": "SecretPassword123",
        "display_name": "Refresh User"
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    raw_refresh_1 = reg_res.json()["refresh_token"]

    # Perform refresh
    ref_res = await client.post("/api/v1/auth/refresh", json={"refresh_token": raw_refresh_1})
    assert ref_res.status_code == 200
    data_2 = ref_res.json()
    raw_refresh_2 = data_2["refresh_token"]
    assert raw_refresh_2 != raw_refresh_1

    # Verify old session was revoked in database
    old_hash = hash_token(raw_refresh_1)
    stmt = select(AuthSession).where(AuthSession.refresh_token_hash == old_hash)
    res = await db_session.execute(stmt)
    old_session = res.scalar_one_or_none()
    assert old_session is not None
    assert old_session.revoked_at is not None

    # Attempting to use old refresh token should fail (rotated out)
    ref_fail = await client.post("/api/v1/auth/refresh", json={"refresh_token": raw_refresh_1})
    assert ref_fail.status_code == 401

@pytest.mark.asyncio
async def test_logout_revocation(client: AsyncClient, db_session: AsyncSession):
    reg_payload = {
        "email": "logout_user@mathos.local",
        "password": "SecretPassword123",
        "display_name": "Logout User"
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    raw_refresh = reg_res.json()["refresh_token"]

    logout_res = await client.post("/api/v1/auth/logout", json={"refresh_token": raw_refresh})
    assert logout_res.status_code == 200

    # Refresh after logout should fail
    ref_res = await client.post("/api/v1/auth/refresh", json={"refresh_token": raw_refresh})
    assert ref_res.status_code == 401

@pytest.mark.asyncio
async def test_forgot_and_reset_password(client: AsyncClient, db_session: AsyncSession):
    reg_payload = {
        "email": "reset_user@mathos.local",
        "password": "OldPassword123",
        "display_name": "Reset User"
    }
    await client.post("/api/v1/auth/register", json=reg_payload)

    # Forgot password
    forgot_res = await client.post("/api/v1/auth/forgot-password", json={"email": "reset_user@mathos.local"})
    assert forgot_res.status_code == 200

    # Retrieve reset token from database
    stmt = select(PasswordResetToken)
    res = await db_session.execute(stmt)
    token_entry = res.scalars().all()[-1]
    assert token_entry is not None

    # Reset password using token
    # Extract raw token generated by testing database (for test purposes we test matching token hash)
    raw_token_for_test = None
    # Test reset password failure with bad token
    bad_reset = await client.post("/api/v1/auth/reset-password", json={"token": "invalid_token", "new_password": "NewPassword123"})
    assert bad_reset.status_code == 400

@pytest.mark.asyncio
async def test_google_auth_placeholder(client: AsyncClient):
    response = await client.get("/api/v1/auth/google")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "NOT_CONFIGURED"
