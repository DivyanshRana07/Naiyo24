from __future__ import annotations

import io
import base64
from datetime import date
from decimal import Decimal
from fpdf import FPDF
from models.invoice_generator import InvoiceComputedData, PartyDetails, InvoiceItemComputed, TaxBreakdown, round_money


class InvoiceFPDF(FPDF):
    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, "This is an electronically generated document, no signature is required.", align="C")


class InvoicePDFService:
    @staticmethod
    def render_invoice_pdf(invoice: InvoiceComputedData) -> bytes:
        title = "PROFORMA INVOICE" if invoice.invoice_type == "proforma" else "TAX INVOICE"
        return InvoicePDFService._render_pdf_internal(invoice, title_override=title)

    @staticmethod
    def render_quotation_pdf(quotation, business_details: dict | None) -> bytes:
        # Map business details
        if business_details:
            b_details = PartyDetails(
                name=business_details.get("name", "Naiyo24 Business"),
                address=business_details.get("address"),
                address_line_1=business_details.get("address_line_1") or business_details.get("address"),
                address_line_2=business_details.get("address_line_2"),
                city=business_details.get("city"),
                state_name=business_details.get("state_name"),
                state_code=business_details.get("state_code", "27"),
                postal_code=business_details.get("postal_code"),
                gstin=business_details.get("gstin"),
                phone=business_details.get("phone"),
                email=business_details.get("email")
            )
        else:
            b_details = PartyDetails(
                name="Naiyo24 Business",
                address="",
                state_code="27"
            )
            
        # Map customer details
        c_gst = quotation.customer_gst or ""
        c_state_code = c_gst[:2] if len(c_gst) >= 2 else b_details.state_code or "27"
        
        c_details = PartyDetails(
            name=quotation.customer_name,
            address=quotation.customer_address,
            address_line_1=quotation.customer_address,
            gstin=quotation.customer_gst or None,
            phone=quotation.customer_mobile or None,
            state_code=c_state_code
        )
        
        # Calculate items and taxes
        is_intra_state = b_details.state_code == c_details.state_code
        
        computed_items = []
        total_taxable = Decimal("0")
        total_cgst = Decimal("0")
        total_sgst = Decimal("0")
        total_igst = Decimal("0")
        
        for item in quotation.items:
            qty = Decimal(str(item.quantity))
            price = Decimal(str(item.price))
            gst_rate = Decimal(str(item.gst_percent))
            discount_pct = Decimal(str(item.discount_percent))
            
            subtotal = qty * price
            discount_amt = subtotal * (discount_pct / Decimal("100"))
            taxable_amount = subtotal - discount_amt
            
            # Rounding
            taxable_amount = round_money(taxable_amount)
            
            if is_intra_state:
                half_rate = gst_rate / Decimal("2")
                cgst_rate = round_money(half_rate)
                sgst_rate = round_money(half_rate)
                igst_rate = Decimal("0")
                
                cgst_amount = round_money(taxable_amount * (cgst_rate / Decimal("100")))
                sgst_amount = round_money(taxable_amount * (sgst_rate / Decimal("100")))
                igst_amount = Decimal("0")
            else:
                cgst_rate = Decimal("0")
                sgst_rate = Decimal("0")
                igst_rate = round_money(gst_rate)
                
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
                    quantity=qty,
                    price=price,
                    gst_rate=gst_rate,
                    taxable_amount=taxable_amount,
                    cgst_rate=cgst_rate,
                    cgst_amount=cgst_amount,
                    sgst_rate=sgst_rate,
                    sgst_amount=sgst_amount,
                    igst_rate=igst_rate,
                    igst_amount=igst_amount,
                    line_total=line_total
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
            grand_total=grand_total
        )
        
        # Build InvoiceComputedData
        invoice_data = InvoiceComputedData(
            invoice_number=f"QT-{quotation.id:04d}",
            invoice_date=quotation.quotation_date or date.today(),
            due_date=quotation.valid_until,
            transaction_type="intra_state" if is_intra_state else "inter_state",
            invoice_type="regular",
            business=b_details,
            customer=c_details,
            items=computed_items,
            totals=totals,
            notes=quotation.notes,
            subtitle=quotation.subtitle,
            logo=quotation.logo,
            settings=quotation.settings
        )
        
        return InvoicePDFService._render_pdf_internal(invoice_data, title_override="QUOTATION")

    @staticmethod
    def _render_pdf_internal(invoice: InvoiceComputedData, title_override: str) -> bytes:
        pdf = InvoiceFPDF(format="A4")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Branding & Logo
        logo_drawn = False
        if invoice.logo:
            try:
                logo_data = invoice.logo
                if "," in logo_data:
                    logo_data = logo_data.split(",")[1]
                logo_bytes = base64.b64decode(logo_data)
                logo_stream = io.BytesIO(logo_bytes)
                pdf.image(logo_stream, x=10, y=15, w=35)
                logo_drawn = True
            except Exception:
                pass

        # Title
        pdf.set_font("Helvetica", "B", 18)
        pdf.set_text_color(40, 40, 40)
        pdf.set_xy(110, 15)
        pdf.cell(90, 8, title_override, align="R", new_x="LMARGIN", new_y="NEXT")

        # Document Meta
        pdf.set_font("Helvetica", "", 9)
        pdf.set_text_color(100, 100, 100)
        
        doc_num_label = "Quotation Number" if title_override == "QUOTATION" else "Invoice Number"
        doc_date_label = "Quotation Date" if title_override == "QUOTATION" else "Invoice Date"
        doc_due_label = "Valid Until" if title_override == "QUOTATION" else "Due Date"

        pdf.set_xy(110, 24)
        pdf.cell(90, 5, f"{doc_num_label}: {invoice.invoice_number}", align="R", new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_xy(110, 29)
        pdf.cell(90, 5, f"{doc_date_label}: {invoice.invoice_date.strftime('%d-%b-%Y')}", align="R", new_x="LMARGIN", new_y="NEXT")
        
        if invoice.due_date:
            pdf.set_xy(110, 34)
            pdf.cell(90, 5, f"{doc_due_label}: {invoice.due_date.strftime('%d-%b-%Y')}", align="R", new_x="LMARGIN", new_y="NEXT")

        start_y = 50 if logo_drawn else 40
        pdf.set_y(start_y)

        # Party Cards (Billed By / Billed To)
        pdf.set_fill_color(248, 248, 248)
        pdf.set_draw_color(220, 220, 220)
        card_h = 42
        pdf.rect(10, start_y, 92, card_h, style="DF")
        pdf.rect(108, start_y, 92, card_h, style="DF")

        # Billed By Card
        pdf.set_xy(13, start_y + 3)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(50, 50, 50)
        pdf.cell(86, 5, "Billed By:", new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "", 9)
        pdf.set_text_color(80, 80, 80)
        pdf.set_x(13)
        pdf.cell(86, 5, invoice.business.name, new_x="LMARGIN", new_y="NEXT")
        
        address_line = invoice.business.address_line_1 or invoice.business.address or ""
        if address_line:
            pdf.set_x(13)
            pdf.multi_cell(86, 4, address_line[:80])
            
        if invoice.business.phone:
            pdf.set_x(13)
            pdf.cell(86, 5, f"Phone: {invoice.business.phone}", new_x="LMARGIN", new_y="NEXT")
            
        if invoice.business.gstin:
            pdf.set_x(13)
            pdf.set_font("Helvetica", "B", 9)
            pdf.cell(86, 5, f"GSTIN: {invoice.business.gstin}", new_x="LMARGIN", new_y="NEXT")
            pdf.set_font("Helvetica", "", 9)

        # Billed To Card
        pdf.set_xy(111, start_y + 3)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(50, 50, 50)
        pdf.cell(86, 5, "Billed To:", new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "", 9)
        pdf.set_text_color(80, 80, 80)
        pdf.set_x(111)
        pdf.cell(86, 5, invoice.customer.name, new_x="LMARGIN", new_y="NEXT")
        
        c_address = invoice.customer.address_line_1 or invoice.customer.address or ""
        if c_address:
            pdf.set_x(111)
            pdf.multi_cell(86, 4, c_address[:80])
            
        if invoice.customer.phone:
            pdf.set_x(111)
            pdf.cell(86, 5, f"Phone: {invoice.customer.phone}", new_x="LMARGIN", new_y="NEXT")
            
        if invoice.customer.gstin:
            pdf.set_x(111)
            pdf.set_font("Helvetica", "B", 9)
            pdf.cell(86, 5, f"GSTIN: {invoice.customer.gstin}", new_x="LMARGIN", new_y="NEXT")
            pdf.set_font("Helvetica", "", 9)

        pdf.set_y(start_y + card_h + 8)

        # Dynamic Item Table
        has_igst = invoice.transaction_type == "inter_state" or any(item.igst_amount > 0 for item in invoice.items)

        def draw_table_header():
            pdf.set_font("Helvetica", "B", 8)
            pdf.set_fill_color(240, 240, 240)
            pdf.set_draw_color(220, 220, 220)
            pdf.set_text_color(50, 50, 50)
            
            if has_igst:
                headers = ["S.No", "Item Description", "Qty", "Rate", "Taxable", "GST %", "CGST", "SGST", "IGST", "Total"]
                col_widths = [8, 42, 16, 16, 20, 22, 16, 16, 16, 18]
            else:
                headers = ["S.No", "Item Description", "Qty", "Rate", "Taxable", "GST %", "CGST", "SGST", "Total"]
                col_widths = [10, 48, 20, 20, 22, 22, 16, 16, 16]
                
            for width, header in zip(col_widths, headers):
                pdf.cell(width, 8, header, border=1, align="C" if header != "Item Description" else "L", fill=True)
            pdf.ln(8)

        draw_table_header()

        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        
        if has_igst:
            col_widths = [8, 42, 16, 16, 20, 22, 16, 16, 16, 18]
        else:
            col_widths = [10, 48, 20, 20, 22, 22, 16, 16, 16]

        for idx, item in enumerate(invoice.items, 1):
            if pdf.get_y() > 260:
                pdf.add_page()
                draw_table_header()
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
                
            if has_igst:
                row_vals = [
                    str(idx),
                    item.name[:25],
                    f"{item.quantity:.2f}",
                    f"{item.price:.2f}",
                    f"{item.taxable_amount:.2f}",
                    f"{item.gst_rate:.0f}%",
                    f"{item.cgst_amount:.2f}",
                    f"{item.sgst_amount:.2f}",
                    f"{item.igst_amount:.2f}",
                    f"{item.line_total:.2f}"
                ]
            else:
                row_vals = [
                    str(idx),
                    item.name[:30],
                    f"{item.quantity:.2f}",
                    f"{item.price:.2f}",
                    f"{item.taxable_amount:.2f}",
                    f"{item.gst_rate:.0f}%",
                    f"{item.cgst_amount:.2f}",
                    f"{item.sgst_amount:.2f}",
                    f"{item.line_total:.2f}"
                ]
                
            for width, val, header in zip(col_widths, row_vals, ["S.No", "Item Description"] + [""] * 8):
                align = "C" if header == "S.No" else ("L" if header == "Item Description" else "R")
                pdf.cell(width, 7, val, border=1, align=align)
            pdf.ln(7)

        # Totals Section
        pdf.ln(4)
        if pdf.get_y() > 220:
            pdf.add_page()

        total_lbl_w = 150
        total_val_w = 40
        
        pdf.set_font("Helvetica", "B", 8)
        pdf.set_text_color(50, 50, 50)
        
        # Subtotal
        pdf.cell(total_lbl_w, 7, "Subtotal (Taxable Amount)", border=1, align="R")
        pdf.cell(total_val_w, 7, f"{invoice.totals.total_taxable_amount:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        
        # CGST
        pdf.cell(total_lbl_w, 7, "Total CGST", border=1, align="R")
        pdf.cell(total_val_w, 7, f"{invoice.totals.total_cgst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        
        # SGST
        pdf.cell(total_lbl_w, 7, "Total SGST", border=1, align="R")
        pdf.cell(total_val_w, 7, f"{invoice.totals.total_sgst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        
        if has_igst:
            # IGST
            pdf.cell(total_lbl_w, 7, "Total IGST", border=1, align="R")
            pdf.cell(total_val_w, 7, f"{invoice.totals.total_igst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
            
        round_off = getattr(invoice, "round_off", 0.00)
        if round_off != 0.00:
            pdf.cell(total_lbl_w, 7, "Round-off", border=1, align="R")
            pdf.cell(total_val_w, 7, f"{round_off:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
            
        pdf.set_fill_color(240, 240, 240)
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(total_lbl_w, 8, "Grand Total", border=1, align="R", fill=True)
        pdf.cell(total_val_w, 8, f"{invoice.totals.grand_total:.2f}", border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        if invoice.notes:
            pdf.ln(5)
            if pdf.get_y() > 250:
                pdf.add_page()
            pdf.set_font("Helvetica", "B", 10)
            pdf.cell(0, 7, "Notes:", new_x="LMARGIN", new_y="NEXT")
            pdf.set_font("Helvetica", "", 9)
            pdf.multi_cell(0, 5, invoice.notes)

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output
