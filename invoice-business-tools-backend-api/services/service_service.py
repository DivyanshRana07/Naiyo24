from sqlalchemy.orm import Session
from models.db_models import Service
from schemas.service_schema import ServiceCreateRequest, ServiceUpdateRequest
from sqlalchemy import or_

def generate_service_code(db: Session, user_id: int) -> str:
    codes = db.query(Service.code).filter(
        Service.user_id == user_id,
        Service.code.like("S%")
    ).all()
    max_num = 0
    for (code_str,) in codes:
        if code_str and len(code_str) > 1:
            try:
                num = int(code_str[1:])
                if num > max_num:
                    max_num = num
            except ValueError:
                continue
    next_num = max_num + 1
    return f"S{next_num:03d}"

def create_service_service(db: Session, user_id: int, data: ServiceCreateRequest):
    code = generate_service_code(db, user_id)
    new_service = Service(
        user_id=user_id,
        code=code,
        name=data.name,
        category=data.category,
        selling_price=data.sellingPrice,
        gst_percent=data.gstPercent,
        status=data.status
    )
    db.add(new_service)
    db.commit()
    db.refresh(new_service)
    return new_service

def list_services_service(db: Session, user_id: int, query: str = None):
    q = db.query(Service).filter(Service.user_id == user_id)
    if query:
        search_filter = or_(
            Service.code.ilike(f"%{query}%"),
            Service.name.ilike(f"%{query}%"),
            Service.category.ilike(f"%{query}%")
        )
        q = q.filter(search_filter)
    return q.all()

def get_service_by_id_service(db: Session, user_id: int, service_id: int):
    return db.query(Service).filter(Service.id == service_id, Service.user_id == user_id).first()

def update_service_service(db: Session, user_id: int, service_id: int, data: ServiceUpdateRequest):
    service = db.query(Service).filter(Service.id == service_id, Service.user_id == user_id).first()
    if not service:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    mapping = {
        "sellingPrice": "selling_price",
        "gstPercent": "gst_percent"
    }
    
    for key, value in update_data.items():
        db_key = mapping.get(key, key)
        setattr(service, db_key, value)
        
    db.commit()
    db.refresh(service)
    return service

def delete_service_service(db: Session, user_id: int, service_id: int) -> bool:
    service = db.query(Service).filter(Service.id == service_id, Service.user_id == user_id).first()
    if not service:
        return False
    db.delete(service)
    db.commit()
    return True
