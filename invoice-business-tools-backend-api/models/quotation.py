from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Annotated, Literal
from uuid import uuid4

from pydantic import BaseModel, ConfigDict, Field, field_validator


def generate_quotation_id() -> str:
    return f"QUO-{uuid4().hex[:8].upper()}"


class QuotationItem(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True
    )

    name: Annotated[str, Field(min_length=2, max_length=150)]
    quantity: Annotated[Decimal, Field(gt=Decimal("0"))]
    price: Annotated[Decimal, Field(ge=Decimal("0"))]

    @field_validator("quantity", "price", mode="before")
    @classmethod
    def parse_decimal(cls, value):
        decimal_value = Decimal(str(value))
        if decimal_value <= 0:
            raise ValueError("Value must be greater than zero")
        return decimal_value


class QuotationCreateRequest(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True
    )

    quotation_id: str | None = None
    quotation_date: date = Field(default_factory=date.today)
    client_name: Annotated[str, Field(min_length=2, max_length=150)]
    client_address: Annotated[str | None, Field(max_length=300)] = None
    items: Annotated[list[QuotationItem], Field(min_length=1, max_length=100)]
    notes: Annotated[str | None, Field(max_length=500)] = None

    def resolved_quotation_id(self) -> str:
        if self.quotation_id:
            return self.quotation_id
        return generate_quotation_id()


class QuotationComputedData(BaseModel):
    quotation_id: str
    quotation_date: date
    client_name: str
    client_address: str | None
    items: list[QuotationItem]
    total_amount: Decimal
    notes: str | None


class QuotationSuccessResponse(BaseModel):
    success: Literal[True] = True
    message: str
    data: QuotationComputedData