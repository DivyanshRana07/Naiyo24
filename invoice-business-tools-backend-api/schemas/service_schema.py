from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional

class ServiceCreateRequest(BaseModel):
    name: str
    category: str
    sellingPrice: float
    gstPercent: float
    status: str = "active"

class ServiceUpdateRequest(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    sellingPrice: Optional[float] = None
    gstPercent: Optional[float] = None
    status: Optional[str] = None

class ServiceResponse(BaseModel):
    id: str
    code: str
    name: str
    category: str
    sellingPrice: float = Field(..., validation_alias="selling_price")
    gstPercent: float = Field(..., validation_alias="gst_percent")
    status: str

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    @field_validator("id", mode="before")
    @classmethod
    def serialize_id(cls, v):
        if v is not None:
            return str(v)
        return v
