# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import Item
from schemas.item_schema import ItemCreateRequest, ItemUpdateRequest, ItemStockUpdateRequest
# pyrefly: ignore [missing-import]
from sqlalchemy import or_

def generate_item_code(db: Session, user_id: int) -> str:
    codes = db.query(Item.code).filter(
        Item.user_id == user_id,
        Item.code.like("P%")  # We will keep "P" as the prefix or use "I". Let's match whatever products had.
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
    return f"P{next_num:03d}"

def create_item_service(db: Session, user_id: int, data: ItemCreateRequest):
    code = generate_item_code(db, user_id)
    new_item = Item(
        user_id=user_id,
        code=code,
        name=data.name,
        category=data.category,
        unit=data.unit,
        purchase_price=data.purchasePrice,
        selling_price=data.sellingPrice,
        stock_qty=data.stockQty,
        gst_percent=data.gstPercent,
        status=data.status
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

def list_items_service(db: Session, user_id: int, query: str = None):
    q = db.query(Item).filter(Item.user_id == user_id)
    if query:
        search_filter = or_(
            Item.code.ilike(f"%{query}%"),
            Item.name.ilike(f"%{query}%"),
            Item.category.ilike(f"%{query}%")
        )
        q = q.filter(search_filter)
    return q.all()

def get_item_by_id_service(db: Session, user_id: int, item_id: int):
    return db.query(Item).filter(Item.id == item_id, Item.user_id == user_id).first()

def update_item_service(db: Session, user_id: int, item_id: int, data: ItemUpdateRequest):
    item = db.query(Item).filter(Item.id == item_id, Item.user_id == user_id).first()
    if not item:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    mapping = {
        "purchasePrice": "purchase_price",
        "sellingPrice": "selling_price",
        "stockQty": "stock_qty",
        "gstPercent": "gst_percent"
    }
    
    for key, value in update_data.items():
        db_key = mapping.get(key, key)
        setattr(item, db_key, value)
        
    db.commit()
    db.refresh(item)
    return item

def update_item_stock_service(db: Session, user_id: int, item_id: int, data: ItemStockUpdateRequest):
    # pyrefly: ignore [missing-import]
    from fastapi import HTTPException
    item = db.query(Item).filter(Item.id == item_id, Item.user_id == user_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
        
    if data.deduct is not None:
        if data.deduct < 0:
            raise HTTPException(status_code=400, detail="Deduct quantity must be non-negative")
        if item.stock_qty < data.deduct:
            raise HTTPException(status_code=400, detail="Insufficient stock")
        item.stock_qty -= data.deduct
        
    if data.restore is not None:
        if data.restore < 0:
            raise HTTPException(status_code=400, detail="Restore quantity must be non-negative")
        item.stock_qty += data.restore
        
    db.commit()
    db.refresh(item)
    return item

def delete_item_service(db: Session, user_id: int, item_id: int) -> bool:
    item = db.query(Item).filter(Item.id == item_id, Item.user_id == user_id).first()
    if not item:
        return False
    db.delete(item)
    db.commit()
    return True
