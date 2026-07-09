"""
routes/activity.py — Activity feed endpoints.

Endpoints
---------
GET /api/v1/activity
    Returns the authenticated user's activity history, newest first.
    Supports optional ?limit= and ?offset= query parameters for pagination.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from db import get_db
from schemas.activity_schema import ActivityResponse
from services.activity_service import list_activities

router = APIRouter(prefix="/activity", tags=["Activity"])


@router.get("", response_model=dict)
def get_activity_feed(
    limit: int = Query(default=50, ge=1, le=200, description="Max records to return"),
    offset: int = Query(default=0, ge=0, description="Records to skip (pagination)"),
    user_id: int = Query(default=1, description="User ID (defaults to 1 for development)"),
    db: Session = Depends(get_db),
):
    """
    Retrieve the activity feed for the specified user.

    Returns activities ordered from newest to oldest.
    Use `limit` and `offset` for pagination.
    
    Development mode: user_id defaults to 1 (bypassing authentication)
    """
    activities = list_activities(db, user_id, limit=limit, offset=offset)
    return {
        "success": True,
        "data": [
            ActivityResponse.model_validate(a).model_dump(by_alias=True)
            for a in activities
        ],
    }
