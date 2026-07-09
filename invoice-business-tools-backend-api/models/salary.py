from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Annotated, Literal
from uuid import uuid4

from pydantic import BaseModel, ConfigDict, Field, field_validator


def generate_salary_id() -> str:
    return f"SAL-{uuid4().hex[:8].upper()}"


class SalaryGenerateRequest(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True
    )

    salary_id: str | None = None
    salary_date: date = Field(default_factory=date.today)

    employee_name: Annotated[str, Field(min_length=2, max_length=150)]
    employee_id: Annotated[str, Field(min_length=2, max_length=50)]

    base_salary: Annotated[Decimal, Field(gt=Decimal("0"))]
    bonus: Annotated[Decimal, Field(ge=Decimal("0"))]
    deductions: Annotated[Decimal, Field(ge=Decimal("0"))] = Decimal("0")

    notes: Annotated[str | None, Field(max_length=500)] = None

    @field_validator("base_salary", "bonus", "deductions", mode="before")
    @classmethod
    def parse_salary_values(cls, value):
        decimal_value = Decimal(str(value))
        if decimal_value < 0:
            raise ValueError("Value cannot be negative")
        return decimal_value

    def resolved_salary_id(self) -> str:
        if self.salary_id:
            return self.salary_id
        return generate_salary_id()


class SalaryComputedData(BaseModel):
    salary_id: str
    salary_date: date
    employee_name: str
    employee_id: str
    base_salary: Decimal
    bonus: Decimal
    deductions: Decimal
    total_salary: Decimal
    notes: str | None


class SalarySuccessResponse(BaseModel):
    success: Literal[True] = True
    message: str
    data: SalaryComputedData