from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from schemas.expense_schema import ExpenseCreateRequest, ExpenseUpdateRequest, ExpenseResponse
from services.expense_service import (
    add_expense_service, 
    list_expenses_service,
    get_expense_by_id_service,
    update_expense_service,
    delete_expense_service
)
from db import get_db
from models.db_models import User
from core.dependencies import get_current_user

router = APIRouter(prefix="/expenses", tags=["Expenses"])

@router.post("", response_model=dict)
@router.post("/add", response_model=dict)
def add_expense(payload: ExpenseCreateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = add_expense_service(db, current_user.id, payload)
    return {
        "success": True,
        "message": "Expense added",
        "data": ExpenseResponse.model_validate(result)
    }

@router.get("", response_model=dict)
@router.get("/list", response_model=dict)
def list_expenses(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):

    result = list_expenses_service(db, current_user.id)
    return {
        "success": True,
        "data": [ExpenseResponse.model_validate(expense) for expense in result]
    }

@router.get("/{id}", response_model=dict)
def get_expense(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = get_expense_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {
        "success": True,
        "message": "Expense fetched successfully",
        "data": ExpenseResponse.model_validate(result)
    }

@router.put("/{id}", response_model=dict)
def update_expense(id: int, payload: ExpenseUpdateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = update_expense_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {
        "success": True,
        "message": "Expense updated successfully",
        "data": ExpenseResponse.model_validate(result)
    }

@router.delete("/{id}", response_model=dict)
def delete_expense(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    success = delete_expense_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {
        "success": True,
        "message": "Expense deleted successfully"
    }