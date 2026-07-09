from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date

class ExpenseCreateRequest(BaseModel):
    title: str
    amount: float
    category: Optional[str] = None
    expense_date: Optional[date] = None
    vendor_id: Optional[int] = None
    purchase_order_id: Optional[int] = None

class ExpenseUpdateRequest(BaseModel):
    title: Optional[str] = None
    amount: Optional[float] = None
    category: Optional[str] = None
    expense_date: Optional[date] = None
    vendor_id: Optional[int] = None
    purchase_order_id: Optional[int] = None

class ExpenseResponse(BaseModel):
    id: int
    title: str
    amount: float
    category: Optional[str] = None
    expense_date: Optional[date] = None
    vendor_id: Optional[int] = None
    purchase_order_id: Optional[int] = None
    
    model_config = ConfigDict(from_attributes=True)