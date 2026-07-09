# pyrefly: ignore [missing-import]
from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, Annotated
from datetime import datetime


class VendorCreateRequest(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    gstin: Optional[str] = None
    user_id: Optional[int] = None
    contact_person: Annotated[
        Optional[str], Field(alias="contactPerson")
    ] = None

    model_config = ConfigDict(populate_by_name=True)


class VendorUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    gstin: Optional[str] = None
    contact_person: Annotated[
        Optional[str], Field(alias="contactPerson")
    ] = None

    model_config = ConfigDict(populate_by_name=True)


class VendorResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    gstin: Optional[str] = None
    contact_person: Annotated[
        Optional[str], Field(alias="contactPerson")
    ] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
