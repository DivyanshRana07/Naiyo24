from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db import get_db
from models.db_models import User
from core.dependencies import get_current_user
from schemas.customer_schema import CustomerCreateRequest, CustomerUpdateRequest, CustomerResponse
from services.customer_service import (
    create_customer_service,
    list_customers_service,
    get_customer_by_id_service,
    update_customer_service,
    delete_customer_service
)

router = APIRouter(prefix="/customers", tags=["Customers"])

@router.post("", response_model=dict)
def create_customer(
    payload: CustomerCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = create_customer_service(db, current_user.id, payload)
        return {
            "success": True,
            "message": "Customer created successfully",
            "data": CustomerResponse.model_validate(result)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create customer: {str(e)}"
        )

@router.get("", response_model=dict)
def list_customers(
    q: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = list_customers_service(db, current_user.id, q)
        return {
            "success": True,
            "data": [CustomerResponse.model_validate(c) for c in result]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch customers: {str(e)}"
        )

@router.get("/{id}", response_model=dict)
def get_customer(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = get_customer_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Customer not found")
    return {
        "success": True,
        "data": CustomerResponse.model_validate(result)
    }

@router.put("/{id}", response_model=dict)
def update_customer(
    id: int,
    payload: CustomerUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = update_customer_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Customer not found")
    return {
        "success": True,
        "message": "Customer updated successfully",
        "data": CustomerResponse.model_validate(result)
    }

@router.delete("/{id}", response_model=dict)
def delete_customer(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_customer_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Customer not found")
    return {
        "success": True,
        "message": "Customer deleted successfully"
    }
