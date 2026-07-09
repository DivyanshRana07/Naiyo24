from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Annotated, Literal
from uuid import uuid4

from pydantic import BaseModel, ConfigDict, Field, field_validator


def generate_expense_id() -> str:
    return f"EXP-{uuid4().hex[:8].upper()}"


class ExpenseCategory(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True
    )

    category_name: Annotated[str, Field(
        min_length=2,
        max_length=100
    )]

    category_type: Literal[
        "Food",
        "Travel",
        "Office",
        "Salary",
        "Utilities",
        "Other"
    ]


class ExpenseCreateRequest(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True
    )

    expense_id: str | None = None

    expense_date: date = Field(
        default_factory=date.today
    )

    title: Annotated[str, Field(
        min_length=2,
        max_length=150
    )]

    description: Annotated[str | None, Field(
        max_length=300
    )] = None

    amount: Annotated[Decimal, Field(
        gt=Decimal("0")
    )]

    payment_method: Literal[
        "Cash",
        "UPI",
        "Card",
        "Bank Transfer"
    ]

    category: ExpenseCategory

    notes: Annotated[str | None, Field(
        max_length=500
    )] = None

    @field_validator("amount", mode="before")
    @classmethod
    def validate_amount(cls, value):
        decimal_value = Decimal(str(value))
        if decimal_value <= 0:
            raise ValueError("Amount must be greater than zero")
        return decimal_value

    def resolved_expense_id(self) -> str:
        if self.expense_id:
            return self.expense_id
        return generate_expense_id()


class ExpenseComputedData(BaseModel):
    expense_id: str
    expense_date: date
    title: str
    description: str | None
    amount: Decimal
    payment_method: str
    category: ExpenseCategory
    notes: str | None


class ExpenseListData(BaseModel):
    total_expenses: int
    expenses: list[ExpenseComputedData]


class ApiSuccessResponse(BaseModel):
    success: Literal[True] = True
    message: str
    data: ExpenseComputedData


class ExpenseListResponse(BaseModel):
    success: Literal[True] = True
    message: str
    data: ExpenseListData