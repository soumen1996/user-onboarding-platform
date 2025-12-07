from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.user import UserCreate, UserResponse
from app.crud.user import create_user, get_user_by_id
from app.models.user import User

router = APIRouter()

@router.post("/", response_model=UserResponse)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = get_user_by_id(db, user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return create_user(db=db, user=user)

@router.get("/{user_id}", response_model=UserResponse)
def read_user(user_id: int, db: Session = Depends(get_db)):
    user = get_user_by_id(db, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user