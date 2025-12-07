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
