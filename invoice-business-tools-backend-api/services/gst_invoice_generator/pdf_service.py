from __future__ import annotations

from fpdf import FPDF

from models.invoice_generator import InvoiceComputedData


class InvoicePDFService:
    @staticmethod
    def render_invoice_pdf(invoice: InvoiceComputedData) -> bytes:
        pdf = FPDF(format="A4")
        pdf.set_auto_page_break(auto=True, margin=15)
        pdf.add_page()

        pdf.set_font("Helvetica", "B", 16)
        title = "PROFORMA INVOICE" if invoice.invoice_type == "proforma" else "TAX INVOICE"
        pdf.cell(0, 10, title, new_x="LMARGIN", new_y="NEXT", align="C")

        pdf.set_font("Helvetica", "", 11)
        pdf.cell(100, 7, f"Invoice No: {invoice.invoice_number}")
        pdf.cell(0, 7, f"Invoice Date: {invoice.invoice_date.isoformat()}", new_x="LMARGIN", new_y="NEXT")
        due_date = invoice.due_date.isoformat() if invoice.due_date else "-"
        pdf.cell(100, 7, f"Due Date: {due_date}")
        pdf.cell(0, 7, f"Transaction: {invoice.transaction_type.replace('_', ' ').title()}", new_x="LMARGIN", new_y="NEXT")
        pdf.ln(3)

        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(95, 8, "From (Business)", border=1)
        pdf.cell(95, 8, "To (Customer)", border=1, new_x="LMARGIN", new_y="NEXT")

        pdf.set_font("Helvetica", "", 10)
        left_lines = [
            invoice.business.name,
            invoice.business.address_line_1,
            invoice.business.address_line_2 or "",
            f"{invoice.business.city}, {invoice.business.state_name} - {invoice.business.postal_code}",
            f"State Code: {invoice.business.state_code}",
            f"GSTIN: {invoice.business.gstin or '-'}",
        ]
        right_lines = [
            invoice.customer.name,
            invoice.customer.address_line_1,
            invoice.customer.address_line_2 or "",
            f"{invoice.customer.city}, {invoice.customer.state_name} - {invoice.customer.postal_code}",
            f"State Code: {invoice.customer.state_code}",
            f"GSTIN: {invoice.customer.gstin or '-'}",
        ]

        for index in range(max(len(left_lines), len(right_lines))):
            left = left_lines[index] if index < len(left_lines) else ""
            right = right_lines[index] if index < len(right_lines) else ""
            pdf.cell(95, 7, left, border=1)
            pdf.cell(95, 7, right, border=1, new_x="LMARGIN", new_y="NEXT")

        pdf.ln(4)
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(50, 8, "Item", border=1)
        pdf.cell(18, 8, "Qty", border=1, align="R")
        pdf.cell(22, 8, "Price", border=1, align="R")
        pdf.cell(22, 8, "Taxable", border=1, align="R")
        pdf.cell(18, 8, "CGST", border=1, align="R")
        pdf.cell(18, 8, "SGST", border=1, align="R")
        pdf.cell(18, 8, "IGST", border=1, align="R")
        pdf.cell(22, 8, "Total", border=1, align="R", new_x="LMARGIN", new_y="NEXT")

        pdf.set_font("Helvetica", "", 9)
        for item in invoice.items:
            pdf.cell(50, 7, item.name[:28], border=1)
            pdf.cell(18, 7, f"{item.quantity:.2f}", border=1, align="R")
            pdf.cell(22, 7, f"{item.price:.2f}", border=1, align="R")
            pdf.cell(22, 7, f"{item.taxable_amount:.2f}", border=1, align="R")
            pdf.cell(18, 7, f"{item.cgst_amount:.2f}", border=1, align="R")
            pdf.cell(18, 7, f"{item.sgst_amount:.2f}", border=1, align="R")
            pdf.cell(18, 7, f"{item.igst_amount:.2f}", border=1, align="R")
            pdf.cell(22, 7, f"{item.line_total:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")

        pdf.ln(2)
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(148, 8, "Subtotal", border=1)
        pdf.cell(42, 8, f"{invoice.totals.total_taxable_amount:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        pdf.cell(148, 8, "Total CGST", border=1)
        pdf.cell(42, 8, f"{invoice.totals.total_cgst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        pdf.cell(148, 8, "Total SGST", border=1)
        pdf.cell(42, 8, f"{invoice.totals.total_sgst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        pdf.cell(148, 8, "Total IGST", border=1)
        pdf.cell(42, 8, f"{invoice.totals.total_igst:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")
        pdf.cell(148, 8, "Grand Total", border=1)
        pdf.cell(42, 8, f"{invoice.totals.grand_total:.2f}", border=1, align="R", new_x="LMARGIN", new_y="NEXT")

        if invoice.notes:
            pdf.ln(4)
            pdf.set_font("Helvetica", "B", 10)
            pdf.cell(0, 7, "Notes", new_x="LMARGIN", new_y="NEXT")
            pdf.set_font("Helvetica", "", 10)
            pdf.multi_cell(0, 6, invoice.notes)

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output
