from pydantic import BaseSettings

class Config(BaseSettings):
    AZURE_SQL_CONNECTION_STRING: str
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Config()
