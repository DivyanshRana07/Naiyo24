# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from db import get_db
from models.db_models import User
from core.dependencies import get_current_user
from schemas.account_schema import (
    AccountGroupCreateRequest,
    AccountGroupUpdateRequest,
    AccountGroupResponse,
    AccountCreateRequest,
    AccountUpdateRequest,
    AccountResponse,
)
from services.account_service import (
    list_account_groups_service,
    get_account_group_by_id_service,
    create_account_group_service,
    update_account_group_service,
    delete_account_group_service,
    list_accounts_service,
    get_account_by_id_service,
    create_account_service,
    update_account_service,
    delete_account_service,
)

# Router for Account Groups
groups_router = APIRouter(prefix="/account-groups", tags=["Account Groups"])

# Router for Accounts
accounts_router = APIRouter(prefix="/accounts", tags=["Accounts"])


# --- Account Groups Endpoints ---

@groups_router.post("", response_model=dict)
def create_account_group(
    payload: AccountGroupCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = create_account_group_service(db, current_user.id, payload)
        return {
            "success": True,
            "message": "Account group created successfully",
            "data": AccountGroupResponse.model_validate(result).model_dump(by_alias=True)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create account group: {str(e)}"
        )


@groups_router.get("", response_model=dict)
def list_account_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = list_account_groups_service(db, current_user.id)
        return {
            "success": True,
            "data": [
                AccountGroupResponse.model_validate(g).model_dump(by_alias=True)
                for g in result
            ]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch account groups: {str(e)}"
        )


@groups_router.get("/{id}", response_model=dict)
def get_account_group(
    id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = get_account_group_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Account group not found")
    return {
        "success": True,
        "data": AccountGroupResponse.model_validate(result).model_dump(by_alias=True)
    }


@groups_router.put("/{id}", response_model=dict)
def update_account_group(
    id: str,
    payload: AccountGroupUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = update_account_group_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Account group not found or cannot be updated")
    return {
        "success": True,
        "message": "Account group updated successfully",
        "data": AccountGroupResponse.model_validate(result).model_dump(by_alias=True)
    }


@groups_router.delete("/{id}", response_model=dict)
def delete_account_group(
    id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_account_group_service(db, current_user.id, id)
    if not success:
        raise HTTPException(
            status_code=400,
            detail="Account group not found or is a protected system group"
        )
    return {
        "success": True,
        "message": "Account group deleted successfully"
    }


# --- Accounts Endpoints ---

@accounts_router.post("", response_model=dict)
def create_account(
    payload: AccountCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = create_account_service(db, current_user.id, payload)
        return {
            "success": True,
            "message": "Account created successfully",
            "data": AccountResponse.model_validate(result).model_dump(by_alias=True)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create account: {str(e)}"
        )


@accounts_router.get("", response_model=dict)
def list_accounts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        result = list_accounts_service(db, current_user.id)
        return {
            "success": True,
            "data": [
                AccountResponse.model_validate(a).model_dump(by_alias=True)
                for a in result
            ]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch accounts: {str(e)}"
        )


@accounts_router.get("/{id}", response_model=dict)
def get_account(
    id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = get_account_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Account not found")
    return {
        "success": True,
        "data": AccountResponse.model_validate(result).model_dump(by_alias=True)
    }


@accounts_router.put("/{id}", response_model=dict)
def update_account(
    id: str,
    payload: AccountUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = update_account_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Account not found")
    return {
        "success": True,
        "message": "Account updated successfully",
        "data": AccountResponse.model_validate(result).model_dump(by_alias=True)
    }


@accounts_router.delete("/{id}", response_model=dict)
def delete_account(
    id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_account_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Account not found")
    return {
        "success": True,
        "message": "Account deleted successfully"
    }
