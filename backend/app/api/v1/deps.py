from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..db.session import get_db
from ..models.user import User
from ..core.security import get_current_user

def get_current_active_user(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.is_active:
        return current_user
    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")