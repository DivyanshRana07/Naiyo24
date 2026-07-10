# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
import io
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from db import get_db
from schemas.purchase_order_schema import PurchaseOrderCreateRequest, PurchaseOrderUpdateRequest, PurchaseOrderResponse
from schemas.expense_schema import ExpenseResponse
from services.purchase_order_service import (
    create_po_service,
    list_pos_service,
    get_po_by_id_service,
    update_po_service,
    delete_po_service,
    convert_po_to_expense_service
)
from services.gst_invoice_generator.list_pdf_service import ListPDFService

router = APIRouter(prefix="/purchase-orders", tags=["Purchase Orders"])

@router.post("/create", response_model=dict)
def create_po(payload: PurchaseOrderCreateRequest, db: Session = Depends(get_db)):
    result = create_po_service(db, payload)
    return {
        "success": True,
        "message": "Purchase order created successfully",
        "data": PurchaseOrderResponse.model_validate(result)
    }

@router.get("/list", response_model=dict)
def list_pos(user_id: int = None, db: Session = Depends(get_db)):
    result = list_pos_service(db, user_id)
    return {
        "success": True,
        "data": [PurchaseOrderResponse.model_validate(po) for po in result]
    }


@router.get("/export-list-pdf")
def export_po_list_pdf(db: Session = Depends(get_db)):
    """Export all purchase orders as a formatted PDF list"""
    try:
        pos = list_pos_service(db, user_id=None)
        
        if not pos:
            raise HTTPException(
                status_code=404,
                detail="No purchase orders found"
            )
        
        pdf_bytes = ListPDFService.render_purchase_order_list_pdf(pos)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = "Expense-Report-Export.pdf"
        
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate expense report PDF: {str(e)}"
        )


@router.get("/{id}", response_model=dict)
def get_po(id: int, db: Session = Depends(get_db)):
    result = get_po_by_id_service(db, id)
    if not result:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    return {
        "success": True,
        "data": PurchaseOrderResponse.model_validate(result)
    }

@router.put("/{id}", response_model=dict)
def update_po(id: int, payload: PurchaseOrderUpdateRequest, db: Session = Depends(get_db)):
    result = update_po_service(db, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    return {
        "success": True,
        "message": "Purchase order updated successfully",
        "data": PurchaseOrderResponse.model_validate(result)
    }

@router.delete("/{id}", response_model=dict)
def delete_po(id: int, db: Session = Depends(get_db)):
    success = delete_po_service(db, id)
    if not success:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    return {
        "success": True,
        "message": "Purchase order deleted successfully"
    }

@router.post("/{id}/convert-to-expense", response_model=dict)
def convert_po_to_expense(id: int, db: Session = Depends(get_db)):
    result = convert_po_to_expense_service(db, id)
    if not result:
        raise HTTPException(status_code=404, detail="Purchase order not found or could not be converted")
    return {
        "success": True,
        "message": "Purchase order converted to expense successfully",
        "data": ExpenseResponse.model_validate(result)
    }
