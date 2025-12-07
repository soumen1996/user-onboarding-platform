from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserApprovalSchema
from app.crud.user import approve_user, get_user

router = APIRouter()

@router.post("/approve/{user_id}", response_model=UserApprovalSchema)
def approve_user_endpoint(user_id: int, db: Session = Depends(get_db)):
    user = get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    approved_user = approve_user(db, user_id)
    return approved_user

@router.get("/approvals", response_model=list[UserApprovalSchema])
def list_approvals(db: Session = Depends(get_db)):
    # This function would typically return a list of users pending approval
    # For now, we will return an empty list as a placeholder
    return []  # Replace with actual logic to fetch pending approvals