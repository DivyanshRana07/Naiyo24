
# pyrefly: ignore [missing-import]
from pydantic import BaseModel, EmailStr
from typing import Optional



class RegisterRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    full_name: str | None = None


class LoginRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: str



class TokenResponse(BaseModel):
    access_token: str
    token_type: str