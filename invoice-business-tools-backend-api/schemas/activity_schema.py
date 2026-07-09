from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime


class ActivityResponse(BaseModel):
    """
    Response schema for an ActivityLog record.

    Field names use camelCase aliases to match the Flutter frontend JSON contract:
      action, entityType, entityId, title, description, createdAt

    The backend ORM model uses snake_case column names (entity_type, entity_id,
    created_at). Pydantic maps these automatically via the aliases and
    populate_by_name=True so that model_validate(orm_obj) works directly.
    """

    id: int

    action: str
    """Action performed — e.g. "Created", "Updated", "Deleted", "Generated"."""

    entity_type: str = Field(alias="entityType")
    """Entity category — e.g. "Invoice", "Customer", "Vendor"."""

    entity_id: Optional[str] = Field(default=None, alias="entityId")
    """String identifier of the affected entity (int id or invoice number)."""

    title: str
    """Human-readable event title — e.g. "Invoice Created"."""

    description: Optional[str] = None
    """Full description sentence — e.g. "Invoice INV-0042 was created successfully." """

    created_at: datetime = Field(alias="createdAt")
    """ISO-8601 UTC timestamp of when the event occurred."""

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,  # allow validation from both snake_case attrs and camelCase aliases
    )

