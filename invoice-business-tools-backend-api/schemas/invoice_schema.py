# pyrefly: ignore [missing-import]
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from datetime import date
from decimal import Decimal
from models.invoice_generator import PartyDetails, InvoiceItemInput

class InvoiceCreateRequest(BaseModel):
    invoice_number: Optional[str] = None
    invoice_date: date = Field(default_factory=date.today)
    due_date: Optional[date] = None
    notes: Optional[str] = None
    subtitle: Optional[str] = None
    logo: Optional[str] = None
    settings: Optional[dict] = None
    business: PartyDetails
    customer: PartyDetails
    items: List[InvoiceItemInput]
    paymentMethod: Optional[str] = Field(None, validation_alias="payment_method")
    paidAmount: float = Field(0.00, validation_alias="paid_amount")
    roundOff: float = Field(0.00, validation_alias="round_off")
    status: str = "due"

class InvoiceUpdateRequest(BaseModel):
    due_date: Optional[date] = None
    notes: Optional[str] = None
    customer: Optional[PartyDetails] = None
    paymentMethod: Optional[str] = Field(None, validation_alias="payment_method")
    paidAmount: Optional[float] = Field(None, validation_alias="paid_amount")
    roundOff: Optional[float] = Field(None, validation_alias="round_off")
    status: Optional[str] = None

class InvoiceItemResponse(BaseModel):
    id: int
    invoice_id: int
    name: str
    quantity: Decimal
    price: Decimal
    gst_rate: Decimal
    taxable_amount: Decimal
    cgst_rate: Decimal
    cgst_amount: Decimal
    sgst_rate: Decimal
    sgst_amount: Decimal
    igst_rate: Decimal
    igst_amount: Decimal
    line_total: Decimal

    model_config = ConfigDict(from_attributes=True)

class InvoiceResponse(BaseModel):
    id: int
    user_id: int
    invoice_number: str
    invoice_date: date
    due_date: Optional[date] = None
    transaction_type: str
    notes: Optional[str] = None
    subtitle: Optional[str] = None
    logo: Optional[str] = None
    settings: Optional[dict] = None
    business_details: PartyDetails
    customer_details: PartyDetails
    tax_breakdown: dict
    items: List[InvoiceItemResponse] = []
    paymentMethod: Optional[str] = Field(None, validation_alias="payment_method")
    paidAmount: float = Field(0.00, validation_alias="paid_amount")
    roundOff: float = Field(0.00, validation_alias="round_off")
    status: str = "due"

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
