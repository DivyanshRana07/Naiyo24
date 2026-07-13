# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
import io
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from db import get_db
from schemas.expense_schema import ExpenseCreateRequest, ExpenseUpdateRequest, ExpenseResponse
from services.expense_service import (
    create_expense_service,
    list_expenses_service,
    get_expense_by_id_service,
    update_expense_service,
    delete_expense_service,
)
from services.gst_invoice_generator.list_pdf_service import ListPDFService

from core.dependencies import get_current_user
from models.db_models import User

router = APIRouter(prefix="/expenses", tags=["Expenses"])

@router.post("/create", response_model=dict)
def create_expense(
    payload: ExpenseCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    payload.user_id = current_user.id
    result = create_expense_service(db, payload)
    return {
        "success": True,
        "message": "Expense created successfully",
        "data": ExpenseResponse.model_validate(result)
    }

@router.get("/list", response_model=dict)
def list_expenses(
    user_id: int = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    target_user_id = user_id if user_id is not None else current_user.id
    result = list_expenses_service(db, target_user_id)
    return {
        "success": True,
        "data": [ExpenseResponse.model_validate(expense) for expense in result]
    }


@router.get("/export-list-pdf")
def export_expense_list_pdf(db: Session = Depends(get_db)):
    """Export all expenses as a formatted PDF list"""
    try:
        expenses = list_expenses_service(db, user_id=None)
        
        if not expenses:
            raise HTTPException(
                status_code=404,
                detail="No expenses found"
            )
        
        pdf_bytes = ListPDFService.render_expense_list_pdf(expenses)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = "Expenses-Export.pdf"
        
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
def get_expense(id: int, db: Session = Depends(get_db)):
    result = get_expense_by_id_service(db, id)
    if not result:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {
        "success": True,
        "data": ExpenseResponse.model_validate(result)
    }

@router.put("/{id}", response_model=dict)
def update_expense(id: int, payload: ExpenseUpdateRequest, db: Session = Depends(get_db)):
    result = update_expense_service(db, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {
        "success": True,
        "message": "Expense updated successfully",
        "data": ExpenseResponse.model_validate(result)
    }

@router.delete("/{id}", response_model=dict)
def delete_expense(id: int, db: Session = Depends(get_db)):
    success = delete_expense_service(db, id)
    if not success:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {
        "success": True,
        "message": "Expense deleted successfully"
    }

