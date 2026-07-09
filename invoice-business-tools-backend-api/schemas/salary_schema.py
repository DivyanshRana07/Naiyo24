from pydantic import BaseModel, ConfigDict
from typing import Optional

class SalaryGenerateRequest(BaseModel):
    employee_name: str
    base_salary: float
    bonus: float

class SalaryUpdateRequest(BaseModel):
    employee_name: Optional[str] = None
    base_salary: Optional[float] = None
    bonus: Optional[float] = None

class SalaryResponse(BaseModel):
    id: int
    employee_name: str
    base_salary: float
    bonus: float
    total_salary: float
    
    model_config = ConfigDict(from_attributes=True)