from sqlalchemy.orm import Session
from models.db_models import Expense
from services.activity_service import create_activity

def add_expense_service(db: Session, user_id: int, data):
    new_expense = Expense(
        user_id=user_id,
        title=data.title,
        amount=data.amount,
        category=data.category,
        expense_date=data.expense_date,
        vendor_id=data.vendor_id if hasattr(data, "vendor_id") else None,
        purchase_order_id=data.purchase_order_id if hasattr(data, "purchase_order_id") else None
    )
    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)

    create_activity(
        db, user_id,
        action="Created",
        entity_type="Expense",
        entity_id=str(new_expense.id),
        title="Expense Added",
        description=f"Expense \"{new_expense.title}\" of ₹{new_expense.amount} was added successfully.",
    )
    return new_expense

def list_expenses_service(db: Session, user_id: int):
    return db.query(Expense).filter(Expense.user_id == user_id).all()

def get_expense_by_id_service(db: Session, user_id: int, expense_id: int):
    return db.query(Expense).filter(Expense.id == expense_id, Expense.user_id == user_id).first()

def update_expense_service(db: Session, user_id: int, expense_id: int, data):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.user_id == user_id).first()
    if not expense:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(expense, key, value)
        
    db.commit()
    db.refresh(expense)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="Expense",
        entity_id=str(expense.id),
        title="Expense Updated",
        description=f"Expense \"{expense.title}\" was updated successfully.",
    )
    return expense

def delete_expense_service(db: Session, user_id: int, expense_id: int):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.user_id == user_id).first()
    if not expense:
        return False

    expense_title = expense.title
    expense_id_val = expense.id
    db.delete(expense)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="Expense",
        entity_id=str(expense_id_val),
        title="Expense Deleted",
        description=f"Expense \"{expense_title}\" was deleted.",
    )
    return True