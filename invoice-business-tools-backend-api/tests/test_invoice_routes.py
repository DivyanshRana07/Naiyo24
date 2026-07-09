"""
test_invoice_routes.py — Integration tests for POST /api/v1/invoices/create.

Uses FastAPI TestClient + an isolated in-memory SQLite database.
No mocking — actual DB persistence is verified after each request.

Route behaviour (after import fix):
  - Computes GST via GSTInvoiceService.compute_invoice(payload)
  - Persists Invoice + InvoiceItem rows via GSTInvoiceService.save_invoice_to_db()
  - Returns { success, message, data: InvoiceComputedData }
"""

import pytest
from sqlalchemy.orm import Session

from models.db_models import Invoice, InvoiceItem

# ---------------------------------------------------------------------------
# Reusable test payload builders
# ---------------------------------------------------------------------------

def _business(state_code: str = "27") -> dict:
    return {
        "name": "Acme Technologies Pvt Ltd",
        "address_line_1": "101 Business Park Andheri East",
        "city": "Mumbai",
        "state_name": "Maharashtra",
        "state_code": state_code,
        "postal_code": "400069",
        "gstin": "27AABCU9603R1ZX",
    }


def _customer(state_code: str = "27") -> dict:
    return {
        "name": "Customer Corp Ltd",
        "address_line_1": "202 Client Road Sector 15",
        "city": "Pune",
        "state_name": "Maharashtra",
        "state_code": state_code,
        "postal_code": "411001",
    }


def _item(name="Consulting Service", qty="10", price="1000", gst_rate="18") -> dict:
    return {"name": name, "quantity": qty, "price": price, "gst_rate": gst_rate}


def _payload(
    invoice_number: str = "TEST-INV-001",
    business_state: str = "27",
    customer_state: str = "27",
    items: list | None = None,
    notes: str | None = None,
) -> dict:
    payload = {
        "invoice_number": invoice_number,
        "invoice_date": "2024-01-15",
        "due_date": "2024-02-15",
        "business": _business(business_state),
        "customer": _customer(customer_state),
        "items": items or [_item()],
    }
    if notes:
        payload["notes"] = notes
    return payload


# ---------------------------------------------------------------------------
# 1. Successful creation
# ---------------------------------------------------------------------------

class TestInvoiceCreateSuccess:

    def test_returns_200(self, auth_client):
        resp = auth_client.post("/api/v1/invoices/create", json=_payload())
        assert resp.status_code == 200

    def test_response_success_flag(self, auth_client):
        resp = auth_client.post("/api/v1/invoices/create", json=_payload())
        assert resp.json()["success"] is True

    def test_response_contains_invoice_number(self, auth_client):
        resp = auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="MY-INV-007"))
        data = resp.json()["data"]
        assert data["invoice_number"] == "MY-INV-007"

    def test_intra_state_transaction_type(self, auth_client):
        # Same state code → intra_state
        resp = auth_client.post("/api/v1/invoices/create", json=_payload(business_state="27", customer_state="27"))
        assert resp.json()["data"]["transaction_type"] == "intra_state"

    def test_inter_state_transaction_type(self, auth_client):
        # Different state codes → inter_state
        resp = auth_client.post("/api/v1/invoices/create", json=_payload(business_state="27", customer_state="29"))
        assert resp.json()["data"]["transaction_type"] == "inter_state"

    def test_response_contains_totals(self, auth_client):
        resp = auth_client.post("/api/v1/invoices/create", json=_payload())
        totals = resp.json()["data"]["tax_breakdown"]
        assert "grand_total" in totals
        assert "total_taxable_amount" in totals
        assert "total_cgst" in totals
        assert "total_sgst" in totals
        assert "total_igst" in totals

    def test_intra_state_grand_total_value(self, auth_client):
        # qty=10, price=1000, gst=18 → taxable=10000, cgst=900, sgst=900 → grand=11800
        resp = auth_client.post("/api/v1/invoices/create", json=_payload())
        grand_total = float(resp.json()["data"]["tax_breakdown"]["grand_total"])
        assert grand_total == pytest.approx(11800.00, rel=1e-4)

    def test_inter_state_grand_total_value(self, auth_client):
        # same amounts but IGST=1800 instead of cgst+sgst
        resp = auth_client.post(
            "/api/v1/invoices/create",
            json=_payload(business_state="27", customer_state="29"),
        )
        grand_total = float(resp.json()["data"]["tax_breakdown"]["grand_total"])
        assert grand_total == pytest.approx(11800.00, rel=1e-4)

    def test_notes_in_response(self, auth_client):
        resp = auth_client.post("/api/v1/invoices/create", json=_payload(notes="Pay within 30 days"))
        assert resp.json()["data"]["notes"] == "Pay within 30 days"

    def test_items_in_response(self, auth_client):
        resp = auth_client.post("/api/v1/invoices/create", json=_payload())
        assert len(resp.json()["data"]["items"]) == 1

    def test_multiple_items_in_response(self, auth_client):
        items = [_item("Item A"), _item("Item B", qty="5", price="500")]
        resp = auth_client.post("/api/v1/invoices/create", json=_payload(items=items))
        assert len(resp.json()["data"]["items"]) == 2


