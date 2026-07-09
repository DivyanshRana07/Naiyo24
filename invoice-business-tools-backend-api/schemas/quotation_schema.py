# pyrefly: ignore [missing-import]
from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import date


# pyrefly: ignore [missing-import]
from pydantic import Field

class QuotationItemBase(BaseModel):
    name: str
    price: float
    quantity: int
    discountPercent: float = Field(0.00, validation_alias="discount_percent")
    gstPercent: float = Field(0.00, validation_alias="gst_percent")

    model_config = ConfigDict(populate_by_name=True)


class QuotationItemCreate(QuotationItemBase):
    pass


class QuotationItemResponse(QuotationItemBase):
    id: int
    quotation_id: int

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)



class QuotationCreateRequest(BaseModel):
    customer_id: Optional[str] = None
    customer_name: str
    customer_mobile: Optional[str] = None
    customer_address: Optional[str] = None
    customer_gst: Optional[str] = None

    quotation_date: Optional[date] = None
    valid_until: Optional[date] = None
    payment_terms: Optional[str] = None
    currency: Optional[str] = "INR"
    
    subtitle: Optional[str] = None
    logo: Optional[str] = None
    settings: Optional[dict] = None

    items: List[QuotationItemCreate]
    status: Optional[str] = "Draft"


class QuotationUpdateRequest(BaseModel):
    customer_id: Optional[str] = None
    customer_name: Optional[str] = None
    customer_mobile: Optional[str] = None
    customer_address: Optional[str] = None
    customer_gst: Optional[str] = None

    quotation_date: Optional[date] = None
    valid_until: Optional[date] = None
    payment_terms: Optional[str] = None
    currency: Optional[str] = None

    status: Optional[str] = None


class QuotationResponse(BaseModel):
    id: int

    customer_id: Optional[str] = None
    customer_name: str
    customer_mobile: Optional[str] = None
    customer_address: Optional[str] = None
    customer_gst: Optional[str] = None

    quotation_date: Optional[date] = None
    valid_until: Optional[date] = None
    payment_terms: Optional[str] = None
    currency: Optional[str] = None
    
    subtitle: Optional[str] = None
    logo: Optional[str] = None
    settings: Optional[dict] = None

    total: float
    status: str

    items: List[QuotationItemResponse] = []

    model_config = ConfigDict(from_attributes=True)