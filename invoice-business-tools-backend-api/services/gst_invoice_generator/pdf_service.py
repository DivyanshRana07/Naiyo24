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
            notes=quotation.notes,  # Now safe to use directly
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

        # Title with dark gray/black color
        pdf.set_font("Helvetica", "B", 18)
        pdf.set_text_color(30, 30, 30)  # Very dark gray/black
        pdf.set_xy(110, 15)
        pdf.cell(90, 8, title_override, align="R", new_x="LMARGIN", new_y="NEXT")

        # Document Meta with enhanced information
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
        
        # Add transaction type if invoice
        if title_override != "QUOTATION":
            pdf.set_xy(110, 39)
            trans_type = "Intra State" if invoice.transaction_type == "intra_state" else "Inter State"
            pdf.cell(90, 5, f"Transaction: {trans_type}", align="R", new_x="LMARGIN", new_y="NEXT")
            
            # Add status
            pdf.set_xy(110, 44)
            status_display = invoice.status.upper() if hasattr(invoice, 'status') else "DUE"
            pdf.cell(90, 5, f"Status: {status_display}", align="R", new_x="LMARGIN", new_y="NEXT")

        # Add subtitle if available
        if invoice.subtitle:
            pdf.set_xy(10, pdf.get_y() + 2)
            pdf.set_font("Helvetica", "I", 9)
            pdf.set_text_color(120, 120, 120)
            pdf.multi_cell(190, 4, invoice.subtitle, align="C")

        start_y = 58 if logo_drawn else 48
        pdf.set_y(start_y)

        # Party Cards (Billed By / Billed To) with light gray background
        pdf.set_fill_color(245, 245, 245)  # Light gray background
        pdf.set_draw_color(180, 180, 180)  # Medium gray border
        card_h = 50
        pdf.rect(10, start_y, 92, card_h, style="DF")
        pdf.rect(108, start_y, 92, card_h, style="DF")

        # Billed By Card
        pdf.set_xy(13, start_y + 3)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(40, 40, 40)  # Dark gray text for header
        pdf.cell(86, 5, "Billed By:", new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(60, 60, 60)
        pdf.set_x(13)
        pdf.cell(86, 5, invoice.business.name, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        
        address_line = invoice.business.address_line_1 or invoice.business.address or ""
        if address_line:
            pdf.set_x(13)
            pdf.multi_cell(86, 4, address_line[:100])
            
        if invoice.business.city or invoice.business.state_name or invoice.business.postal_code:
            city_state = []
            if invoice.business.city:
                city_state.append(invoice.business.city)
            if invoice.business.state_name:
                city_state.append(invoice.business.state_name)
            if invoice.business.postal_code:
                city_state.append(invoice.business.postal_code)
            pdf.set_x(13)
            pdf.cell(86, 4, ", ".join(city_state), new_x="LMARGIN", new_y="NEXT")
            
        if invoice.business.phone:
            pdf.set_x(13)
            pdf.cell(86, 4, f"Ph: {invoice.business.phone}", new_x="LMARGIN", new_y="NEXT")
            
        if invoice.business.email:
            pdf.set_x(13)
            pdf.cell(86, 4, f"Email: {invoice.business.email}", new_x="LMARGIN", new_y="NEXT")
            
        if invoice.business.gstin:
            pdf.set_x(13)
            pdf.set_font("Helvetica", "B", 8)
            pdf.cell(86, 4, f"GSTIN: {invoice.business.gstin}", new_x="LMARGIN", new_y="NEXT")
            pdf.set_font("Helvetica", "", 8)

        # Billed To Card
        pdf.set_xy(111, start_y + 3)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(40, 40, 40)  # Dark gray text for header
        pdf.cell(86, 5, "Billed To:", new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(60, 60, 60)
        pdf.set_x(111)
        pdf.cell(86, 5, invoice.customer.name, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        
        c_address = invoice.customer.address_line_1 or invoice.customer.address or ""
        if c_address:
            pdf.set_x(111)
            pdf.multi_cell(86, 4, c_address[:100])
            
        if invoice.customer.city or invoice.customer.state_name or invoice.customer.postal_code:
            city_state = []
            if invoice.customer.city:
                city_state.append(invoice.customer.city)
            if invoice.customer.state_name:
                city_state.append(invoice.customer.state_name)
            if invoice.customer.postal_code:
                city_state.append(invoice.customer.postal_code)
            pdf.set_x(111)
            pdf.cell(86, 4, ", ".join(city_state), new_x="LMARGIN", new_y="NEXT")
            
        if invoice.customer.phone:
            pdf.set_x(111)
            pdf.cell(86, 4, f"Ph: {invoice.customer.phone}", new_x="LMARGIN", new_y="NEXT")
            
        if invoice.customer.email:
            pdf.set_x(111)
            pdf.cell(86, 4, f"Email: {invoice.customer.email}", new_x="LMARGIN", new_y="NEXT")
            
        if invoice.customer.gstin:
            pdf.set_x(111)
            pdf.set_font("Helvetica", "B", 8)
            pdf.cell(86, 4, f"GSTIN: {invoice.customer.gstin}", new_x="LMARGIN", new_y="NEXT")
            pdf.set_font("Helvetica", "", 8)

        pdf.set_y(start_y + card_h + 10)

        # Dynamic Item Table
        has_igst = invoice.transaction_type == "inter_state" or any(item.igst_amount > 0 for item in invoice.items)

        def draw_table_header():
            pdf.set_font("Helvetica", "B", 8)
            pdf.set_fill_color(60, 60, 60)  # Dark gray/charcoal background for table header
            pdf.set_draw_color(60, 60, 60)  # Dark gray border
            pdf.set_text_color(255, 255, 255)  # White text
            
            if has_igst:
                headers = ["#", "Item Description", "Qty", "Rate", "Taxable", "GST%", "CGST", "SGST", "IGST", "Total"]
                col_widths = [8, 42, 15, 18, 20, 16, 16, 16, 16, 23]
            else:
                headers = ["#", "Item Description", "Qty", "Rate", "Taxable", "GST%", "CGST", "SGST", "Total"]
                col_widths = [10, 48, 18, 20, 22, 18, 18, 18, 18]
                
            for width, header in zip(col_widths, headers):
                pdf.cell(width, 8, header, border=1, align="C" if header != "Item Description" else "L", fill=True)
            pdf.ln(8)

        draw_table_header()

        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)  # Reset border color for rows
        pdf.set_fill_color(252, 252, 252)  # Very light gray for alternating rows
        
        if has_igst:
            col_widths = [8, 42, 15, 18, 20, 16, 16, 16, 16, 23]
        else:
            col_widths = [10, 48, 18, 20, 22, 18, 18, 18, 18]

        for idx, item in enumerate(invoice.items, 1):
            if pdf.get_y() > 260:
                pdf.add_page()
                draw_table_header()
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
                pdf.set_draw_color(220, 220, 220)  # Reset border color for rows
            
            # Alternate row colors for better readability
            fill_row = idx % 2 == 0
            
            if has_igst:
                row_vals = [
                    str(idx),
                    item.name[:30],
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
                    item.name[:35],
                    f"{item.quantity:.2f}",
                    f"{item.price:.2f}",
                    f"{item.taxable_amount:.2f}",
                    f"{item.gst_rate:.0f}%",
                    f"{item.cgst_amount:.2f}",
                    f"{item.sgst_amount:.2f}",
                    f"{item.line_total:.2f}"
                ]
                
            for width, val, header in zip(col_widths, row_vals, ["#", "Item Description"] + [""] * 8):
                align = "C" if header == "#" else ("L" if header == "Item Description" else "R")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Totals Section with enhanced grayscale colors
        pdf.ln(4)
        if pdf.get_y() > 220:
            pdf.add_page()

        total_lbl_w = 150
        total_val_w = 40
        
        pdf.set_font("Helvetica", "B", 8)
        pdf.set_text_color(50, 50, 50)
        pdf.set_draw_color(200, 200, 200)
        pdf.set_fill_color(250, 250, 250)
        
        # Subtotal
        pdf.cell(total_lbl_w, 7, "Subtotal (Taxable Amount)", border=1, align="R", fill=True)
        pdf.cell(total_val_w, 7, f"Rs {invoice.totals.total_taxable_amount:.2f}", border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        # CGST
        if invoice.totals.total_cgst > 0:
            pdf.cell(total_lbl_w, 7, "Total CGST", border=1, align="R")
            pdf.cell(total_val_w, 7, f"Rs {invoice.totals.total_cgst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        
        # SGST
        if invoice.totals.total_sgst > 0:
            pdf.cell(total_lbl_w, 7, "Total SGST", border=1, align="R")
            pdf.cell(total_val_w, 7, f"Rs {invoice.totals.total_sgst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        
        if has_igst and invoice.totals.total_igst > 0:
            # IGST
            pdf.cell(total_lbl_w, 7, "Total IGST", border=1, align="R")
            pdf.cell(total_val_w, 7, f"Rs {invoice.totals.total_igst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
            
        round_off = getattr(invoice, "round_off", 0.00)
        if round_off != 0.00:
            pdf.cell(total_lbl_w, 7, "Round-off", border=1, align="R")
            sign = "+" if round_off >= 0 else ""
            pdf.cell(total_val_w, 7, f"Rs {sign}{round_off:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
            
        pdf.set_fill_color(60, 60, 60)  # Dark gray background for grand total
        pdf.set_draw_color(60, 60, 60)  # Dark gray border
        pdf.set_text_color(255, 255, 255)  # White text
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(total_lbl_w, 9, "Grand Total", border=1, align="R", fill=True)
        pdf.cell(total_val_w, 9, f"Rs {invoice.totals.grand_total:.2f}", border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        # Payment information for invoices
        if title_override != "QUOTATION":
            pdf.ln(2)
            pdf.set_font("Helvetica", "", 8)
            pdf.set_text_color(80, 80, 80)
            
            # Show payment details if available
            paid_amount = getattr(invoice, "paid_amount", 0.00)
            payment_method = getattr(invoice, "payment_method", None)
            
            if paid_amount > 0:
                pdf.set_font("Helvetica", "B", 8)
                pdf.cell(total_lbl_w, 6, "Paid Amount", border=1, align="R")
                pdf.cell(total_val_w, 6, f"Rs {paid_amount:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
                
                balance = float(invoice.totals.grand_total) - paid_amount
                if balance > 0:
                    pdf.set_fill_color(255, 240, 240)  # Light red tint
                    pdf.cell(total_lbl_w, 6, "Balance Due", border=1, align="R", fill=True)
                    pdf.cell(total_val_w, 6, f"Rs {balance:.2f}", border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")
                elif balance == 0:
                    pdf.set_fill_color(240, 255, 240)  # Light green tint
                    pdf.cell(total_lbl_w, 6, "Status", border=1, align="R", fill=True)
                    pdf.cell(total_val_w, 6, "PAID", border=1, align="C", fill=True, new_x="LMARGIN", new_y="NEXT")
                    
            if payment_method:
                pdf.set_font("Helvetica", "", 8)
                pdf.cell(0, 5, f"Payment Method: {payment_method}", new_x="LMARGIN", new_y="NEXT")

        # Notes section with better formatting
        if invoice.notes:
            pdf.ln(6)
            if pdf.get_y() > 250:
                pdf.add_page()
            
            pdf.set_fill_color(248, 248, 248)
            pdf.set_draw_color(200, 200, 200)
            pdf.rect(10, pdf.get_y(), 190, 1, style="F")
            pdf.ln(2)
            
            pdf.set_font("Helvetica", "B", 9)
            pdf.set_text_color(50, 50, 50)
            pdf.cell(0, 6, "Notes / Terms & Conditions:", new_x="LMARGIN", new_y="NEXT")
            
            pdf.set_font("Helvetica", "", 8)
            pdf.set_text_color(80, 80, 80)
            pdf.multi_cell(0, 4, invoice.notes)

        # Bank details or additional info section (if settings provided)
        if invoice.settings and isinstance(invoice.settings, dict):
            bank_details = invoice.settings.get("bank_details")
            if bank_details:
                pdf.ln(4)
                if pdf.get_y() > 250:
                    pdf.add_page()
                    
                pdf.set_fill_color(248, 248, 248)
                pdf.set_draw_color(200, 200, 200)
                pdf.rect(10, pdf.get_y(), 190, 1, style="F")
                pdf.ln(2)
                
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_text_color(50, 50, 50)
                pdf.cell(0, 6, "Bank Details for Payment:", new_x="LMARGIN", new_y="NEXT")
                
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
                
                if isinstance(bank_details, dict):
                    if bank_details.get("bank_name"):
                        pdf.cell(0, 4, f"Bank Name: {bank_details['bank_name']}", new_x="LMARGIN", new_y="NEXT")
                    if bank_details.get("account_number"):
                        pdf.cell(0, 4, f"Account Number: {bank_details['account_number']}", new_x="LMARGIN", new_y="NEXT")
                    if bank_details.get("ifsc_code"):
                        pdf.cell(0, 4, f"IFSC Code: {bank_details['ifsc_code']}", new_x="LMARGIN", new_y="NEXT")
                    if bank_details.get("branch"):
                        pdf.cell(0, 4, f"Branch: {bank_details['branch']}", new_x="LMARGIN", new_y="NEXT")
                elif isinstance(bank_details, str):
                    pdf.multi_cell(0, 4, bank_details)

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output
