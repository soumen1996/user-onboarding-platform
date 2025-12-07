# Creates/overwrites backend DB, model, and schema files to add Azure SQL support.
# Run: powershell -ExecutionPolicy Bypass -File .\apply_db_changes.ps1

$base = Split-Path -Parent $MyInvocation.MyCommand.Definition
$app = Join-Path $base "app"

if (-not (Test-Path $app)) {
    Write-Error "App folder not found at $app"
    exit 1
}

function Write-FileSafely($relPath, $content) {
    $full = Join-Path $base $relPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $full) {
        $bak = "$full.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -Path $full -Destination $bak -Force
        Write-Host "Backed up $relPath -> $(Split-Path $bak -Leaf)"
    }
    $content | Out-File -FilePath $full -Encoding UTF8 -Force
    Write-Host "Wrote $relPath"
}

$files = @{}

$files['app\db\session.py'] = @'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from typing import Generator

from ..core.config import settings

# Engine configured from environment variable AZURE_SQL_CONNECTION_STRING (no hard-coded credentials)
# Example Azure SQL SQLAlchemy pattern (set in env): "mssql+pyodbc:///?odbc_connect=<urlencoded-conn-str>"
engine = create_engine(settings.AZURE_SQL_CONNECTION_STRING, pool_pre_ping=True, future=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'@

$files['app\db\base.py'] = @'
from sqlalchemy.orm import declarative_base

Base = declarative_base()
'@

$files['app\models\user.py'] = @'
from sqlalchemy import Column, Integer, String, DateTime, Text, func
from ..db.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)
    role = Column(String(20), nullable=False, default="USER")           # "USER" or "ADMIN"
    status = Column(String(20), nullable=False, default="PENDING")      # "PENDING", "APPROVED", "REJECTED"
    rejection_reason = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    def __repr__(self):
        return f"<User id={self.id} email={self.email} role={self.role} status={self.status}>"
'@

$files['app\schemas\user.py'] = @'
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None

class UserRead(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str] = None
    role: str
    status: str
    rejection_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class UserStatus(BaseModel):
    status: str
    rejection_reason: Optional[str] = None

class UserUpdateStatus(BaseModel):
    status: str
    rejection_reason: Optional[str] = None
'@

$files['app\db\init_db.py'] = @'
from .base import Base
from .session import engine

def create_tables():
    """
    Create tables in the target database. Ensure AZURE_SQL_CONNECTION_STRING is set in the environment.
    Use this in development or for one-off initialization; use Alembic for production migrations.
    """
    Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    create_tables()
    print("Tables created (if they did not already exist).")
'@

foreach ($rel in $files.Keys) {
    Write-FileSafely $rel $files[$rel]
}

Write-Host ''
Write-Host 'Done.'
Write-Host ''
Write-Host 'Next steps (example):'
Write-Host '1) create & activate Python venv:'
Write-Host '   python -m venv .venv'
Write-Host '   .\.venv\Scripts\Activate.ps1'
Write-Host '2) install deps:'
Write-Host '   pip install -r requirements.txt'
Write-Host '3) set AZURE_SQL_CONNECTION_STRING in this session (do NOT hard-code in files).'
Write-Host '   For quick dev you can use sqlite:'
Write-Host "     $env:AZURE_SQL_CONNECTION_STRING = 'sqlite+pysqlite:///./dev.db'"
Write-Host '   For Azure SQL, construct and URL-encode your ODBC string and set:'
Write-Host "     $env:AZURE_SQL_CONNECTION_STRING = 'mssql+pyodbc:///?odbc_connect=<urlencoded-string>'"
Write-Host '4) create tables (one-off):'
Write-Host '   python -c "from app.db.init_db import create_tables; create_tables()"'
Write-Host '5) run the app:'
Write-Host '   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000'