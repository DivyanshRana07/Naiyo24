# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import Invoice
from services.activity_service import create_activity

def list_invoices_service(db: Session, user_id: int):
    return db.query(Invoice).filter(Invoice.user_id == user_id).all()

def get_invoice_by_id_service(db: Session, user_id: int, invoice_id: int):
    return db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()

def update_invoice_service(db: Session, user_id: int, invoice_id: int, data):
    db_invoice = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()
    if not db_invoice:
        return None

    if data.due_date is not None:
        db_invoice.due_date = data.due_date
    if data.notes is not None:
        db_invoice.notes = data.notes
    if data.customer is not None:
        db_invoice.customer_details = data.customer.model_dump()
    if data.paymentMethod is not None:
        db_invoice.payment_method = data.paymentMethod
    if data.paidAmount is not None:
        db_invoice.paid_amount = data.paidAmount
    if data.roundOff is not None:
        db_invoice.round_off = data.roundOff
    if data.status is not None:
        db_invoice.status = data.status


    db.commit()
    db.refresh(db_invoice)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="Invoice",
        entity_id=db_invoice.invoice_number,
        title="Invoice Updated",
        description=f"Invoice {db_invoice.invoice_number} was updated successfully.",
    )
    return db_invoice

def delete_invoice_service(db: Session, user_id: int, invoice_id: int) -> bool:
    db_invoice = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()
    if not db_invoice:
        return False

    invoice_number = db_invoice.invoice_number
    db.delete(db_invoice)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="Invoice",
        entity_id=invoice_number,
        title="Invoice Deleted",
        description=f"Invoice {invoice_number} was deleted.",
    )
    return True