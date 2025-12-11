from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://lms_user:lms_password@localhost:5432/lms_db"
    SECRET_KEY: str = "your-super-secret-key-change-this-min-32-chars"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    COURSES_ROOT_PATH: str = "C:\\LMS_Content"
    
    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()