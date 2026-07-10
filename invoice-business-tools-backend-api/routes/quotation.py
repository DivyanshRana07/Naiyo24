import io
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from models.db_models import Invoice
from services.gst_invoice_generator.pdf_service import InvoicePDFService


from schemas.quotation_schema import (
    QuotationCreateRequest,
    QuotationUpdateRequest,
    QuotationResponse
)

from services.quotation_service import (
    create_quotation_service,
    list_quotation_service,
    get_quotation_by_id_service,
    update_quotation_service,
    delete_quotation_service
)

from db import get_db

router = APIRouter(
    prefix="/quotation",
    tags=["Quotation"]
)


@router.post("/create", response_model=dict)
def create_quotation(
    payload: QuotationCreateRequest,
    db: Session = Depends(get_db)
):
    result = create_quotation_service(db, 1, payload)

    return {
        "success": True,
        "message": "Quotation created",
        "data": QuotationResponse.model_validate(result)
    }


@router.get("/list", response_model=dict)
def list_quotations(
    db: Session = Depends(get_db)
):
    try:
        result = list_quotation_service(db, 1)

        return {
            "success": True,
            "message": "Quotation list fetched successfully",
            "data": [
                QuotationResponse.model_validate(q)
                for q in result
            ]
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch quotation records: {str(e)}"
        )


@router.get("/{id}", response_model=dict)
def get_quotation(
    id: int,
    db: Session = Depends(get_db)
):
    result = get_quotation_by_id_service(db, 1, id)

    if not result:
        raise HTTPException(
            status_code=404,
            detail="Quotation not found"
        )

    return {
        "success": True,
        "message": "Quotation fetched successfully",
        "data": QuotationResponse.model_validate(result)
    }


@router.put("/{id}", response_model=dict)
def update_quotation(
    id: int,
    payload: QuotationUpdateRequest,
    db: Session = Depends(get_db)
):
    result = update_quotation_service(db, 1, id, payload)

    if not result:
        raise HTTPException(
            status_code=404,
            detail="Quotation not found"
        )

    return {
        "success": True,
        "message": "Quotation updated successfully",
        "data": QuotationResponse.model_validate(result)
    }


@router.delete("/{id}", response_model=dict)
def delete_quotation(
    id: int,
    db: Session = Depends(get_db)
):
    success = delete_quotation_service(db, 1, id)

    if not success:
        raise HTTPException(
            status_code=404,
            detail="Quotation not found"
        )

    return {
        "success": True,
        "message": "Quotation deleted successfully"
    }


@router.get("/{id}/download-pdf")
def download_quotation_pdf(
    id: int,
    db: Session = Depends(get_db)
):
    db_quotation = get_quotation_by_id_service(db, 1, id)
    if not db_quotation:
        raise HTTPException(
            status_code=404,
            detail="Quotation not found"
        )
    
    try:
        # Fetch user's latest invoice for business details
        latest_invoice = db.query(Invoice).filter(Invoice.user_id == 1).order_by(Invoice.id.desc()).first()
        business_details = latest_invoice.business_details if latest_invoice else None
        
        pdf_bytes = InvoicePDFService.render_quotation_pdf(db_quotation, business_details)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = f"Quotation-{db_quotation.id}.pdf"
        
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate PDF: {str(e)}"
        )