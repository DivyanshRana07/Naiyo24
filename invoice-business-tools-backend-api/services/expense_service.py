# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import Expense, ExpenseItem, Vendor
from schemas.expense_schema import ExpenseCreateRequest, ExpenseUpdateRequest
from datetime import date
from services.activity_service import create_activity

def create_expense_service(db: Session, data: ExpenseCreateRequest):
    # Calculate sum total if items are provided, otherwise use flat total_amount
    total_val = data.total_amount
    if data.items:
        total_val = sum(item.line_total for item in data.items)

    # Create the Expense header
    new_expense = Expense(
        user_id=data.user_id,
        vendor_id=data.vendor_id,
        expense_number=data.expense_number,
        expense_date=data.expense_date,
        expected_delivery_date=data.expected_delivery_date,
        status=data.status or "Draft",
        notes=data.notes,
        title=data.title,
        description=data.description,
        total_amount=total_val,
        gst_amount=data.gst_amount or 0.00,
        receipt_image=data.receipt_image
    )
    db.add(new_expense)
    db.flush()  # get the ID

    # Create the Expense items (if provided)
    if data.items:
        for item in data.items:
            new_item = ExpenseItem(
                expense_id=new_expense.id,
                name=item.name,
                quantity=item.quantity,
                price=item.price,
                gst_rate=item.gst_rate or 0.00,
                line_total=item.line_total
            )
            db.add(new_item)
    
    db.commit()
    db.refresh(new_expense)
    
    # Add vendor_name to the response
    vendor = db.query(Vendor).filter(Vendor.id == new_expense.vendor_id).first()
    if vendor:
        new_expense.vendor_name = vendor.name
    else:
        new_expense.vendor_name = "Unknown Vendor"

    expense_user_id = new_expense.user_id
    if expense_user_id is not None:
        create_activity(
            db, expense_user_id,
            action="Created",
            entity_type="Expense",
            entity_id=new_expense.expense_number,
            title="Expense Created",
            description=f"Expense {new_expense.expense_number} was created successfully.",
        )
    return new_expense

def list_expenses_service(db: Session, user_id: int = None):
    query = db.query(Expense)
    if user_id is not None:
        query = query.filter(Expense.user_id == user_id)
    
    expenses = query.all()
    
    # Add vendor_name to each Expense
    for expense in expenses:
        vendor = db.query(Vendor).filter(Vendor.id == expense.vendor_id).first()
        if vendor:
            expense.vendor_name = vendor.name
        else:
            expense.vendor_name = "Unknown Vendor"
    
    return expenses

def get_expense_by_id_service(db: Session, expense_id: int):
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if expense:
        vendor = db.query(Vendor).filter(Vendor.id == expense.vendor_id).first()
        if vendor:
            expense.vendor_name = vendor.name
        else:
            expense.vendor_name = "Unknown Vendor"
    return expense

def update_expense_service(db: Session, expense_id: int, data: ExpenseUpdateRequest):
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    items_data = update_data.pop("items", None)
    
    # Update Expense header fields
    for key, value in update_data.items():
        setattr(expense, key, value)
        
    # Update items if provided
    if items_data is not None:
        # Delete old items
        db.query(ExpenseItem).filter(ExpenseItem.expense_id == expense.id).delete()
        # Add new items
        for item in items_data:
            new_item = ExpenseItem(
                expense_id=expense.id,
                name=item["name"],
                quantity=item["quantity"],
                price=item["price"],
                gst_rate=item.get("gst_rate", 0.00) or 0.00,
                line_total=item["line_total"]
            )
            db.add(new_item)
        # Recalculate total_amount from new items
        expense.total_amount = sum(item["line_total"] for item in items_data)
            
    db.commit()
    db.refresh(expense)
    
    # Add vendor_name to the response
    vendor = db.query(Vendor).filter(Vendor.id == expense.vendor_id).first()
    if vendor:
        expense.vendor_name = vendor.name
    else:
        expense.vendor_name = "Unknown Vendor"

    expense_user_id = expense.user_id
    if expense_user_id is not None:
        create_activity(
            db, expense_user_id,
            action="Updated",
            entity_type="Expense",
            entity_id=expense.expense_number,
            title="Expense Updated",
            description=f"Expense {expense.expense_number} was updated successfully.",
        )
    return expense

def delete_expense_service(db: Session, expense_id: int) -> bool:
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        return False
        
    expense_number = expense.expense_number
    expense_user_id = expense.user_id
    expense_id_val = expense.id
    db.delete(expense)
    db.commit()

    if expense_user_id is not None:
        create_activity(
            db, expense_user_id,
            action="Deleted",
            entity_type="Expense",
            entity_id=expense_number,
            title="Expense Deleted",
            description=f"Expense {expense_number} was deleted.",
        )
    return True

