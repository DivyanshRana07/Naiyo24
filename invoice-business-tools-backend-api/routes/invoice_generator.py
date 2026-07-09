import io
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from db import get_db
from models.invoice_generator import InvoiceCreateRequest
from models.db_models import User
from core.dependencies import get_current_user
from schemas.invoice_schema import (
    InvoiceUpdateRequest,
    InvoiceResponse
)
from services.invoice_service import (
    list_invoices_service,
    get_invoice_by_id_service,
    update_invoice_service,
    delete_invoice_service
)
from services.gst_invoice_generator.gst_invoice_service import GSTInvoiceService
from services.gst_invoice_generator.pdf_service import InvoicePDFService
from models.invoice_generator import (
    InvoiceComputedData,
    TaxBreakdown,
    InvoiceItemComputed,
    PartyDetails
)

router = APIRouter(prefix="/invoices", tags=["Invoices"])


@router.post("", response_model=dict)
@router.post("/create", response_model=dict)
def create_invoice(
    payload: InvoiceCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # compute the GST invoice details
        computed_data = GSTInvoiceService.compute_invoice(payload)
        # save the computed details to the database, associated with current_user.id
        db_invoice = GSTInvoiceService.save_invoice_to_db(db, current_user.id, computed_data)
        
        return {
            "success": True,
            "message": "Invoice created successfully",
            "data": InvoiceResponse.model_validate(db_invoice)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create invoice: {str(e)}"
        )


@router.get("", response_model=dict)
@router.get("/list", response_model=dict)
def list_invoices(

    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    invoices = list_invoices_service(db, current_user.id)
    return {
        "success": True,
        "data": [InvoiceResponse.model_validate(inv) for inv in invoices]
    }


@router.get("/{id}", response_model=dict)
def get_invoice(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    invoice = get_invoice_by_id_service(db, current_user.id, id)
    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    return {
        "success": True,
        "data": InvoiceResponse.model_validate(invoice)
    }


@router.put("/{id}", response_model=dict)
def update_invoice(
    id: int,
    payload: InvoiceUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    invoice = update_invoice_service(db, current_user.id, id, payload)
    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    return {
        "success": True,
        "message": "Invoice updated successfully",
        "data": InvoiceResponse.model_validate(invoice)
    }


@router.delete("/{id}", response_model=dict)
def delete_invoice(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_invoice_service(db, current_user.id, id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    return {
        "success": True,
        "message": "Invoice deleted successfully"
    }


@router.get("/{id}/download-pdf")
def download_invoice_pdf(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_invoice = get_invoice_by_id_service(db, current_user.id, id)
    if not db_invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    
    try:
        business = PartyDetails(**db_invoice.business_details)
        customer = PartyDetails(**db_invoice.customer_details)
        totals = TaxBreakdown(**db_invoice.tax_breakdown)
        
        computed_items = []
        for item in db_invoice.items:
            computed_items.append(
                InvoiceItemComputed(
                    name=item.name,
                    quantity=item.quantity,
                    price=item.price,
                    gst_rate=item.gst_rate,
                    taxable_amount=item.taxable_amount,
                    cgst_rate=item.cgst_rate,
                    cgst_amount=item.cgst_amount,
                    sgst_rate=item.sgst_rate,
                    sgst_amount=item.sgst_amount,
                    igst_rate=item.igst_rate,
                    igst_amount=item.igst_amount,
                    line_total=item.line_total
                )
            )
        
        computed_data = InvoiceComputedData(
            invoice_number=db_invoice.invoice_number,
            invoice_date=db_invoice.invoice_date,
            due_date=db_invoice.due_date,
            transaction_type=db_invoice.transaction_type,
            invoice_type=db_invoice.invoice_type,
            business=business,
            customer=customer,
            items=computed_items,
            totals=totals,
            notes=db_invoice.notes
        )
        
        pdf_bytes = InvoicePDFService.render_invoice_pdf(computed_data)
        
        pdf_stream = io.BytesIO(pdf_bytes)
        filename = f"Invoice-{db_invoice.invoice_number}.pdf"
        
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate PDF: {str(e)}"
        )