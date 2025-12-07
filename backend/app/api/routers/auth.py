from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from jose import jwt

from ...db.session import get_db
from ...models.user import User
from ...schemas.user import LoginRequest, Token
from ...core.config import settings
from ...core.security import verify_password

router = APIRouter()

@router.post("/auth/login", response_model=Token)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return JWT access token with claims: sub (id), email, role.
    """
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": str(user.id), "email": user.email, "role": user.role, "exp": expire}
    token = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return {"access_token": token, "token_type": "bearer"}
