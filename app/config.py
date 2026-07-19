from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://dwmb:dwmb_secret_2026@localhost:5432/dwmb"
    SECRET_KEY: str = "dwmb-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    ADMIN_PASSWORD: str = "admin123"

    # MinIO / S3
    MINIO_ENDPOINT: str = "minio:9000"
    MINIO_PUBLIC_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "dwmb_minio"
    MINIO_SECRET_KEY: str = "dwmb_minio_secret"
    MINIO_BUCKET: str = "dwmb-media"
    MINIO_SECURE: bool = False

    # AI (OpenAI)
    AI_API_KEY: str = ""
    AI_MODEL_EMBEDDING: str = "text-embedding-3-small"
    AI_MODEL_CHAT: str = "gpt-4o-mini"
    AI_EMBEDDING_DIM: int = 1536

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings():
    return Settings()
