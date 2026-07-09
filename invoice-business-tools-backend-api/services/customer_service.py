from sqlalchemy.orm import Session
from models.db_models import Customer
from schemas.customer_schema import CustomerCreateRequest, CustomerUpdateRequest
from sqlalchemy import or_
from services.activity_service import create_activity

def generate_customer_code(db: Session, user_id: int) -> str:
    codes = db.query(Customer.code).filter(
        Customer.user_id == user_id,
        Customer.code.like("C%")
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
    return f"C{next_num:03d}"

def create_customer_service(db: Session, user_id: int, data: CustomerCreateRequest):
    code = generate_customer_code(db, user_id)
    new_customer = Customer(
        user_id=user_id,
        code=code,
        name=data.name,
        mobile=data.mobile,
        email=data.email,
        address=data.address,
        gst_number=data.gstNumber,
        opening_balance=data.openingBalance,
        credit_limit=data.creditLimit,
        status=data.status
    )
    db.add(new_customer)
    db.commit()
    db.refresh(new_customer)

    create_activity(
        db, user_id,
        action="Created",
        entity_type="Customer",
        entity_id=str(new_customer.id),
        title="Customer Added",
        description=f"Customer \"{new_customer.name}\" ({new_customer.code}) was added successfully.",
    )
    return new_customer

def list_customers_service(db: Session, user_id: int, query: str = None):
    q = db.query(Customer).filter(Customer.user_id == user_id)
    if query:
        search_filter = or_(
            Customer.code.ilike(f"%{query}%"),
            Customer.name.ilike(f"%{query}%"),
            Customer.mobile.ilike(f"%{query}%")
        )
        q = q.filter(search_filter)
    return q.all()

def get_customer_by_id_service(db: Session, user_id: int, customer_id: int):
    return db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()

def update_customer_service(db: Session, user_id: int, customer_id: int, data: CustomerUpdateRequest):
    customer = db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()
    if not customer:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    mapping = {
        "gstNumber": "gst_number",
        "openingBalance": "opening_balance",
        "creditLimit": "credit_limit"
    }
    
    for key, value in update_data.items():
        db_key = mapping.get(key, key)
        setattr(customer, db_key, value)
        
    db.commit()
    db.refresh(customer)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="Customer",
        entity_id=str(customer.id),
        title="Customer Updated",
        description=f"Customer \"{customer.name}\" was updated successfully.",
    )
    return customer

def delete_customer_service(db: Session, user_id: int, customer_id: int) -> bool:
    customer = db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()
    if not customer:
        return False
    customer_name = customer.name
    customer_id_val = customer.id
    db.delete(customer)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="Customer",
        entity_id=str(customer_id_val),
        title="Customer Deleted",
        description=f"Customer \"{customer_name}\" was deleted.",
    )
    return True
