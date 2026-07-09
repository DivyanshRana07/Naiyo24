# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import Quotation, QuotationItem
from services.activity_service import create_activity


def create_quotation_service(db: Session, user_id: int, data):
    total_amount = 0
    for item in data.items:
        subtotal = item.price * item.quantity
        discount = subtotal * (item.discountPercent / 100.0)
        taxable = subtotal - discount
        gst = taxable * (item.gstPercent / 100.0)
        total_amount += (taxable + gst)

    new_quotation = Quotation(
        user_id=user_id,

        customer_id=data.customer_id,
        customer_name=data.customer_name,
        customer_mobile=data.customer_mobile,
        customer_address=data.customer_address,
        customer_gst=data.customer_gst,

        quotation_date=data.quotation_date,
        valid_until=data.valid_until,
        payment_terms=data.payment_terms,
        currency=data.currency,
        
        subtitle=data.subtitle,
        logo=data.logo,
        settings=data.settings,

        total=total_amount,
        status=data.status
    )

    db.add(new_quotation)
    db.flush()

    for item in data.items:
        db_item = QuotationItem(
            quotation_id=new_quotation.id,
            name=item.name,
            price=item.price,
            quantity=item.quantity,
            discount_percent=item.discountPercent,
            gst_percent=item.gstPercent
        )
        db.add(db_item)


    db.commit()
    db.refresh(new_quotation)

    create_activity(
        db, user_id,
        action="Created",
        entity_type="Quotation",
        entity_id=str(new_quotation.id),
        title="Quotation Created",
        description=f"Quotation for \"{new_quotation.customer_name}\" worth ₹{new_quotation.total} was created successfully.",
    )

    return new_quotation


def list_quotation_service(db: Session, user_id: int):
    return db.query(Quotation).filter(
        Quotation.user_id == user_id
    ).all()


def get_quotation_by_id_service(db: Session, user_id: int, quotation_id: int):
    return db.query(Quotation).filter(
        Quotation.id == quotation_id,
        Quotation.user_id == user_id
    ).first()


def update_quotation_service(db: Session, user_id: int, quotation_id: int, data):
    quotation = db.query(Quotation).filter(
        Quotation.id == quotation_id,
        Quotation.user_id == user_id
    ).first()

    if not quotation:
        return None

    update_data = data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(quotation, key, value)

    db.commit()
    db.refresh(quotation)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="Quotation",
        entity_id=str(quotation.id),
        title="Quotation Updated",
        description=f"Quotation for \"{quotation.customer_name}\" was updated successfully.",
    )

    return quotation


def delete_quotation_service(db: Session, user_id: int, quotation_id: int):
    quotation = db.query(Quotation).filter(
        Quotation.id == quotation_id,
        Quotation.user_id == user_id
    ).first()

    if not quotation:
        return False

    customer_name = quotation.customer_name
    q_id = quotation.id
    db.delete(quotation)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="Quotation",
        entity_id=str(q_id),
        title="Quotation Deleted",
        description=f"Quotation for \"{customer_name}\" was deleted.",
    )

    return True