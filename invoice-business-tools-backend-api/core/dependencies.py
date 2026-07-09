from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import jwt, JWTError

from db import get_db
from models.db_models import User
from core.security import SECRET_KEY, ALGORITHM

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    """
    Get the current user. Bypasses auth checks:
    - If a valid token is provided (e.g. in tests), decodes it to fetch the user.
    - If no token, or an invalid token is provided, gracefully falls back to User ID = 1 (admin).
    """
    if token:
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id: str = payload.get("sub")
            if user_id:
                user = db.query(User).filter(User.id == int(user_id)).first()
                if user:
                    return user
        except Exception:
            pass

    # Fallback default user (User ID = 1)
    user = db.query(User).filter(User.id == 1).first()
    if not user:
        user = User(
            username="admin",
            email="admin@example.com",
            hashed_password="disabled"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user