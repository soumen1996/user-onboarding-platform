from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.user import User
from ...schemas.user import UserCreate, UserRead
from ...core.security import hash_password

router = APIRouter()

@router.post("/auth/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user. Sets role="USER", status="PENDING".
    Validates password length >= 8 and unique email.
    """
    # pydantic EmailStr validates format; enforce password length here as additional guard
    if len(payload.password) < 8:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password must be at least 8 characters")
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        full_name=payload.full_name,
        role="USER",
        status="PENDING"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
