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
