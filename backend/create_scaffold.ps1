# Creates backend scaffold files for the FastAPI project.
# Run: powershell -ExecutionPolicy Bypass -File '...create_scaffold.ps1'

$base = Split-Path -Parent $MyInvocation.MyCommand.Definition

$dirs = @(
  "app",
  "app\api",
  "app\api\routers",
  "app\models",
  "app\schemas",
  "app\core",
  "app\services",
  "app\db"
)

foreach ($d in $dirs) {
  $path = Join-Path $base $d
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

$files = @{
"requirements.txt" = @'
fastapi
uvicorn[standard]
sqlalchemy
pydantic
python-jose[cryptography]
passlib[bcrypt]
pyodbc
'@

"app\__init__.py" = @'
# Package marker
'@

"app\main.py" = @'
from fastapi import FastAPI
from .api.routers import users

def create_app() -> FastAPI:
    app = FastAPI(title="Onboarding API")

    @app.get("/health", tags=["health"])
    async def health():
        return {"status": "ok"}

    app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
    return app

app = create_app()
'@

"app\api\routers\__init__.py" = @'
from . import users
'@

"app\api\routers\users.py" = @'
from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from ...schemas.user import UserCreate, UserOut
from ...services.user_service import UserService
from ...db.session import get_db

router = APIRouter()

@router.post("/", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(payload: UserCreate, db=Depends(get_db)):
    svc = UserService(db)
    user = svc.create_user(payload.email, payload.password)
    return user

@router.get("/", response_model=List[UserOut])
def list_users(db=Depends(get_db)):
    svc = UserService(db)
    return svc.list_users()
'@

"app\models\__init__.py" = @'
# Models package
'@

"app\models\user.py" = @'
from sqlalchemy import Column, Integer, String, Boolean
from ..db.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    role = Column(String(50), default="USER")
    is_approved = Column(Boolean, default=False)
'@

"app\schemas\__init__.py" = @'
# Schemas package
'@

"app\schemas\user.py" = @'
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    email: EmailStr
    role: str
    is_approved: bool

    class Config:
        orm_mode = True
'@

"app\core\__init__.py" = @'
# Core package
'@

"app\core\config.py" = @'
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
'@

"app\core\security.py" = @'
from datetime import datetime, timedelta
from passlib.context import CryptContext
from jose import jwt
from typing import Optional

from .config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode = {"sub": subject, "exp": expire}
    encoded = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded
'@

"app\services\__init__.py" = @'
# Services package
'@

"app\services\user_service.py" = @'
from sqlalchemy.orm import Session
from ..models.user import User
from ..core.security import hash_password

class UserService:
    def __init__(self, db: Session):
        self.db = db

    def create_user(self, email: str, password: str) -> User:
        user = User(email=email, hashed_password=hash_password(password))
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def list_users(self):
        return self.db.query(User).all()
'@

"app\db\__init__.py" = @'
# DB package
'@

"app\db\base.py" = @'
from sqlalchemy.orm import declarative_base

Base = declarative_base()
'@

"app\db\session.py" = @'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from typing import Generator

from ..core.config import settings

# Use AZURE_SQL_CONNECTION_STRING from env
engine = create_engine(settings.AZURE_SQL_CONNECTION_STRING, future=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency for FastAPI endpoints
def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'@
}

foreach ($rel in $files.Keys) {
  $full = Join-Path $base $rel
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $files[$rel] | Out-File -FilePath $full -Encoding UTF8 -Force
  Write-Host "Wrote $rel"
}

Write-Host "Scaffold creation complete."
Write-Host ""
Write-Host "Next steps:"
Write-Host "1) create & activate virtualenv:"
Write-Host "   python -m venv .venv"
Write-Host "   .\\.venv\\Scripts\\Activate.ps1"
Write-Host "2) install deps:"
Write-Host "   pip install -r requirements.txt"
Write-Host "3) for quick local test (use sqlite):"
Write-Host "   $env:AZURE_SQL_CONNECTION_STRING = 'sqlite+pysqlite:///./dev.db'"
Write-Host "   $env:JWT_SECRET_KEY = 'dev-secret'"
Write-Host "   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"