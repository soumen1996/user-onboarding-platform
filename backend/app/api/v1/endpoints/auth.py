from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.user import UserCreate, UserOut
from app.crud.user import create_user, get_user_by_email
from app.core.security import create_access_token
from app.core.config import settings
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter()

@router.post("/login", response_model=UserOut)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = get_user_by_email(db, email=form_data.username)
    if not user or not user.verify_password(form_data.password):
        raise HTTPException(status_code=400, detail="Incorrect username or password")
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register", response_model=UserOut)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = get_user_by_email(db, email=user.email)
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = create_user(db=db, user=user)
    return new_user