"""
activity_service.py — Business logic for ActivityLog records.

Functions
---------
create_activity(db, user_id, action, entity_type, entity_id, title, description)
    Persist one ActivityLog row.  Non-raising: if anything goes wrong the error
    is swallowed so the caller's primary operation is never interrupted.

list_activities(db, user_id, limit, offset)
    Return the authenticated user's activity feed, newest first.
"""

from __future__ import annotations

import logging
from typing import Optional

from sqlalchemy.orm import Session

from models.db_models import ActivityLog

logger = logging.getLogger(__name__)


def create_activity(
    db: Session,
    user_id: int,
    action: str,
    entity_type: str,
    entity_id: Optional[str],
    title: str,
    description: Optional[str] = None,
) -> Optional[ActivityLog]:
    """
    Persist an ActivityLog row after a successful business operation.

    This function is intentionally non-raising: any exception is caught and
    logged so that a logging failure can never roll back or break the calling
    service's already-committed transaction.

    Parameters
    ----------
    db          : SQLAlchemy session (already committed by the calling service)
    user_id     : ID of the authenticated user who performed the action
    action      : Short verb — "Created", "Updated", "Deleted", "Generated"
    entity_type : Entity category — "Invoice", "Customer", "Vendor", etc.
    entity_id   : String identifier of the affected entity (may be None on delete)
    title       : Human-readable event title, e.g. "Invoice Created"
    description : Full sentence, e.g. "Invoice INV-0042 was created successfully."
    """
    try:
        log = ActivityLog(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            entity_id=str(entity_id) if entity_id is not None else None,
            title=title,
            description=description,
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return log
    except Exception as exc:  # pragma: no cover
        logger.error(
            "Failed to create activity log: action=%s entity_type=%s entity_id=%s — %s",
            action,
            entity_type,
            entity_id,
            exc,
            exc_info=True,
        )
        try:
            db.rollback()
        except Exception:
            pass
        return None


def list_activities(
    db: Session,
    user_id: int,
    limit: int = 50,
    offset: int = 0,
) -> list[ActivityLog]:
    """
    Return the current user's activity feed ordered by most recent first.

    Parameters
    ----------
    db      : SQLAlchemy session
    user_id : Scopes results to a single user (ownership enforced)
    limit   : Maximum number of records to return (default 50)
    offset  : Number of records to skip for pagination (default 0)
    """
    return (
        db.query(ActivityLog)
        .filter(ActivityLog.user_id == user_id)
        .order_by(ActivityLog.created_at.desc(), ActivityLog.id.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )
