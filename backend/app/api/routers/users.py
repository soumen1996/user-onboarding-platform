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
