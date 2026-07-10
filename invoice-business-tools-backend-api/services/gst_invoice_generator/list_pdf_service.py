from __future__ import annotations

import io
from datetime import date
from fpdf import FPDF


class ListPDF(FPDF):
    def __init__(self, title: str):
        super().__init__(format="A4", orientation="L")  # Landscape for more columns
        self.title_text = title
        
    def header(self):
        self.set_font("Helvetica", "B", 16)
        self.set_text_color(40, 40, 40)
        self.cell(0, 10, self.title_text, align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Helvetica", "", 9)
        self.set_text_color(100, 100, 100)
        self.cell(0, 6, f"Generated on {date.today().strftime('%d %B %Y')}", align="C", new_x="LMARGIN", new_y="NEXT")
        self.ln(5)
        
    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f"Page {self.page_no()}", align="C")


class ListPDFService:
    @staticmethod
    def render_invoice_list_pdf(invoices: list) -> bytes:
        """Generate a PDF list of all invoices"""
        pdf = ListPDF("Invoice List Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Invoice No", "Date", "Customer", "Type", "Amount", "Paid", "Balance", "Status"]
        col_widths = [12, 35, 28, 60, 30, 28, 28, 28, 28]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        total_amount = 0
        total_paid = 0
        total_balance = 0
        
        for idx, inv in enumerate(invoices, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                # Redraw header
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            # Get values
            invoice_no = inv.invoice_number if hasattr(inv, 'invoice_number') else str(inv.id)
            inv_date = inv.invoice_date.strftime('%d/%m/%Y') if hasattr(inv, 'invoice_date') and inv.invoice_date else '-'
            customer = inv.business_details.get('name', 'N/A')[:25] if hasattr(inv, 'business_details') else 'N/A'
            inv_type = inv.invoice_type.title() if hasattr(inv, 'invoice_type') else 'Regular'
            
            # Get financial data
            tax_breakdown = inv.tax_breakdown if hasattr(inv, 'tax_breakdown') else {}
            grand_total = float(tax_breakdown.get('grand_total', 0))
            paid_amount = float(inv.paid_amount if hasattr(inv, 'paid_amount') and inv.paid_amount else 0)
            balance = grand_total - paid_amount
            status = inv.status if hasattr(inv, 'status') else 'due'
            
            total_amount += grand_total
            total_paid += paid_amount
            total_balance += balance
            
            row_data = [
                str(idx),
                invoice_no[:20],
                inv_date,
                customer,
                inv_type,
                f"Rs {grand_total:.2f}",
                f"Rs {paid_amount:.2f}",
                f"Rs {balance:.2f}",
                status.upper()
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else ("R" if "Rs" in val else "L")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary section
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        
        summary_data = [
            ("Total Invoices:", str(len(invoices))),
            ("Total Amount:", f"Rs {total_amount:.2f}"),
            ("Total Paid:", f"Rs {total_paid:.2f}"),
            ("Total Balance:", f"Rs {total_balance:.2f}"),
        ]
        
        for label, value in summary_data:
            pdf.cell(80, 7, label, border=1, fill=True)
            pdf.cell(80, 7, value, border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_quotation_list_pdf(quotations: list) -> bytes:
        """Generate a PDF list of all quotations"""
        pdf = ListPDF("Quotation List Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Quotation No", "Date", "Valid Until", "Customer", "Amount", "Status"]
        col_widths = [12, 40, 32, 32, 80, 35, 30]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        total_amount = 0
        
        for idx, quot in enumerate(quotations, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                # Redraw header
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            # Get values
            quot_no = f"QT-{quot.id:04d}"
            quot_date = quot.quotation_date.strftime('%d/%m/%Y') if quot.quotation_date else '-'
            valid_until = quot.valid_until.strftime('%d/%m/%Y') if quot.valid_until else '-'
            customer = quot.customer_name[:35] if quot.customer_name else 'N/A'
            amount = float(quot.total)
            status = quot.status if quot.status else 'Draft'
            
            total_amount += amount
            
            row_data = [
                str(idx),
                quot_no,
                quot_date,
                valid_until,
                customer,
                f"Rs {amount:.2f}",
                status.upper()
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else ("R" if "Rs" in val else "L")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary section
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        
        summary_data = [
            ("Total Quotations:", str(len(quotations))),
            ("Total Amount:", f"Rs {total_amount:.2f}"),
        ]
        
        for label, value in summary_data:
            pdf.cell(80, 7, label, border=1, fill=True)
            pdf.cell(80, 7, value, border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_customer_list_pdf(customers: list) -> bytes:
        """Generate a PDF list of all customers"""
        pdf = ListPDF("Customer List Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Code", "Name", "Mobile", "Email", "GST No", "Credit Limit", "Status"]
        col_widths = [12, 25, 60, 35, 50, 40, 32, 23]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        for idx, cust in enumerate(customers, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            row_data = [
                str(idx),
                cust.code[:15] if hasattr(cust, 'code') else '',
                cust.name[:30] if hasattr(cust, 'name') else '',
                cust.mobile if hasattr(cust, 'mobile') else '',
                cust.email[:25] if hasattr(cust, 'email') and cust.email else '-',
                cust.gst_number if hasattr(cust, 'gst_number') and cust.gst_number else '-',
                f"Rs {float(cust.credit_limit):.2f}" if hasattr(cust, 'credit_limit') else 'Rs 0.00',
                cust.status.upper() if hasattr(cust, 'status') else 'ACTIVE'
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else ("R" if "Rs" in val else "L")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        pdf.cell(80, 7, "Total Customers:", border=1, fill=True)
        pdf.cell(80, 7, str(len(customers)), border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_vendor_list_pdf(vendors: list) -> bytes:
        """Generate a PDF list of all vendors"""
        pdf = ListPDF("Vendor List Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Name", "Email", "Phone", "Address", "GST No"]
        col_widths = [12, 60, 55, 35, 75, 40]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        for idx, vendor in enumerate(vendors, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            row_data = [
                str(idx),
                vendor.name[:30] if hasattr(vendor, 'name') else '',
                vendor.email[:30] if hasattr(vendor, 'email') and vendor.email else '-',
                vendor.phone if hasattr(vendor, 'phone') else '',
                vendor.address[:40] if hasattr(vendor, 'address') and vendor.address else '-',
                vendor.gst_number if hasattr(vendor, 'gst_number') and vendor.gst_number else '-'
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else "L"
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        pdf.cell(80, 7, "Total Vendors:", border=1, fill=True)
        pdf.cell(80, 7, str(len(vendors)), border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_item_list_pdf(items: list) -> bytes:
        """Generate a PDF list of all items"""
        pdf = ListPDF("Item List Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Code", "Name", "Unit", "Sale Price", "Purchase Price", "Stock", "Status"]
        col_widths = [12, 30, 70, 25, 32, 35, 25, 28]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        for idx, item in enumerate(items, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            row_data = [
                str(idx),
                item.code[:20] if hasattr(item, 'code') else '',
                item.name[:35] if hasattr(item, 'name') else '',
                item.unit if hasattr(item, 'unit') else '',
                f"Rs {float(item.selling_price):.2f}" if hasattr(item, 'selling_price') else 'Rs 0.00',
                f"Rs {float(item.purchase_price):.2f}" if hasattr(item, 'purchase_price') else 'Rs 0.00',
                str(int(item.stock_qty)) if hasattr(item, 'stock_qty') else '0',
                item.status.upper() if hasattr(item, 'status') else 'ACTIVE'
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else ("R" if "Rs" in val or val.isdigit() else "L")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        pdf.cell(80, 7, "Total Items:", border=1, fill=True)
        pdf.cell(80, 7, str(len(items)), border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_service_list_pdf(services: list) -> bytes:
        """Generate a PDF list of all services"""
        pdf = ListPDF("Service List Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Code", "Name", "Category", "Price", "GST %", "Status"]
        col_widths = [12, 35, 80, 50, 35, 25, 28]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        for idx, service in enumerate(services, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            row_data = [
                str(idx),
                service.code[:25] if hasattr(service, 'code') else '',
                service.name[:40] if hasattr(service, 'name') else '',
                service.category[:30] if hasattr(service, 'category') and service.category else '-',
                f"Rs {float(service.selling_price):.2f}" if hasattr(service, 'selling_price') else 'Rs 0.00',
                f"{float(service.gst_percent):.1f}%" if hasattr(service, 'gst_percent') else '0%',
                service.status.upper() if hasattr(service, 'status') else 'ACTIVE'
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else ("R" if "Rs" in val or "%" in val else "L")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        pdf.cell(80, 7, "Total Services:", border=1, fill=True)
        pdf.cell(80, 7, str(len(services)), border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_activity_list_pdf(activities: list) -> bytes:
        """Generate a PDF list of all activity logs"""
        pdf = ListPDF("Activity Log Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "Action", "Description", "Date"]
        col_widths = [12, 55, 145, 45]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        for idx, activity in enumerate(activities, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            action = activity.action if hasattr(activity, 'action') else 'Activity'
            # Remove special characters like Rupee symbol that Helvetica doesn't support
            description = activity.description[:75] if hasattr(activity, 'description') and activity.description else (activity.title[:75] if hasattr(activity, 'title') else '')
            # Replace Rupee symbol and other special characters
            description = description.replace('₹', 'Rs ').replace('€', 'EUR ').replace('$', 'USD ').replace('£', 'GBP ')
            activity_date = activity.created_at.strftime('%d/%m/%Y %H:%M') if hasattr(activity, 'created_at') and activity.created_at else '-'
            
            row_data = [
                str(idx),
                action[:30],
                description,
                activity_date
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else "L"
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        pdf.cell(80, 7, "Total Activities:", border=1, fill=True)
        pdf.cell(80, 7, str(len(activities)), border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output

    @staticmethod
    def render_purchase_order_list_pdf(purchase_orders: list) -> bytes:
        """Generate a PDF list of all purchase orders (expenses)"""
        pdf = ListPDF("Expense Report")
        pdf.set_margins(10, 15, 10)
        pdf.set_auto_page_break(auto=True, margin=20)
        pdf.add_page()

        # Table header
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_draw_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        
        headers = ["#", "PO Number", "Date", "Vendor", "Title", "Amount", "Status"]
        col_widths = [12, 35, 30, 60, 70, 35, 25]
        
        for width, header in zip(col_widths, headers):
            pdf.cell(width, 8, header, border=1, align="C", fill=True)
        pdf.ln(8)

        # Table rows
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.set_draw_color(220, 220, 220)
        pdf.set_fill_color(252, 252, 252)
        
        total_amount = 0
        
        for idx, po in enumerate(purchase_orders, 1):
            if pdf.get_y() > 170:
                pdf.add_page()
                pdf.set_font("Helvetica", "B", 9)
                pdf.set_fill_color(60, 60, 60)
                pdf.set_text_color(255, 255, 255)
                for width, header in zip(col_widths, headers):
                    pdf.cell(width, 8, header, border=1, align="C", fill=True)
                pdf.ln(8)
                pdf.set_font("Helvetica", "", 8)
                pdf.set_text_color(80, 80, 80)
            
            fill_row = idx % 2 == 0
            
            po_number = po.po_number if hasattr(po, 'po_number') else f"PO-{po.id:04d}"
            po_date = po.date.strftime('%d/%m/%Y') if hasattr(po, 'date') and po.date else '-'
            vendor_name = po.vendor_name[:30] if hasattr(po, 'vendor_name') else 'N/A'
            title = po.title[:35] if hasattr(po, 'title') and po.title else '-'
            amount = float(po.total_amount) if hasattr(po, 'total_amount') else 0.0
            status = po.status.upper() if hasattr(po, 'status') else 'PENDING'
            
            total_amount += amount
            
            row_data = [
                str(idx),
                po_number[:25],
                po_date,
                vendor_name,
                title,
                f"Rs {amount:.2f}",
                status
            ]
            
            for width, val in zip(col_widths, row_data):
                align = "C" if width == 12 else ("R" if "Rs" in val else "L")
                pdf.cell(width, 7, val, border=1, align=align, fill=fill_row)
            pdf.ln(7)

        # Summary
        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_fill_color(60, 60, 60)
        pdf.set_text_color(255, 255, 255)
        pdf.cell(0, 10, "Summary", align="L", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(40, 40, 40)
        pdf.set_fill_color(245, 245, 245)
        
        summary_data = [
            ("Total Expenses:", str(len(purchase_orders))),
            ("Total Amount:", f"Rs {total_amount:.2f}"),
        ]
        
        for label, value in summary_data:
            pdf.cell(80, 7, label, border=1, fill=True)
            pdf.cell(80, 7, value, border=1, align="R", fill=True, new_x="LMARGIN", new_y="NEXT")

        output = pdf.output(dest="S")
        if isinstance(output, bytearray):
            return bytes(output)
        if isinstance(output, str):
            return output.encode("latin-1")
        return output
