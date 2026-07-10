# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
import io
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from db import get_db
from models.db_models import User
from core.dependencies import get_current_user
from schemas.item_schema import ItemCreateRequest, ItemUpdateRequest, ItemResponse, ItemStockUpdateRequest
from services.item_service import (
    create_item_service,
    list_items_service,
    get_item_by_id_service,
    update_item_service,
    update_item_stock_service,
    delete_item_service
)
from services.gst_invoice_generator.list_pdf_service import ListPDFService

router = APIRouter(prefix="/items", tags=["Items"])

@router.post("", response_model=dict)
def create_item(
    payload: ItemCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = create_item_service(db, current_user.id, payload)
        return {
            "success": True,
            "message": "Item created successfully",
            "data": ItemResponse.model_validate(result).model_dump(by_alias=True)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create item: {str(e)}"
        )

@router.get("", response_model=dict)
def list_items(
    q: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = list_items_service(db, current_user.id, q)
        return {
            "success": True,
            "data": [ItemResponse.model_validate(p).model_dump(by_alias=True) for p in result]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch items: {str(e)}"
        )


@router.get("/export-list-pdf")
def export_item_list_pdf(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Export all items as a formatted PDF list"""
    try:
        items = list_items_service(db, current_user.id)
        
        if not items:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No items found"
            )
        
        pdf_bytes = ListPDFService.render_item_list_pdf(items)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = "Item-List-Export.pdf"
        
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate item list PDF: {str(e)}"
        )


@router.get("/{id}", response_model=dict)
def get_item(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = get_item_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Item not found")
    return {
        "success": True,
        "data": ItemResponse.model_validate(result).model_dump(by_alias=True)
    }

@router.put("/{id}", response_model=dict)
def update_item(
    id: int,
    payload: ItemUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = update_item_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Item not found")
    return {
        "success": True,
        "message": "Item updated successfully",
        "data": ItemResponse.model_validate(result).model_dump(by_alias=True)
    }

@router.patch("/{id}/stock", response_model=dict)
def update_item_stock(
    id: int,
    payload: ItemStockUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = update_item_stock_service(db, current_user.id, id, payload)
    return {
        "success": True,
        "message": "Item stock updated successfully",
        "data": ItemResponse.model_validate(result).model_dump(by_alias=True)
    }

@router.delete("/{id}", response_model=dict)
def delete_item(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_item_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Item not found")
    return {
        "success": True,
        "message": "Item deleted successfully"
    }
