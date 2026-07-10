"""
routes/activity.py — Activity feed endpoints.

Endpoints
---------
GET /api/v1/activity
    Returns the authenticated user's activity history, newest first.
    Supports optional ?limit= and ?offset= query parameters for pagination.
"""

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
import io
from sqlalchemy.orm import Session

from db import get_db
from schemas.activity_schema import ActivityResponse
from services.activity_service import list_activities
from services.gst_invoice_generator.list_pdf_service import ListPDFService

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


@router.get("/export-list-pdf")
def export_activity_list_pdf(
    user_id: int = Query(default=1, description="User ID"),
    db: Session = Depends(get_db)
):
    """Export all activities as a formatted PDF list"""
    try:
        activities = list_activities(db, user_id, limit=1000, offset=0)
        
        if not activities:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=404,
                detail="No activities found"
            )
        
        pdf_bytes = ListPDFService.render_activity_list_pdf(activities)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = "Activity-Log-Export.pdf"
        
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate activity list PDF: {str(e)}"
        )


@router.delete("/{activity_id}")
def delete_activity(
    activity_id: int,
    user_id: int = Query(default=1, description="User ID"),
    db: Session = Depends(get_db),
):
    """
    Delete a specific activity log by ID.
    
    Only allows deletion if the activity belongs to the specified user.
    """
    from fastapi import HTTPException
    from models.db_models import ActivityLog
    
    # Find the activity
    activity = db.query(ActivityLog).filter(
        ActivityLog.id == activity_id,
        ActivityLog.user_id == user_id
    ).first()
    
    if not activity:
        raise HTTPException(
            status_code=404,
            detail=f"Activity with ID {activity_id} not found or does not belong to user"
        )
    
    # Delete the activity
    try:
        db.delete(activity)
        db.commit()
        
        return {
            "success": True,
            "message": f"Activity {activity_id} deleted successfully"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete activity: {str(e)}"
        )
