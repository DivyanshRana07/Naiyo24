from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional

class ItemCreateRequest(BaseModel):
    name: str
    category: str
    unit: str
    purchasePrice: float
    sellingPrice: float
    stockQty: int
    gstPercent: float
    status: str = "active"

class ItemUpdateRequest(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    unit: Optional[str] = None
    purchasePrice: Optional[float] = None
    sellingPrice: Optional[float] = None
    stockQty: Optional[int] = None
    gstPercent: Optional[float] = None
    status: Optional[str] = None

class ItemStockUpdateRequest(BaseModel):
    deduct: Optional[int] = None
    restore: Optional[int] = None

class ItemResponse(BaseModel):
    id: str
    code: str
    name: str
    category: str
    unit: str
    purchasePrice: float = Field(..., validation_alias="purchase_price")
    sellingPrice: float = Field(..., validation_alias="selling_price")
    stockQty: int = Field(..., validation_alias="stock_qty")
    gstPercent: float = Field(..., validation_alias="gst_percent")
    status: str

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    @field_validator("id", mode="before")
    @classmethod
    def serialize_id(cls, v):
        if v is not None:
            return str(v)
        return v
