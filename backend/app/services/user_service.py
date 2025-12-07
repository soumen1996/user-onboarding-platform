from sqlalchemy.orm import Session
from typing import List, Optional, Tuple
from ..models.user import User
from ..core.security import hash_password

class UserService:
    def __init__(self, db: Session):
        self.db = db

    def create_user(self, email: str, password: str, full_name: Optional[str] = None, role: str = "USER") -> User:
        user = User(email=email, password_hash=hash_password(password), full_name=full_name, role=role, status="PENDING")
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def list_users_by_status(self, status: str, page: int = 1, page_size: int = 20) -> Tuple[List[User], int]:
        query = self.db.query(User).filter(User.status == status)
        total = query.count()
        results = query.offset((page-1)*page_size).limit(page_size).all()
        return results, total

    def approve(self, user: User) -> User:
        user.status = "APPROVED"
        user.rejection_reason = None
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def reject(self, user: User, reason: Optional[str] = None) -> User:
        user.status = "REJECTED"
        user.rejection_reason = reason
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
