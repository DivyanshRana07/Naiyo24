from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db import get_db
from models.db_models import User
from core.dependencies import get_current_user
from schemas.service_schema import ServiceCreateRequest, ServiceUpdateRequest, ServiceResponse
from services.service_service import (
    create_service_service,
    list_services_service,
    get_service_by_id_service,
    update_service_service,
    delete_service_service
)

router = APIRouter(prefix="/services", tags=["Services"])

@router.post("", response_model=dict)
def create_service(
    payload: ServiceCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = create_service_service(db, current_user.id, payload)
        return {
            "success": True,
            "message": "Service created successfully",
            "data": ServiceResponse.model_validate(result)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create service: {str(e)}"
        )

@router.get("", response_model=dict)
def list_services(
    q: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = list_services_service(db, current_user.id, q)
        return {
            "success": True,
            "data": [ServiceResponse.model_validate(s) for s in result]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch services: {str(e)}"
        )

@router.get("/{id}", response_model=dict)
def get_service(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = get_service_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Service not found")
    return {
        "success": True,
        "data": ServiceResponse.model_validate(result)
    }

@router.put("/{id}", response_model=dict)
def update_service(
    id: int,
    payload: ServiceUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = update_service_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Service not found")
    return {
        "success": True,
        "message": "Service updated successfully",
        "data": ServiceResponse.model_validate(result)
    }

@router.delete("/{id}", response_model=dict)
def delete_service(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_service_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Service not found")
    return {
        "success": True,
        "message": "Service deleted successfully"
    }
