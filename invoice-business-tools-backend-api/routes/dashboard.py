print("Dashboard router loaded")
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date

from db import get_db
from models.db_models import (
    Invoice,
    InvoiceItem,
    Expense,
    Quotation,
    Salary,
    Customer,
    Lead,
)

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)


@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db)
):

    total_invoices = db.query(Invoice).count()

    invoice_amount = (
        db.query(func.sum(InvoiceItem.line_total))
        .scalar()
    ) or 0
    
    # Count pending invoices (status = due or partial)
    pending_invoices = db.query(Invoice).filter(
        Invoice.status.in_(['due', 'partial'])
    ).count()
    
    # Calculate overdue amount (status = due and due_date < today)
    overdue_invoices = db.query(Invoice).filter(
        Invoice.status == 'due',
        Invoice.due_date < date.today()
    ).all()
    
    overdue_amount = sum(
        float(item.line_total) 
        for invoice in overdue_invoices 
        for item in invoice.items
    )

    total_expenses = db.query(Expense).count()

    expense_amount = (
        db.query(func.sum(Expense.amount))
        .scalar()
    ) or 0

    total_quotations = db.query(Quotation).count()

    quotation_amount = (
        db.query(func.sum(Quotation.total))
        .scalar()
    ) or 0

    total_salaries = db.query(Salary).count()

    salary_amount = (
        db.query(func.sum(Salary.total_salary))
        .scalar()
    ) or 0
    
    # Customer metrics
    active_customers = db.query(Customer).filter(Customer.status == 'active').count()
    
    # Lead metrics
    total_leads = db.query(Lead).count()
    new_leads = db.query(Lead).filter(Lead.status == 'new').count()

    return {
        "total_invoices": total_invoices,
        "invoice_amount": float(invoice_amount),
        "pending_invoices": pending_invoices,
        "overdue_amount": overdue_amount,
        "overdue_count": len(overdue_invoices),

        "total_expenses": total_expenses,
        "expense_amount": float(expense_amount),

        "total_quotations": total_quotations,
        "quotation_amount": float(quotation_amount),

        "total_salaries": total_salaries,
        "salary_amount": float(salary_amount),
        
        "active_customers": active_customers,
        "total_leads": total_leads,
        "new_leads": new_leads
    }
