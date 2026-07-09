from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional

from db import get_db
from core.dependencies import get_current_user
from models.db_models import User
from schemas.lead_schema import LeadCreateRequest, LeadUpdateRequest, LeadResponse
from schemas.customer_schema import CustomerResponse
from services.lead_service import (
    create_lead_service,
    list_leads_service,
    get_lead_by_id_service,
    update_lead_service,
    delete_lead_service,
    convert_lead_to_customer_service
)

router = APIRouter(prefix="/leads", tags=["Leads"])


@router.post("/create", response_model=dict)
def create_lead(
    payload: LeadCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    lead = create_lead_service(db, current_user.id, payload)
    return {
        "success": True,
        "message": "Lead created successfully",
        "data": LeadResponse.model_validate(lead)
    }


@router.get("/list", response_model=dict)
def list_leads(
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    leads = list_leads_service(db, current_user.id, status)
    return {
        "success": True,
        "data": [LeadResponse.model_validate(lead) for lead in leads]
    }


@router.get("/{id}", response_model=dict)
def get_lead(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    lead = get_lead_by_id_service(db, current_user.id, id)
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    return {
        "success": True,
        "data": LeadResponse.model_validate(lead)
    }


@router.put("/{id}", response_model=dict)
def update_lead(
    id: int,
    payload: LeadUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    lead = update_lead_service(db, current_user.id, id, payload)
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    return {
        "success": True,
        "message": "Lead updated successfully",
        "data": LeadResponse.model_validate(lead)
    }


@router.delete("/{id}", response_model=dict)
def delete_lead(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_lead_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Lead not found")
    return {
        "success": True,
        "message": "Lead deleted successfully"
    }


@router.post("/{id}/convert", response_model=dict)
def convert_lead_to_customer(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    customer = convert_lead_to_customer_service(db, current_user.id, id)
    if not customer:
        raise HTTPException(status_code=404, detail="Lead not found or already converted")
    return {
        "success": True,
        "message": "Lead converted to customer successfully",
        "data": CustomerResponse.model_validate(customer)
    }
