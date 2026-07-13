# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
import io
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from db import get_db
from schemas.vendor_schema import VendorCreateRequest, VendorUpdateRequest, VendorResponse
from services.vendor_service import (
    add_vendor_service,
    list_vendors_service,
    get_vendor_by_id_service,
    update_vendor_service,
    delete_vendor_service
)
from services.gst_invoice_generator.list_pdf_service import ListPDFService

from core.dependencies import get_current_user
from models.db_models import User

router = APIRouter(prefix="/vendors", tags=["Vendors"])

@router.post("/add", response_model=dict)
def add_vendor(
    payload: VendorCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    payload.user_id = current_user.id
    result = add_vendor_service(db, payload)
    return {
        "success": True,
        "message": "Vendor added successfully",
        "data": VendorResponse.model_validate(result)
    }

@router.get("/list", response_model=dict)
def list_vendors(
    user_id: int = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    target_user_id = user_id if user_id is not None else current_user.id
    result = list_vendors_service(db, target_user_id)
    return {
        "success": True,
        "data": [VendorResponse.model_validate(v) for v in result]
    }


@router.get("/export-list-pdf")
def export_vendor_list_pdf(db: Session = Depends(get_db)):
    """Export all vendors as a formatted PDF list"""
    try:
        vendors = list_vendors_service(db, user_id=None)
        
        if not vendors:
            raise HTTPException(
                status_code=404,
                detail="No vendors found"
            )
        
        pdf_bytes = ListPDFService.render_vendor_list_pdf(vendors)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = "Vendor-List-Export.pdf"
        
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate vendor list PDF: {str(e)}"
        )


@router.get("/{id}", response_model=dict)
def get_vendor(id: int, db: Session = Depends(get_db)):
    result = get_vendor_by_id_service(db, id)
    if not result:
        raise HTTPException(status_code=404, detail="Vendor not found")
    return {
        "success": True,
        "data": VendorResponse.model_validate(result)
    }

@router.put("/{id}", response_model=dict)
def update_vendor(id: int, payload: VendorUpdateRequest, db: Session = Depends(get_db)):
    result = update_vendor_service(db, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Vendor not found")
    return {
        "success": True,
        "message": "Vendor updated successfully",
        "data": VendorResponse.model_validate(result)
    }

@router.delete("/{id}", response_model=dict)
def delete_vendor(id: int, db: Session = Depends(get_db)):
    success = delete_vendor_service(db, id)
    if not success:
        raise HTTPException(status_code=404, detail="Vendor not found")
    return {
        "success": True,
        "message": "Vendor deleted successfully"
    }
