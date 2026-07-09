# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
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

router = APIRouter(prefix="/vendors", tags=["Vendors"])

@router.post("/add", response_model=dict)
def add_vendor(payload: VendorCreateRequest, db: Session = Depends(get_db)):
    result = add_vendor_service(db, payload)
    return {
        "success": True,
        "message": "Vendor added successfully",
        "data": VendorResponse.model_validate(result)
    }

@router.get("/list", response_model=dict)
def list_vendors(user_id: int = None, db: Session = Depends(get_db)):
    result = list_vendors_service(db, user_id)
    return {
        "success": True,
        "data": [VendorResponse.model_validate(v) for v in result]
    }

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
