from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional, Tuple

from ...db.session import get_db
from ...models.user import User
from ...schemas.user import UserRead, UserUpdateStatus, UserStatus
from ...core.security import get_current_admin_user

router = APIRouter()

@router.get("/admin/users", response_model=List[UserRead])
def list_users(status: Optional[str] = "PENDING", page: int = 1, page_size: int = 20, db: Session = Depends(get_db), current_admin=Depends(get_current_admin_user)):
    """
    Paginated list of users by status. Returns list (page) - total count can be retrieved separately if needed.
    """
    if page < 1:
        page = 1
    if page_size < 1 or page_size > 200:
        page_size = 20
    query = db.query(User).filter(User.status == status)
    users = query.offset((page-1)*page_size).limit(page_size).all()
    return users

@router.post("/admin/users/{user_id}/approve", response_model=UserRead)
def approve_user(user_id: int, db: Session = Depends(get_db), current_admin=Depends(get_current_admin_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.status != "PENDING":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User status is not PENDING")
    user.status = "APPROVED"
    user.rejection_reason = None
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/admin/users/{user_id}/reject", response_model=UserRead)
def reject_user(user_id: int, payload: UserUpdateStatus = Depends(), db: Session = Depends(get_db), current_admin=Depends(get_current_admin_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.status != "PENDING":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User status is not PENDING")
    if payload.status != "REJECTED":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status for rejection")
    user.status = "REJECTED"
    user.rejection_reason = payload.rejection_reason
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
