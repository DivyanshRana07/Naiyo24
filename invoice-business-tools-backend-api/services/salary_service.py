from sqlalchemy.orm import Session
from models.db_models import Salary
from services.activity_service import create_activity

def generate_salary_service(db: Session, user_id: int, data):
    total_salary = data.base_salary + data.bonus
    new_salary = Salary(
        user_id=user_id,
        employee_name=data.employee_name,
        base_salary=data.base_salary,
        bonus=data.bonus,
        total_salary=total_salary
    )
    db.add(new_salary)
    db.commit()
    db.refresh(new_salary)

    create_activity(
        db, user_id,
        action="Generated",
        entity_type="Salary",
        entity_id=str(new_salary.id),
        title="Salary Generated",
        description=f"Salary slip generated for {new_salary.employee_name} — ₹{new_salary.total_salary}.",
    )
    return new_salary

def list_salary_service(db: Session, user_id: int):
    return db.query(Salary).filter(Salary.user_id == user_id).all()

def get_salary_by_id_service(db: Session, user_id: int, salary_id: int):
    return db.query(Salary).filter(Salary.id == salary_id, Salary.user_id == user_id).first()

def update_salary_service(db: Session, user_id: int, salary_id: int, data):
    salary = db.query(Salary).filter(Salary.id == salary_id, Salary.user_id == user_id).first()
    if not salary:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(salary, key, value)
        
    # Recalculate total
    salary.total_salary = float(salary.base_salary) + float(salary.bonus)
    
    db.commit()
    db.refresh(salary)

    create_activity(
        db, user_id,
        action="Updated",
        entity_type="Salary",
        entity_id=str(salary.id),
        title="Salary Updated",
        description=f"Salary record for {salary.employee_name} was updated — ₹{salary.total_salary}.",
    )
    return salary

def delete_salary_service(db: Session, user_id: int, salary_id: int):
    salary = db.query(Salary).filter(Salary.id == salary_id, Salary.user_id == user_id).first()
    if not salary:
        return False

    employee_name = salary.employee_name
    salary_id_val = salary.id
    db.delete(salary)
    db.commit()

    create_activity(
        db, user_id,
        action="Deleted",
        entity_type="Salary",
        entity_id=str(salary_id_val),
        title="Salary Deleted",
        description=f"Salary record for {employee_name} was deleted.",
    )
    return True