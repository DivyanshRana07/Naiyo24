from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional


class LeadCreateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)
    
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    company: Optional[str] = None
    status: str = "new"
    notes: Optional[str] = None
    source: Optional[str] = None


class LeadUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)
    
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    company: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    source: Optional[str] = None


class LeadResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    user_id: int
    name: str
    email: Optional[str]
    phone: Optional[str]
    company: Optional[str]
    status: str
    notes: Optional[str]
    source: Optional[str]
    converted_to_customer_id: Optional[int]
    created_at: datetime
    updated_at: Optional[datetime]
