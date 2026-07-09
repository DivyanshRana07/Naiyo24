# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import Vendor
from schemas.vendor_schema import VendorCreateRequest, VendorUpdateRequest
from services.activity_service import create_activity

def add_vendor_service(db: Session, data: VendorCreateRequest):
    new_vendor = Vendor(
        user_id=data.user_id,
        name=data.name,
        email=data.email,
        phone=data.phone,
        address=data.address,
        gstin=data.gstin,
        contact_person=data.contact_person
    )
    db.add(new_vendor)
    db.commit()
    db.refresh(new_vendor)

    if new_vendor.user_id is not None:
        create_activity(
            db, new_vendor.user_id,
            action="Created",
            entity_type="Vendor",
            entity_id=str(new_vendor.id),
            title="Vendor Added",
            description=f"Vendor \"{new_vendor.name}\" was added successfully.",
        )
    return new_vendor

def list_vendors_service(db: Session, user_id: int = None):
    query = db.query(Vendor)
    if user_id is not None:
        query = query.filter(Vendor.user_id == user_id)
    return query.all()

def get_vendor_by_id_service(db: Session, vendor_id: int):
    return db.query(Vendor).filter(Vendor.id == vendor_id).first()

def update_vendor_service(db: Session, vendor_id: int, data: VendorUpdateRequest):
    vendor = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not vendor:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(vendor, key, value)
        
    db.commit()
    db.refresh(vendor)

    if vendor.user_id is not None:
        create_activity(
            db, vendor.user_id,
            action="Updated",
            entity_type="Vendor",
            entity_id=str(vendor.id),
            title="Vendor Updated",
            description=f"Vendor \"{vendor.name}\" was updated successfully.",
        )
    return vendor

def delete_vendor_service(db: Session, vendor_id: int) -> bool:
    vendor = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not vendor:
        return False
        
    vendor_name = vendor.name
    vendor_user_id = vendor.user_id
    vendor_id_val = vendor.id
    db.delete(vendor)
    db.commit()

    if vendor_user_id is not None:
        create_activity(
            db, vendor_user_id,
            action="Deleted",
            entity_type="Vendor",
            entity_id=str(vendor_id_val),
            title="Vendor Deleted",
            description=f"Vendor \"{vendor_name}\" was deleted.",
        )
    return True