# ---------------------------------------------------------------------------
# 2. Database persistence verification
# ---------------------------------------------------------------------------

class TestInvoiceDatabasePersistence:
    """
    After POST /create, queries the test DB directly to confirm rows exist.
    Both the HTTP client and the assertion session share the same test_engine.
    """

    def test_invoice_row_created_in_db(self, auth_client, db_session):
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-001"))
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-001").first()
        assert invoice is not None

    def test_invoice_number_persisted(self, auth_client, db_session):
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-002"))
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-002").first()
        assert invoice is not None
        assert invoice.invoice_number == "DB-INV-002"

    def test_invoice_item_rows_created(self, auth_client, db_session):
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-003"))
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-003").first()
        assert invoice is not None
        item_count = db_session.query(InvoiceItem).filter(InvoiceItem.invoice_id == invoice.id).count()
        assert item_count == 1

    def test_invoice_items_count_matches_payload(self, auth_client, session_factory):
        items = [_item("Item A"), _item("Item B"), _item("Item C")]
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-004", items=items))
        # Open a fresh session after the request commits — no stale cache
        with session_factory() as fresh_session:
            invoice = fresh_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-004").first()
            assert invoice is not None
            item_count = fresh_session.query(InvoiceItem).filter(InvoiceItem.invoice_id == invoice.id).count()
        assert item_count == 3

    def test_tax_breakdown_json_persisted(self, auth_client, db_session):
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-005"))
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-005").first()
        assert invoice is not None
        assert invoice.tax_breakdown is not None
        assert "grand_total" in invoice.tax_breakdown

    def test_business_details_json_snapshot_persisted(self, auth_client, db_session):
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-006"))
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-006").first()
        assert invoice is not None
        assert invoice.business_details["name"] == "Acme Technologies Pvt Ltd"

    def test_customer_details_json_snapshot_persisted(self, auth_client, db_session):
        auth_client.post("/api/v1/invoices/create", json=_payload(invoice_number="DB-INV-007"))
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-007").first()
        assert invoice is not None
        assert invoice.customer_details["name"] == "Customer Corp Ltd"

    def test_transaction_type_persisted(self, auth_client, db_session):
        auth_client.post(
            "/api/v1/invoices/create",
            json=_payload(invoice_number="DB-INV-008", business_state="27", customer_state="29"),
        )
        invoice = db_session.query(Invoice).filter(Invoice.invoice_number == "DB-INV-008").first()
        assert invoice is not None
        assert invoice.transaction_type == "inter_state"



# ---------------------------------------------------------------------------
# 3. Validation error scenarios
# ---------------------------------------------------------------------------

class TestInvoiceCreateValidationErrors:

    def test_missing_business_returns_422(self, auth_client):
        payload = _payload()
        del payload["business"]
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_missing_customer_returns_422(self, auth_client):
        payload = _payload()
        del payload["customer"]
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_empty_items_returns_422(self, auth_client):
        # null items field triggers 422 (missing required list)
        payload = _payload()
        payload["items"] = None
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_invalid_state_code_returns_422(self, auth_client):
        payload = _payload()
        payload["business"]["state_code"] = "INVALID"
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_negative_quantity_returns_422(self, auth_client):
        payload = _payload(items=[_item(qty="-5")])
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_gst_rate_over_100_returns_422(self, auth_client):
        payload = _payload(items=[_item(gst_rate="150")])
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_due_date_before_invoice_date_returns_422(self, auth_client):
        payload = _payload()
        payload["invoice_date"] = "2024-06-01"
        payload["due_date"] = "2024-05-01"  # before invoice_date
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        assert resp.status_code == 422

    def test_validation_error_response_structure(self, auth_client):
        payload = _payload()
        payload["business"] = None   # missing required field → 422
        resp = auth_client.post("/api/v1/invoices/create", json=payload)
        body = resp.json()
        assert resp.status_code == 422
        assert body["success"] is False
        assert "message" in body
        assert "errors" in body
