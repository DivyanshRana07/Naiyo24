# pyrefly: ignore [missing-import]
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime


class AccountGroupCreateRequest(BaseModel):
    name: str
    type: str
    parentGroupId: Optional[str] = Field(None, validation_alias="parent_group_id")
    category: str
    description: Optional[str] = None
    isSystem: bool = Field(False, validation_alias="is_system")


class AccountGroupUpdateRequest(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    parentGroupId: Optional[str] = Field(None, validation_alias="parent_group_id")
    category: Optional[str] = None
    description: Optional[str] = None
    isSystem: Optional[bool] = Field(None, validation_alias="is_system")


class AccountGroupResponse(BaseModel):
    id: str = Field(..., validation_alias="group_id_str")
    name: str
    type: str
    parentGroupId: Optional[str] = Field(None, validation_alias="parent_group_id")
    category: str
    description: Optional[str] = None
    isSystem: bool = Field(False, validation_alias="is_system")
    createdAt: datetime = Field(..., validation_alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AccountCreateRequest(BaseModel):
    name: str
    code: str
    accountGroupId: str = Field(..., validation_alias="account_group_id")
    type: str
    openingBalance: float = Field(0.0, validation_alias="opening_balance")
    currentBalance: float = Field(0.0, validation_alias="current_balance")
    isActive: bool = Field(True, validation_alias="is_active")
    currency: str = "INR"


class AccountUpdateRequest(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    accountGroupId: Optional[str] = Field(None, validation_alias="account_group_id")
    type: Optional[str] = None
    openingBalance: Optional[float] = Field(None, validation_alias="opening_balance")
    currentBalance: Optional[float] = Field(None, validation_alias="current_balance")
    isActive: Optional[bool] = Field(None, validation_alias="is_active")
    currency: Optional[str] = None


class AccountResponse(BaseModel):
    id: str = Field(..., validation_alias="account_id_str")
    name: str
    code: str
    accountGroupId: str = Field(..., validation_alias="account_group_id")
    type: str
    openingBalance: float = Field(..., validation_alias="opening_balance")
    currentBalance: float = Field(..., validation_alias="current_balance")
    isActive: bool = Field(..., validation_alias="is_active")
    currency: str
    createdAt: datetime = Field(..., validation_alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
