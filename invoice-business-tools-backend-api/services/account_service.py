import uuid
from datetime import datetime
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from models.db_models import Account, AccountGroup
from schemas.account_schema import (
    AccountGroupCreateRequest,
    AccountGroupUpdateRequest,
    AccountCreateRequest,
    AccountUpdateRequest,
)
from services.activity_service import create_activity


def seed_default_groups_if_needed(db: Session, user_id: int):
    # Check if this user already has any account groups
    existing_count = db.query(AccountGroup).filter(AccountGroup.user_id == user_id).count()
    if existing_count > 0:
        return

    # Seed the 13 system default groups
    defaults = [
        {"id": "ag-seed-001", "name": "Capital Accounts", "type": "Capital", "category": "Capital Accounts"},
        {"id": "ag-seed-002", "name": "Equities", "type": "Capital", "category": "Equities"},
        {"id": "ag-seed-003", "name": "Financial Expenses", "type": "Expense", "category": "Financial Expenses"},
        {"id": "ag-seed-004", "name": "Indirect Expenses", "type": "Expense", "category": "Indirect Expenses"},
        {"id": "ag-seed-005", "name": "Administrative Expenses", "type": "Expense", "category": "Administrative Expenses"},
        {"id": "ag-seed-006", "name": "Cost Of Goods Sold", "type": "Expense", "category": "Cost Of Goods Sold"},
        {"id": "ag-seed-007", "name": "Purchase Accounts", "type": "Expense", "category": "Purchase Accounts"},
        {"id": "ag-seed-008", "name": "Duties and Taxes", "type": "Liability", "category": "Duties and Taxes"},
        {"id": "ag-seed-009", "name": "Bank Accounts", "type": "Asset", "category": "Bank Accounts"},
        {"id": "ag-seed-010", "name": "Cash Accounts", "type": "Asset", "category": "Cash Accounts"},
        {"id": "ag-seed-011", "name": "Accounts Receivable", "type": "Asset", "category": "Accounts Receivable"},
        {"id": "ag-seed-012", "name": "Interest Incomes", "type": "Income", "category": "Interest Incomes"},
        {"id": "ag-seed-013", "name": "Sales / Revenue", "type": "Income", "category": "Sales / Revenue"},
    ]

    for item in defaults:
        group = AccountGroup(
            user_id=user_id,
            group_id_str=item["id"],
            name=item["name"],
            type=item["type"],
            category=item["category"],
            is_system=True,
        )
        db.add(group)
    db.commit()


def list_account_groups_service(db: Session, user_id: int):
    seed_default_groups_if_needed(db, user_id)
    return db.query(AccountGroup).filter(AccountGroup.user_id == user_id).all()


def get_account_group_by_id_service(db: Session, user_id: int, group_id: str):
    seed_default_groups_if_needed(db, user_id)
    return db.query(AccountGroup).filter(
        AccountGroup.user_id == user_id,
        AccountGroup.group_id_str == group_id
    ).first()


def create_account_group_service(db: Session, user_id: int, data: AccountGroupCreateRequest):
    seed_default_groups_if_needed(db, user_id)
    group_id = f"ag-{uuid.uuid4().hex[:10].lower()}"
    new_group = AccountGroup(
        user_id=user_id,
        group_id_str=group_id,
        name=data.name,
        type=data.type,
        parent_group_id=data.parentGroupId,
        category=data.category,
        description=data.description,
        is_system=data.isSystem,
    )
    db.add(new_group)
    db.commit()
    db.refresh(new_group)

    create_activity(
        db, user_id,
        action="Created",
        entity_type="AccountGroup",
        entity_id=new_group.group_id_str,
        title="Account Group Added",
        description=f"Account group \"{new_group.name}\" was created successfully.",
    )
    return new_group


def update_account_group_service(db: Session, user_id: int, group_id: str, data: AccountGroupUpdateRequest):
    seed_default_groups_if_needed(db, user_id)
    group = db.query(AccountGroup).filter(
        AccountGroup.user_id == user_id,
        AccountGroup.group_id_str == group_id
    ).first()
    if not group:
        return None

    update_data = data.model_dump(exclude_unset=True)
    mapping = {
        "parentGroupId": "parent_group_id",
        "isSystem": "is_system",
    }

    for key, value in update_data.items():
        db_key = mapping.get(key, key)
        setattr(group, db_key, value)

    db.commit()
    db.refresh(group)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="AccountGroup",
        entity_id=group.group_id_str,
        title="Account Group Updated",
        description=f"Account group \"{group.name}\" was updated successfully.",
    )
    return group


def delete_account_group_service(db: Session, user_id: int, group_id: str) -> bool:
    seed_default_groups_if_needed(db, user_id)
    group = db.query(AccountGroup).filter(
        AccountGroup.user_id == user_id,
        AccountGroup.group_id_str == group_id
    ).first()
    if not group:
        return False
    if group.is_system:
        # Cannot delete system groups
        return False

    group_name = group.name
    db.delete(group)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="AccountGroup",
        entity_id=group_id,
        title="Account Group Deleted",
        description=f"Account group \"{group_name}\" was deleted.",
    )
    return True


def list_accounts_service(db: Session, user_id: int):
    seed_default_groups_if_needed(db, user_id)
    return db.query(Account).filter(Account.user_id == user_id).all()


def get_account_by_id_service(db: Session, user_id: int, account_id: str):
    seed_default_groups_if_needed(db, user_id)
    return db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_id_str == account_id
    ).first()


def create_account_service(db: Session, user_id: int, data: AccountCreateRequest):
    seed_default_groups_if_needed(db, user_id)
    acc_id = f"acc-{uuid.uuid4().hex[:10].lower()}"
    new_account = Account(
        user_id=user_id,
        account_id_str=acc_id,
        name=data.name,
        code=data.code,
        account_group_id=data.accountGroupId,
        type=data.type,
        opening_balance=data.openingBalance,
        current_balance=data.currentBalance,
        is_active=data.isActive,
        currency=data.currency,
    )
    db.add(new_account)
    db.commit()
    db.refresh(new_account)

    create_activity(
        db, user_id,
        action="Created",
        entity_type="Account",
        entity_id=new_account.account_id_str,
        title="Account Added",
        description=f"Account \"{new_account.name}\" ({new_account.code}) was added successfully.",
    )
    return new_account


def update_account_service(db: Session, user_id: int, account_id: str, data: AccountUpdateRequest):
    seed_default_groups_if_needed(db, user_id)
    account = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_id_str == account_id
    ).first()
    if not account:
        return None

    update_data = data.model_dump(exclude_unset=True)
    mapping = {
        "accountGroupId": "account_group_id",
        "openingBalance": "opening_balance",
        "currentBalance": "current_balance",
        "isActive": "is_active",
    }

    for key, value in update_data.items():
        db_key = mapping.get(key, key)
        setattr(account, db_key, value)

    db.commit()
    db.refresh(account)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="Account",
        entity_id=account.account_id_str,
        title="Account Updated",
        description=f"Account \"{account.name}\" was updated successfully.",
    )
    return account


def delete_account_service(db: Session, user_id: int, account_id: str) -> bool:
    seed_default_groups_if_needed(db, user_id)
    account = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_id_str == account_id
    ).first()
    if not account:
        return False

    account_name = account.name
    db.delete(account)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="Account",
        entity_id=account_id,
        title="Account Deleted",
        description=f"Account \"{account_name}\" was deleted.",
    )
    return True
