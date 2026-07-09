from __future__ import annotations

from decimal import Decimal
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session

from models.db_models import Invoice, InvoiceItem
from models.invoice_generator import (
    InvoiceComputedData,
    InvoiceCreateRequest,
    InvoiceItemComputed,
    TaxBreakdown,
    round_money,
)
from services.activity_service import create_activity


class GSTInvoiceService:
    @staticmethod
    def compute_invoice(payload: InvoiceCreateRequest) -> InvoiceComputedData:
        # Safely extract and fallback state_code to avoid crashes on flat addresses
        b_code = payload.business.state_code
        c_code = payload.customer.state_code
        if not b_code or not c_code:
            is_intra_state = True
        else:
            is_intra_state = b_code == c_code

        computed_items: list[InvoiceItemComputed] = []
        total_taxable = Decimal("0")
        total_cgst = Decimal("0")
        total_sgst = Decimal("0")
        total_igst = Decimal("0")

        for item in payload.items:
            taxable_amount = round_money(item.quantity * item.price)

            if is_intra_state:
                half_rate = item.gst_rate / Decimal("2")
                cgst_rate = round_money(half_rate)
                sgst_rate = round_money(half_rate)
                igst_rate = Decimal("0")

                cgst_amount = round_money(taxable_amount * (cgst_rate / Decimal("100")))
                sgst_amount = round_money(taxable_amount * (sgst_rate / Decimal("100")))
                igst_amount = Decimal("0")
            else:
                cgst_rate = Decimal("0")
                sgst_rate = Decimal("0")
                igst_rate = round_money(item.gst_rate)

                cgst_amount = Decimal("0")
                sgst_amount = Decimal("0")
                igst_amount = round_money(taxable_amount * (igst_rate / Decimal("100")))

            line_total = round_money(taxable_amount + cgst_amount + sgst_amount + igst_amount)

            total_taxable += taxable_amount
            total_cgst += cgst_amount
            total_sgst += sgst_amount
            total_igst += igst_amount

            computed_items.append(
                InvoiceItemComputed(
                    name=item.name,
                    quantity=round_money(item.quantity),
                    price=round_money(item.price),
                    gst_rate=round_money(item.gst_rate),
                    taxable_amount=taxable_amount,
                    cgst_rate=cgst_rate,
                    cgst_amount=cgst_amount,
                    sgst_rate=sgst_rate,
                    sgst_amount=sgst_amount,
                    igst_rate=igst_rate,
                    igst_amount=igst_amount,
                    line_total=line_total,
                )
            )

        total_taxable = round_money(total_taxable)
        total_cgst = round_money(total_cgst)
        total_sgst = round_money(total_sgst)
        total_igst = round_money(total_igst)
        total_tax = round_money(total_cgst + total_sgst + total_igst)
        grand_total = round_money(total_taxable + total_tax)

        totals = TaxBreakdown(
            total_taxable_amount=total_taxable,
            total_cgst=total_cgst,
            total_sgst=total_sgst,
            total_igst=total_igst,
            total_tax=total_tax,
            grand_total=grand_total,
        )

        return InvoiceComputedData(
            invoice_number=payload.resolved_invoice_number(),
            invoice_date=payload.invoice_date,
            due_date=payload.due_date,
            transaction_type="intra_state" if is_intra_state else "inter_state",
            invoice_type=payload.invoice_type,
            business=payload.business,
            customer=payload.customer,
            items=computed_items,
            totals=totals,
            notes=payload.notes,
            subtitle=payload.subtitle,
            logo=payload.logo,
            settings=payload.settings,
            payment_method=payload.paymentMethod,
            paid_amount=payload.paidAmount,
            round_off=payload.roundOff,
            status=payload.status,
        )

    @staticmethod
    def save_invoice_to_db(db: Session, user_id: int, computed_data: InvoiceComputedData) -> Invoice:
        db_invoice = Invoice(
            user_id=user_id,
            invoice_number=computed_data.invoice_number,
            invoice_date=computed_data.invoice_date,
            due_date=computed_data.due_date,
            transaction_type=computed_data.transaction_type,
            invoice_type=computed_data.invoice_type,
            business_details=computed_data.business.model_dump(mode="json"),
            customer_details=computed_data.customer.model_dump(mode="json"),
            tax_breakdown=computed_data.totals.model_dump(mode="json"),
            notes=computed_data.notes,
            subtitle=computed_data.subtitle,
            logo=computed_data.logo,
            settings=computed_data.settings,
            payment_method=computed_data.payment_method,
            paid_amount=computed_data.paid_amount,
            round_off=computed_data.round_off,
            status=computed_data.status,
        )
        
        db.add(db_invoice)
        db.flush() # flush to get db_invoice.id if needed
        
        for item in computed_data.items:
            db_item = InvoiceItem(
                invoice_id=db_invoice.id,
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
            db.add(db_item)
            
        db.commit()
        db.refresh(db_invoice)

        create_activity(
            db, user_id,
            action="Created",
            entity_type="Invoice",
            entity_id=db_invoice.invoice_number,
            title="Invoice Created",
            description=f"Invoice {db_invoice.invoice_number} was created successfully.",
        )

        return db_invoice


