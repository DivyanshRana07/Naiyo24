from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional

class CustomerCreateRequest(BaseModel):
    name: str
    mobile: str
    email: Optional[str] = None
    address: Optional[str] = None
    gstNumber: Optional[str] = None
    openingBalance: float = 0.0
    creditLimit: float = 0.0
    status: str = "active"

class CustomerUpdateRequest(BaseModel):
    name: Optional[str] = None
    mobile: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    gstNumber: Optional[str] = None
    openingBalance: Optional[float] = None
    creditLimit: Optional[float] = None
    status: Optional[str] = None

class CustomerResponse(BaseModel):
    id: str
    code: str
    name: str
    mobile: str
    email: Optional[str] = None
    address: Optional[str] = None
    gstNumber: Optional[str] = Field(None, validation_alias="gst_number")
    openingBalance: float = Field(0.0, validation_alias="opening_balance")
    creditLimit: float = Field(0.0, validation_alias="credit_limit")
    status: str

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    @field_validator("id", mode="before")
    @classmethod
    def serialize_id(cls, v):
        if v is not None:
            return str(v)
        return v
