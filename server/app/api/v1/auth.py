import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta, timezone
from typing import Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    generate_secure_token,
    hash_token,
)
from app.models import (
    User,
    AuthIdentity,
    Profile,
    AuthSession,
    PasswordResetToken,
    PlayerProgress,
)
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    RefreshTokenRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    TokenResponse,
    GenericMessageResponse,
    GoogleAuthStatusResponse,
)

router = APIRouter()

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

def send_local_mail(to_email: str, subject: str, body_text: str) -> None:
    """Sends email via local Mailpit SMTP server."""
    try:
        msg = MIMEMultipart()
        msg["From"] = settings.SMTP_FROM_EMAIL
        msg["To"] = to_email
        msg["Subject"] = subject
        msg.attach(MIMEText(body_text, "plain", "utf-8"))

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=5) as server:
            server.send_message(msg)
    except Exception as e:
        print(f"[Mailpit Error] Could not send email to {to_email}: {e}")

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    """Registers a new user account with Argon2id password hashing."""
    email_norm = payload.email.strip().lower()

    stmt = select(User).where(User.email == email_norm)
    res = await db.execute(stmt)
    if res.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email address is already registered."
        )

    # 1. Create User
    user = User(
        email=email_norm,
        status="ACTIVE",
        email_verified_at=utc_now()  # Auto-verified in local dev
    )
    db.add(user)
    await db.flush()

    # 2. Create Argon2id AuthIdentity
    pw_hash = get_password_hash(payload.password)
    identity = AuthIdentity(
        user_id=user.id,
        provider="LOCAL",
        provider_subject=email_norm,
        password_hash=pw_hash
    )
    db.add(identity)

    # 3. Create Profile
    profile = Profile(
        user_id=user.id,
        display_name=payload.display_name.strip(),
        onboarding_completed=False
    )
    db.add(profile)

    # 4. Create PlayerProgress
    progress = PlayerProgress(
        user_id=user.id,
        progress_version=1,
        cleared_stages=[],
        unlocked_stages=["d1_s1"],
        exp_total=0,
        coin_balance=0,
        adaptive_profiles={}
    )
    db.add(progress)

    # 5. Create AuthSession with Refresh Token Rotation
    raw_refresh = generate_secure_token()
    refresh_hash = hash_token(raw_refresh)
    session = AuthSession(
        user_id=user.id,
        refresh_token_hash=refresh_hash,
        device_name="local_godot_client",
        expires_at=utc_now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    )
    db.add(session)

    await db.commit()

    access_token = create_access_token(subject=str(user.id))
    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        token_type="bearer",
        user_id=str(user.id),
        email=user.email
    )

@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLoginRequest, db: AsyncSession = Depends(get_db)):
    """Authenticates user with Argon2id password verification."""
    email_norm = payload.email.strip().lower()

    stmt = select(User).where(User.email == email_norm)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    stmt_id = select(AuthIdentity).where(
        AuthIdentity.user_id == user.id,
        AuthIdentity.provider == "LOCAL"
    )
    res_id = await db.execute(stmt_id)
    identity = res_id.scalar_one_or_none()

    if identity is None or not identity.password_hash or not verify_password(payload.password, identity.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    # Create session with rotated refresh token hash
    raw_refresh = generate_secure_token()
    refresh_hash = hash_token(raw_refresh)
    session = AuthSession(
        user_id=user.id,
        refresh_token_hash=refresh_hash,
        device_name=payload.device_name or "local_godot_client",
        expires_at=utc_now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    )
    db.add(session)
    await db.commit()

    access_token = create_access_token(subject=str(user.id))
    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        token_type="bearer",
        user_id=str(user.id),
        email=user.email
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(payload: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """Rotates refresh token and returns new access & refresh tokens."""
    raw_refresh = payload.refresh_token.strip()
    refresh_hash = hash_token(raw_refresh)

    stmt = select(AuthSession).where(
        AuthSession.refresh_token_hash == refresh_hash,
        AuthSession.revoked_at.is_(None)
    )
    res = await db.execute(stmt)
    session = res.scalar_one_or_none()

    if session is None or session.expires_at < utc_now():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )

    # 1. Revoke old session (Refresh Token Rotation)
    session.revoked_at = utc_now()

    # 2. Create new session
    new_raw_refresh = generate_secure_token()
    new_refresh_hash = hash_token(new_raw_refresh)
    new_session = AuthSession(
        user_id=session.user_id,
        refresh_token_hash=new_refresh_hash,
        device_name=session.device_name,
        expires_at=utc_now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    )
    db.add(new_session)
    await db.commit()

    # Query user email
    stmt_user = select(User).where(User.id == session.user_id)
    res_user = await db.execute(stmt_user)
    user = res_user.scalar_one()

    access_token = create_access_token(subject=str(user.id))
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_raw_refresh,
        token_type="bearer",
        user_id=str(user.id),
        email=user.email
    )

@router.post("/logout", response_model=GenericMessageResponse)
async def logout(payload: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """Revokes the current auth session."""
    raw_refresh = payload.refresh_token.strip()
    refresh_hash = hash_token(raw_refresh)

    stmt = select(AuthSession).where(AuthSession.refresh_token_hash == refresh_hash)
    res = await db.execute(stmt)
    session = res.scalar_one_or_none()

    if session and session.revoked_at is None:
        session.revoked_at = utc_now()
        await db.commit()

    return GenericMessageResponse(message="Successfully logged out.")

@router.post("/forgot-password", response_model=GenericMessageResponse)
async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    """Generates password reset token and sends link to Mailpit local email UI."""
    email_norm = payload.email.strip().lower()

    stmt = select(User).where(User.email == email_norm)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()

    if user is not None:
        raw_reset_token = generate_secure_token()
        token_h = hash_token(raw_reset_token)

        reset_entry = PasswordResetToken(
            user_id=user.id,
            token_hash=token_h,
            expires_at=utc_now() + timedelta(hours=1)
        )
        db.add(reset_entry)
        await db.commit()

        email_body = f"""Hello,

You requested a password reset for your Mathos account.
Use the following reset token to reset your password:

Reset Token: {raw_reset_token}

This token will expire in 1 hour. If you did not request this, please ignore this email.
"""
        send_local_mail(
            to_email=user.email,
            subject="[Mathos Local] Password Reset Request",
            body_text=email_body
        )

    return GenericMessageResponse(message="If the email exists, a password reset link has been sent.")

@router.post("/reset-password", response_model=GenericMessageResponse)
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    """Resets password using valid reset token."""
    raw_token = payload.token.strip()
    token_h = hash_token(raw_token)

    stmt = select(PasswordResetToken).where(
        PasswordResetToken.token_hash == token_h,
        PasswordResetToken.used_at.is_(None)
    )
    res = await db.execute(stmt)
    reset_entry = res.scalar_one_or_none()

    if reset_entry is None or reset_entry.expires_at < utc_now():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token"
        )

    # 1. Update password
    new_pw_hash = get_password_hash(payload.new_password)
    stmt_id = select(AuthIdentity).where(
        AuthIdentity.user_id == reset_entry.user_id,
        AuthIdentity.provider == "LOCAL"
    )
    res_id = await db.execute(stmt_id)
    identity = res_id.scalar_one()

    identity.password_hash = new_pw_hash
    reset_entry.used_at = utc_now()

    # 2. Revoke active sessions for user
    stmt_revoke = (
        update(AuthSession)
        .where(AuthSession.user_id == reset_entry.user_id, AuthSession.revoked_at.is_(None))
        .values(revoked_at=utc_now())
    )
    await db.execute(stmt_revoke)
    await db.commit()

    return GenericMessageResponse(message="Password successfully reset.")

@router.get("/google", response_model=GoogleAuthStatusResponse)
@router.post("/google", response_model=GoogleAuthStatusResponse)
async def google_auth_placeholder():
    """Google Auth capability status placeholder (returns NOT_CONFIGURED when client keys absent)."""
    if not settings.google_auth_configured:
        return GoogleAuthStatusResponse(
            status="NOT_CONFIGURED",
            message="Google authentication is not configured in this environment."
        )
    return GoogleAuthStatusResponse(
        status="CONFIGURED",
        message="Google authentication configured."
    )
