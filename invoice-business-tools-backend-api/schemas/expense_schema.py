# pyrefly: ignore [missing-import]
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional, Annotated
from datetime import date, datetime


class ExpenseItemRequest(BaseModel):
    name: str
    quantity: float
    price: float
    gst_rate: Optional[float] = 0.00
    line_total: float


class ExpenseItemResponse(BaseModel):
    id: int
    expense_id: Annotated[int, Field(alias="expenseId")]
    name: str
    quantity: float
    price: float
    gst_rate: Annotated[float, Field(alias="gstRate")]
    line_total: Annotated[float, Field(alias="lineTotal")]

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ExpenseCreateRequest(BaseModel):
    vendor_id: int
    expense_number: Annotated[str, Field(alias="expenseNumber")]
    expense_date: Annotated[date, Field(alias="expenseDate")]
    expected_delivery_date: Annotated[Optional[date], Field(alias="expectedDeliveryDate")] = None
    status: Optional[str] = "Draft"
    notes: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_amount: Annotated[Optional[float], Field(alias="totalAmount")] = 0.00
    gst_amount: Annotated[Optional[float], Field(alias="gstAmount")] = 0.00
    receipt_image: Annotated[Optional[str], Field(alias="receiptImage")] = None
    items: Optional[List[ExpenseItemRequest]] = None
    user_id: Optional[int] = None

    model_config = ConfigDict(populate_by_name=True)


class ExpenseUpdateRequest(BaseModel):
    vendor_id: Optional[int] = None
    expense_number: Annotated[Optional[str], Field(alias="expenseNumber")] = None
    expense_date: Annotated[Optional[date], Field(alias="expenseDate")] = None
    expected_delivery_date: Annotated[Optional[date], Field(alias="expectedDeliveryDate")] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_amount: Annotated[Optional[float], Field(alias="totalAmount")] = None
    gst_amount: Annotated[Optional[float], Field(alias="gstAmount")] = None
    receipt_image: Annotated[Optional[str], Field(alias="receiptImage")] = None
    items: Optional[List[ExpenseItemRequest]] = None

    model_config = ConfigDict(populate_by_name=True)


class ExpenseResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    vendor_id: Annotated[int, Field(alias="vendorId")]
    vendor_name: Annotated[Optional[str], Field(alias="vendorName")] = None
    expense_number: Annotated[str, Field(alias="expenseNumber")]
    expense_date: Annotated[date, Field(alias="expenseDate")]
    expected_delivery_date: Annotated[Optional[date], Field(alias="expectedDeliveryDate")] = None
    status: str
    notes: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_amount: Annotated[Optional[float], Field(alias="totalAmount")] = None
    gst_amount: Annotated[Optional[float], Field(alias="gstAmount")] = None
    receipt_image: Annotated[Optional[str], Field(alias="receiptImage")] = None
    created_at: Annotated[Optional[datetime], Field(alias="createdAt")] = None
    items: List[ExpenseItemResponse] = []

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
