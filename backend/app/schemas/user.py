from pydantic import BaseModel, EmailStr, constr
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: constr(min_length=8)
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

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
