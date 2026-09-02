import os
import secrets
from typing import Optional
from pydantic import EmailStr
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "info"
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Mathos Auth & Database Engine"
    SERVER_HOST: str = "127.0.0.1"
    SERVER_PORT: int = 8080

    SECRET_KEY: str = "local_dev_secret_key_change_in_production_32_bytes_min"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    POSTGRES_SERVER: str = "mathos-db"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "mathos_dev"
    POSTGRES_PASSWORD: str = "mathos_dev_password"
    POSTGRES_DB: str = "mathos_local_db"
    SQLALCHEMY_DATABASE_URI: Optional[str] = None

    SMTP_HOST: str = "mathos-mailpit"
    SMTP_PORT: int = 1025
    SMTP_FROM_EMAIL: str = "no-reply@mathos.local"

    GOOGLE_CLIENT_ID: Optional[str] = ""
    GOOGLE_CLIENT_SECRET: Optional[str] = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    @property
    def async_database_url(self) -> str:
        if self.SQLALCHEMY_DATABASE_URI:
            return self.SQLALCHEMY_DATABASE_URI
        return f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    @property
    def sync_database_url(self) -> str:
        return f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    @property
    def google_auth_configured(self) -> bool:
        return bool(self.GOOGLE_CLIENT_ID and self.GOOGLE_CLIENT_ID.strip())

settings = Settings()
