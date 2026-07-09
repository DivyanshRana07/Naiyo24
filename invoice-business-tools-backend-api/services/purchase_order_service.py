# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import PurchaseOrder, PurchaseOrderItem, Expense, Vendor
from schemas.purchase_order_schema import PurchaseOrderCreateRequest, PurchaseOrderUpdateRequest
from datetime import date
from services.activity_service import create_activity

def create_po_service(db: Session, data: PurchaseOrderCreateRequest):
    # Calculate sum total if items are provided, otherwise use flat total_amount
    total_val = data.total_amount
    if data.items:
        total_val = sum(item.line_total for item in data.items)

    # Create the PO header
    new_po = PurchaseOrder(
        user_id=data.user_id,
        vendor_id=data.vendor_id,
        po_number=data.po_number,
        po_date=data.po_date,
        expected_delivery_date=data.expected_delivery_date,
        status=data.status or "Draft",
        notes=data.notes,
        title=data.title,
        description=data.description,
        total_amount=total_val
    )
    db.add(new_po)
    db.flush()  # get the ID

    # Create the PO items (if provided)
    if data.items:
        for item in data.items:
            new_item = PurchaseOrderItem(
                po_id=new_po.id,
                name=item.name,
                quantity=item.quantity,
                price=item.price,
                gst_rate=item.gst_rate or 0.00,
                line_total=item.line_total
            )
            db.add(new_item)
    
    db.commit()
    db.refresh(new_po)
    
    # Add vendor_name to the response
    vendor = db.query(Vendor).filter(Vendor.id == new_po.vendor_id).first()
    if vendor:
        new_po.vendor_name = vendor.name
    else:
        new_po.vendor_name = "Unknown Vendor"

    po_user_id = new_po.user_id
    if po_user_id is not None:
        create_activity(
            db, po_user_id,
            action="Created",
            entity_type="Purchase Order",
            entity_id=new_po.po_number,
            title="Purchase Order Created",
            description=f"Purchase Order {new_po.po_number} was created successfully.",
        )
    return new_po

def list_pos_service(db: Session, user_id: int = None):
    query = db.query(PurchaseOrder)
    if user_id is not None:
        query = query.filter(PurchaseOrder.user_id == user_id)
    
    pos = query.all()
    
    # Add vendor_name to each PO
    for po in pos:
        vendor = db.query(Vendor).filter(Vendor.id == po.vendor_id).first()
        if vendor:
            po.vendor_name = vendor.name
        else:
            po.vendor_name = "Unknown Vendor"
    
    return pos

def get_po_by_id_service(db: Session, po_id: int):
    po = db.query(PurchaseOrder).filter(PurchaseOrder.id == po_id).first()
    if po:
        vendor = db.query(Vendor).filter(Vendor.id == po.vendor_id).first()
        if vendor:
            po.vendor_name = vendor.name
        else:
            po.vendor_name = "Unknown Vendor"
    return po

def update_po_service(db: Session, po_id: int, data: PurchaseOrderUpdateRequest):
    po = db.query(PurchaseOrder).filter(PurchaseOrder.id == po_id).first()
    if not po:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    items_data = update_data.pop("items", None)
    
    # Update PO header fields
    for key, value in update_data.items():
        setattr(po, key, value)
        
    # Update items if provided
    if items_data is not None:
        # Delete old items
        db.query(PurchaseOrderItem).filter(PurchaseOrderItem.po_id == po.id).delete()
        # Add new items
        for item in items_data:
            new_item = PurchaseOrderItem(
                po_id=po.id,
                name=item["name"],
                quantity=item["quantity"],
                price=item["price"],
                gst_rate=item.get("gst_rate", 0.00) or 0.00,
                line_total=item["line_total"]
            )
            db.add(new_item)
        # Recalculate total_amount from new items
        po.total_amount = sum(item["line_total"] for item in items_data)
            
    db.commit()
    db.refresh(po)
    
    # Add vendor_name to the response
    vendor = db.query(Vendor).filter(Vendor.id == po.vendor_id).first()
    if vendor:
        po.vendor_name = vendor.name
    else:
        po.vendor_name = "Unknown Vendor"

    po_user_id = po.user_id
    if po_user_id is not None:
        create_activity(
            db, po_user_id,
            action="Updated",
            entity_type="Purchase Order",
            entity_id=po.po_number,
            title="Purchase Order Updated",
            description=f"Purchase Order {po.po_number} was updated successfully.",
        )
    return po

def delete_po_service(db: Session, po_id: int) -> bool:
    po = db.query(PurchaseOrder).filter(PurchaseOrder.id == po_id).first()
    if not po:
        return False
        
    po_number = po.po_number
    po_user_id = po.user_id
    po_id_val = po.id
    db.delete(po)
    db.commit()

    if po_user_id is not None:
        create_activity(
            db, po_user_id,
            action="Deleted",
            entity_type="Purchase Order",
            entity_id=po_number,
            title="Purchase Order Deleted",
            description=f"Purchase Order {po_number} was deleted.",
        )
    return True

def convert_po_to_expense_service(db: Session, po_id: int):
    po = db.query(PurchaseOrder).filter(PurchaseOrder.id == po_id).first()
    if not po:
        return None
        
    # Check if an expense already exists for this PO
    existing_expense = db.query(Expense).filter(Expense.purchase_order_id == po.id).first()
    if existing_expense:
        return existing_expense
        
    # Calculate sum total
    if po.items:
        total_amount = sum(item.line_total for item in po.items)
    else:
        total_amount = po.total_amount or 0.0
    
    vendor_name = "Unknown Vendor"
    vendor = db.query(Vendor).filter(Vendor.id == po.vendor_id).first()
    if vendor:
        vendor_name = vendor.name
        
    # Create the expense record
    new_expense = Expense(
        user_id=po.user_id or 1,  # fallback to user 1 if user_id is null
        title=f"PO {po.po_number} - {vendor_name}",
        amount=total_amount,
        category="Purchase Order",
        expense_date=date.today(),
        vendor_id=po.vendor_id,
        purchase_order_id=po.id
    )
    
    # Update PO status to Billed/Received
    po.status = "Billed"
    
    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)
    return new_expense
