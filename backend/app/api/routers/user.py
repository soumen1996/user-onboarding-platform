from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...schemas.user import UserRead, UserStatus
from ...core.security import get_current_user

router = APIRouter()

@router.get("/me", response_model=UserRead)
def read_me(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Return current authenticated user (UserRead).
    """
    return current_user

@router.get("/me/status", response_model=UserStatus)
def read_my_status(current_user=Depends(get_current_user)):
    """
    Return only status and rejection_reason for current authenticated user.
    """
    return {"status": current_user.status, "rejection_reason": current_user.rejection_reason}
