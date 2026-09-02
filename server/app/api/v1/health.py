from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db

router = APIRouter()

@router.get("/health", tags=["Health"])
async def check_health(db: AsyncSession = Depends(get_db)):
    """Healthcheck endpoint returning service & database status."""
    db_status = "disconnected"
    try:
        result = await db.execute(text("SELECT 1"))
        if result.scalar() == 1:
            db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    if db_status != "connected":
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "unhealthy", "environment": settings.ENVIRONMENT, "database": db_status}
        )

    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT,
        "database": db_status,
        "version": "1.0.0"
    }
