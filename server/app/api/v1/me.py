import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models import User, Profile
from app.schemas.profile import ProfileResponse, ProfileUpdateRequest

router = APIRouter()

async def get_current_user(
    authorization: str = Header(..., description="Bearer JWT Access Token"),
    db: AsyncSession = Depends(get_db)
) -> User:
    """Dependency for validating Bearer token and returning current User."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Must be 'Bearer <token>'"
        )
    token = authorization[7:].strip()
    payload = decode_access_token(token)
    if payload is None or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token"
        )

    try:
        user_id = uuid.UUID(payload["sub"])
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid subject in access token"
        )

    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()

    if user is None or user.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account inactive or not found"
        )

    return user

@router.get("/profile", response_model=ProfileResponse)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieves current user profile."""
    stmt = select(Profile).where(Profile.user_id == current_user.id)
    res = await db.execute(stmt)
    profile = res.scalar_one()

    return ProfileResponse(
        user_id=str(current_user.id),
        email=current_user.email,
        display_name=profile.display_name,
        avatar_ref=profile.avatar_ref,
        onboarding_completed=profile.onboarding_completed,
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.patch("/profile", response_model=ProfileResponse)
async def update_my_profile(
    payload: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Updates current user profile."""
    stmt = select(Profile).where(Profile.user_id == current_user.id)
    res = await db.execute(stmt)
    profile = res.scalar_one()

    if payload.display_name is not None:
        profile.display_name = payload.display_name.strip()
    if payload.avatar_ref is not None:
        profile.avatar_ref = payload.avatar_ref.strip()
    if payload.onboarding_completed is not None:
        profile.onboarding_completed = payload.onboarding_completed

    await db.commit()
    await db.refresh(profile)

    return ProfileResponse(
        user_id=str(current_user.id),
        email=current_user.email,
        display_name=profile.display_name,
        avatar_ref=profile.avatar_ref,
        onboarding_completed=profile.onboarding_completed,
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )
