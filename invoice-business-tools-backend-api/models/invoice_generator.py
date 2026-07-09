from __future__ import annotations

from datetime import date
from decimal import Decimal, ROUND_HALF_UP
from typing import Annotated, Literal, Optional
from uuid import uuid4
# pyrefly: ignore [missing-import]
from pydantic import BaseModel, ConfigDict, Field, field_validator


TWOPLACES = Decimal("0.01")


def round_money(value: Decimal) -> Decimal:
    return value.quantize(TWOPLACES, rounding=ROUND_HALF_UP)


class PartyDetails(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)

    name: str
    address: Optional[str] = None
    address_line_1: Optional[str] = None
    address_line_2: Optional[str] = None
    city: Optional[str] = None
    state_name: Optional[str] = None
    state_code: Optional[str] = None
    postal_code: Optional[str] = None
    gstin: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None



class InvoiceItemInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    name: Annotated[str, Field(min_length=2, max_length=150)]
    quantity: Annotated[Decimal, Field(gt=Decimal("0"))]
    price: Annotated[Decimal, Field(ge=Decimal("0"))]
    gst_rate: Annotated[Decimal, Field(ge=Decimal("0"), le=Decimal("100"))]

    @field_validator("quantity", "price", "gst_rate", mode="before")
    @classmethod
    def parse_decimal(cls, value: object) -> Decimal:
        decimal_value = Decimal(str(value))
        if not decimal_value.is_finite():
            raise ValueError("must be a valid finite decimal number")
        return decimal_value


class InvoiceCreateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True, populate_by_name=True)

    invoice_number: Optional[str] = None
    invoice_date: date = Field(default_factory=date.today)
    due_date: Optional[date] = None
    invoice_type: Literal["regular", "proforma"] = "regular"
    notes: Optional[str] = None
    subtitle: Optional[str] = None
    logo: Optional[str] = None
    settings: Optional[dict] = None
    business: PartyDetails
    customer: PartyDetails
    items: list[InvoiceItemInput]
    paymentMethod: Optional[str] = Field(None, validation_alias="payment_method")
    paidAmount: float = Field(0.00, validation_alias="paid_amount")
    roundOff: float = Field(0.00, validation_alias="round_off")
    status: str = "due"


    @field_validator("due_date")
    @classmethod
    def validate_due_date(cls, value: date | None, info):
        if value is None:
            return value
        invoice_date = info.data.get("invoice_date")
        if invoice_date and value < invoice_date:
            raise ValueError("due_date cannot be earlier than invoice_date")
        return value

    def resolved_invoice_number(self) -> str:
        if self.invoice_number:
            return self.invoice_number
        return f"INV-{uuid4().hex[:10].upper()}"


class InvoiceItemComputed(BaseModel):
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


class TaxBreakdown(BaseModel):
    total_taxable_amount: Decimal
    total_cgst: Decimal
    total_sgst: Decimal
    total_igst: Decimal
    total_tax: Decimal
    grand_total: Decimal


class InvoiceComputedData(BaseModel):
    invoice_number: str
    invoice_date: date
    due_date: Optional[date] = None
    transaction_type: Literal["intra_state", "inter_state"]
    invoice_type: Literal["regular", "proforma"] = "regular"
    notes: Optional[str] = None
    subtitle: Optional[str] = None
    logo: Optional[str] = None
    settings: Optional[dict] = None
    business: PartyDetails
    customer: PartyDetails
    items: list[InvoiceItemComputed]
    totals: TaxBreakdown
    payment_method: Optional[str] = None
    paid_amount: float = 0.00
    round_off: float = 0.00
    status: str = "due"



class ApiSuccessResponse(BaseModel):
    success: Literal[True] = True
    message: str
    data: InvoiceComputedData
