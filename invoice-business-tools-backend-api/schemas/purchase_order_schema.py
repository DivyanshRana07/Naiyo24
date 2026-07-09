# pyrefly: ignore [missing-import]
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional, Annotated
from datetime import date, datetime


class PurchaseOrderItemRequest(BaseModel):
    name: str
    quantity: float
    price: float
    gst_rate: Optional[float] = 0.00
    line_total: float


class PurchaseOrderItemResponse(BaseModel):
    id: int
    po_id: int
    name: str
    quantity: float
    price: float
    gst_rate: float
    line_total: float

    model_config = ConfigDict(from_attributes=True)


class PurchaseOrderCreateRequest(BaseModel):
    vendor_id: int
    po_number: str
    po_date: date
    expected_delivery_date: Optional[date] = None
    status: Optional[str] = "Draft"
    notes: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_amount: Annotated[Optional[float], Field(alias="totalAmount")] = 0.00
    items: Optional[List[PurchaseOrderItemRequest]] = None
    user_id: Optional[int] = None

    model_config = ConfigDict(populate_by_name=True)


class PurchaseOrderUpdateRequest(BaseModel):
    vendor_id: Optional[int] = None
    po_number: Optional[str] = None
    po_date: Optional[date] = None
    expected_delivery_date: Optional[date] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_amount: Annotated[Optional[float], Field(alias="totalAmount")] = None
    items: Optional[List[PurchaseOrderItemRequest]] = None

    model_config = ConfigDict(populate_by_name=True)


class PurchaseOrderResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    vendor_id: int
    vendor_name: Optional[str] = None
    po_number: str
    po_date: date
    expected_delivery_date: Optional[date] = None
    status: str
    notes: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_amount: Annotated[Optional[float], Field(alias="totalAmount")] = None
    created_at: Optional[datetime] = None
    items: List[PurchaseOrderItemResponse] = []

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
