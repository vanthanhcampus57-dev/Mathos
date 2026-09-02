from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class ProfileResponse(BaseModel):
    user_id: str
    email: str
    display_name: str
    avatar_ref: Optional[str] = None
    onboarding_completed: bool
    created_at: datetime
    updated_at: datetime

class ProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = Field(None, min_length=2, max_length=100)
    avatar_ref: Optional[str] = Field(None, max_length=255)
    onboarding_completed: Optional[bool] = None
