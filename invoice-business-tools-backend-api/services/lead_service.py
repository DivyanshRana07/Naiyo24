from sqlalchemy.orm import Session
from models.db_models import Lead, Customer
from schemas.lead_schema import LeadCreateRequest, LeadUpdateRequest
from typing import Optional, List


def create_lead_service(db: Session, user_id: int, payload: LeadCreateRequest) -> Lead:
    lead = Lead(
        user_id=user_id,
        name=payload.name,
        email=payload.email,
        phone=payload.phone,
        company=payload.company,
        status=payload.status,
        notes=payload.notes,
        source=payload.source
    )
    db.add(lead)
    db.commit()
    db.refresh(lead)
    return lead


def list_leads_service(db: Session, user_id: int, status: Optional[str] = None) -> List[Lead]:
    query = db.query(Lead).filter(Lead.user_id == user_id)
    if status:
        query = query.filter(Lead.status == status)
    return query.order_by(Lead.created_at.desc()).all()


def get_lead_by_id_service(db: Session, user_id: int, lead_id: int) -> Optional[Lead]:
    return db.query(Lead).filter(Lead.id == lead_id, Lead.user_id == user_id).first()


def update_lead_service(db: Session, user_id: int, lead_id: int, payload: LeadUpdateRequest) -> Optional[Lead]:
    lead = get_lead_by_id_service(db, user_id, lead_id)
    if not lead:
        return None
    
    if payload.name is not None:
        lead.name = payload.name
    if payload.email is not None:
        lead.email = payload.email
    if payload.phone is not None:
        lead.phone = payload.phone
    if payload.company is not None:
        lead.company = payload.company
    if payload.status is not None:
        lead.status = payload.status
    if payload.notes is not None:
        lead.notes = payload.notes
    if payload.source is not None:
        lead.source = payload.source
    
    db.commit()
    db.refresh(lead)
    return lead


def delete_lead_service(db: Session, user_id: int, lead_id: int) -> bool:
    lead = get_lead_by_id_service(db, user_id, lead_id)
    if not lead:
        return False
    db.delete(lead)
    db.commit()
    return True


def convert_lead_to_customer_service(db: Session, user_id: int, lead_id: int) -> Optional[Customer]:
    """Convert a lead to a customer"""
    lead = get_lead_by_id_service(db, user_id, lead_id)
    if not lead or lead.status == "converted":
        return None
    
    # Generate customer code
    last_customer = db.query(Customer).filter(Customer.user_id == user_id).order_by(Customer.id.desc()).first()
    if last_customer and last_customer.code.startswith("C"):
        try:
            last_num = int(last_customer.code[1:])
            new_code = f"C{str(last_num + 1).zfill(3)}"
        except:
            new_code = f"C{str(db.query(Customer).filter(Customer.user_id == user_id).count() + 1).zfill(3)}"
    else:
        new_code = "C001"
    
    # Create customer from lead
    customer = Customer(
        user_id=user_id,
        code=new_code,
        name=lead.name,
        mobile=lead.phone or "",
        email=lead.email,
        address=lead.company or "",
        status="active"
    )
    db.add(customer)
    db.flush()
    
    # Update lead status
    lead.status = "converted"
    lead.converted_to_customer_id = customer.id
    
    db.commit()
    db.refresh(customer)
    db.refresh(lead)
    
    return customer
