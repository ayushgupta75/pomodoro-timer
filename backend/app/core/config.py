from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Database
    database_url: str

    # JWT
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 30  # 30 days

    # Apple Sign-In
    apple_bundle_id: str = "com.stackforge.pomodoro-timer"
    apple_keys_url: str = "https://appleid.apple.com/auth/keys"


settings = Settings()
