from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from schemas.salary_schema import SalaryGenerateRequest, SalaryUpdateRequest, SalaryResponse
from services.salary_service import (
    generate_salary_service,
    list_salary_service,
    get_salary_by_id_service,
    update_salary_service,
    delete_salary_service
)
from db import get_db
from models.db_models import User
from core.dependencies import get_current_user

router = APIRouter(
    prefix="/salary",
    tags=["Salary"]
)


@router.post("/generate", response_model=dict)
def generate_salary(payload: SalaryGenerateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    try:
        result = generate_salary_service(db, current_user.id, payload)
        return {
            "success": True,
            "message": "Salary generated successfully",
            "data": SalaryResponse.model_validate(result)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate salary: {str(e)}")


@router.get("/list", response_model=dict)
def list_salaries(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    try:
        result = list_salary_service(db, current_user.id)
        return {
            "success": True,
            "message": "Salary list fetched successfully",
            "data": [SalaryResponse.model_validate(s) for s in result]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch salary records: {str(e)}")


@router.get("/{id}", response_model=dict)
def get_salary(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = get_salary_by_id_service(db, current_user.id, id)
    if not result:
        raise HTTPException(status_code=404, detail="Salary not found")
    return {
        "success": True,
        "message": "Salary fetched successfully",
        "data": SalaryResponse.model_validate(result)
    }


@router.put("/{id}", response_model=dict)
def update_salary(id: int, payload: SalaryUpdateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = update_salary_service(db, current_user.id, id, payload)
    if not result:
        raise HTTPException(status_code=404, detail="Salary not found")
    return {
        "success": True,
        "message": "Salary updated successfully",
        "data": SalaryResponse.model_validate(result)
    }


@router.delete("/{id}", response_model=dict)
def delete_salary(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    success = delete_salary_service(db, current_user.id, id)
    if not success:
        raise HTTPException(status_code=404, detail="Salary not found")
    return {
        "success": True,
        "message": "Salary deleted successfully"
    }