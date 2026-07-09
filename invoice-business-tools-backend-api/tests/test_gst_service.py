"""
test_gst_service.py — Pure unit tests for GSTInvoiceService.compute_invoice().

No HTTP layer. No database. Tests the core GST tax engine directly.

GST Rules Implemented:
  Intra-state (same state_code): CGST = SGST = gst_rate / 2,  IGST = 0
  Inter-state (diff state_code): IGST = gst_rate,             CGST = SGST = 0

All monetary values are rounded to 2 decimal places (ROUND_HALF_UP).
"""

from decimal import Decimal

import pytest

from models.invoice_generator import (
    InvoiceCreateRequest,
    InvoiceItemInput,
    PartyDetails,
)
from services.gst_invoice_generator.gst_invoice_service import GSTInvoiceService


# ---------------------------------------------------------------------------
# Helper factories
# ---------------------------------------------------------------------------

def _party(state_code: str, gstin: str | None = None) -> PartyDetails:
    """Build a minimal valid PartyDetails for a given state code."""
    return PartyDetails(
        name="Test Entity Pvt Ltd",
        address_line_1="123 Test Street Block A",
        city="TestCity",
        state_name="TestState",
        state_code=state_code,
        postal_code="400001",
        gstin=gstin,
    )


def _item(
    name: str = "Test Item",
    quantity: str = "10",
    price: str = "100",
    gst_rate: str = "18",
) -> InvoiceItemInput:
    return InvoiceItemInput(
        name=name,
        quantity=Decimal(quantity),
        price=Decimal(price),
        gst_rate=Decimal(gst_rate),
    )


def _request(
    business_state: str,
    customer_state: str,
    items: list[InvoiceItemInput],
    invoice_number: str = "TEST-001",
) -> InvoiceCreateRequest:
    return InvoiceCreateRequest(
        invoice_number=invoice_number,
        business=_party(business_state, gstin="27AABCU9603R1ZX"),
        customer=_party(customer_state),
        items=items,
    )


# ---------------------------------------------------------------------------
# 1. Intra-State Tests (CGST + SGST, IGST = 0)
# ---------------------------------------------------------------------------

class TestIntraStateTransaction:
    """Business and customer share the same state code → CGST + SGST apply."""

    def test_transaction_type_is_intra_state(self):
        req = _request("27", "27", [_item()])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.transaction_type == "intra_state"

    def test_cgst_equals_half_gst_rate(self):
        # gst_rate=18 → cgst_rate=9
        req = _request("27", "27", [_item(gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.cgst_rate == Decimal("9.00")

    def test_sgst_equals_half_gst_rate(self):
        req = _request("27", "27", [_item(gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.sgst_rate == Decimal("9.00")

    def test_igst_is_zero(self):
        req = _request("27", "27", [_item(gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.igst_rate == Decimal("0")
        assert item.igst_amount == Decimal("0")

    def test_cgst_amount_correct(self):
        # qty=10, price=100 → taxable=1000, cgst_rate=9 → cgst=90
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.items[0].cgst_amount == Decimal("90.00")

    def test_sgst_amount_correct(self):
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.items[0].sgst_amount == Decimal("90.00")

    def test_line_total_correct(self):
        # taxable=1000, cgst=90, sgst=90 → line_total=1180
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.items[0].line_total == Decimal("1180.00")

    def test_grand_total_correct(self):
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.grand_total == Decimal("1180.00")

    def test_total_taxable_amount(self):
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_taxable_amount == Decimal("1000.00")

    def test_total_cgst_in_breakdown(self):
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_cgst == Decimal("90.00")

    def test_total_igst_is_zero_in_breakdown(self):
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_igst == Decimal("0")


# ---------------------------------------------------------------------------
# 2. Inter-State Tests (IGST only, CGST = SGST = 0)
# ---------------------------------------------------------------------------

class TestInterStateTransaction:
    """Business and customer have different state codes → IGST applies."""

    def test_transaction_type_is_inter_state(self):
        req = _request("27", "29", [_item()])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.transaction_type == "inter_state"

    def test_igst_rate_equals_full_gst_rate(self):
        req = _request("27", "29", [_item(gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.items[0].igst_rate == Decimal("18.00")

    def test_cgst_is_zero(self):
        req = _request("27", "29", [_item(gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.cgst_rate == Decimal("0")
        assert item.cgst_amount == Decimal("0")

    def test_sgst_is_zero(self):
        req = _request("27", "29", [_item(gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.sgst_rate == Decimal("0")
        assert item.sgst_amount == Decimal("0")

    def test_igst_amount_correct(self):
        # taxable=1000, igst_rate=18 → igst=180
        req = _request("27", "29", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.items[0].igst_amount == Decimal("180.00")

    def test_line_total_correct(self):
        # taxable=1000, igst=180 → line_total=1180
        req = _request("27", "29", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.items[0].line_total == Decimal("1180.00")

    def test_grand_total_correct(self):
        req = _request("27", "29", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.grand_total == Decimal("1180.00")

    def test_total_igst_in_breakdown(self):
        req = _request("27", "29", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_igst == Decimal("180.00")

    def test_total_cgst_is_zero_in_breakdown(self):
        req = _request("27", "29", [_item(quantity="10", price="100", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_cgst == Decimal("0")


# ---------------------------------------------------------------------------
# 3. Multiple Items Tests
# ---------------------------------------------------------------------------

class TestMultipleItems:
    """Verify tax aggregation across multiple line items."""

    def test_two_items_total_taxable(self):
        # item1: qty=5, price=200 → 1000 | item2: qty=3, price=100 → 300 | total=1300
        items = [
            _item(name="Item A", quantity="5", price="200", gst_rate="18"),
            _item(name="Item B", quantity="3", price="100", gst_rate="12"),
        ]
        req = _request("27", "27", items)
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_taxable_amount == Decimal("1300.00")

    def test_two_items_total_cgst(self):
        # item1: taxable=1000, cgst_rate=9 → cgst=90
        # item2: taxable=300,  cgst_rate=6 → cgst=18
        # total_cgst = 108
        items = [
            _item(name="Item A", quantity="5", price="200", gst_rate="18"),
            _item(name="Item B", quantity="3", price="100", gst_rate="12"),
        ]
        req = _request("27", "27", items)
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_cgst == Decimal("108.00")

    def test_two_items_total_sgst(self):
        items = [
            _item(name="Item A", quantity="5", price="200", gst_rate="18"),
            _item(name="Item B", quantity="3", price="100", gst_rate="12"),
        ]
        req = _request("27", "27", items)
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_sgst == Decimal("108.00")

    def test_two_items_grand_total(self):
        # grand_total = 1300 + 108 + 108 = 1516
        items = [
            _item(name="Item A", quantity="5", price="200", gst_rate="18"),
            _item(name="Item B", quantity="3", price="100", gst_rate="12"),
        ]
        req = _request("27", "27", items)
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.grand_total == Decimal("1516.00")

    def test_item_count_matches(self):
        items = [_item(name=f"Item {i}") for i in range(3)]
        req = _request("27", "27", items)
        result = GSTInvoiceService.compute_invoice(req)
        assert len(result.items) == 3

    def test_total_tax_equals_cgst_plus_sgst_plus_igst(self):
        items = [
            _item(name="Item A", quantity="5", price="200", gst_rate="18"),
            _item(name="Item B", quantity="3", price="100", gst_rate="12"),
        ]
        req = _request("27", "27", items)
        result = GSTInvoiceService.compute_invoice(req)
        t = result.totals
        assert t.total_tax == t.total_cgst + t.total_sgst + t.total_igst


# ---------------------------------------------------------------------------
# 4. Edge Case Tests
# ---------------------------------------------------------------------------

class TestEdgeCases:
    """Boundary values, zero GST, large amounts, rounding."""

    def test_zero_gst_rate(self):
        # GST exempt item: all taxes zero
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="0")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.cgst_amount == Decimal("0")
        assert item.sgst_amount == Decimal("0")
        assert item.igst_amount == Decimal("0")
        assert item.line_total == Decimal("1000.00")
        assert result.totals.grand_total == Decimal("1000.00")

    def test_zero_gst_grand_total_equals_taxable(self):
        req = _request("27", "27", [_item(quantity="10", price="100", gst_rate="0")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.grand_total == result.totals.total_taxable_amount

    def test_large_values(self):
        # qty=1000, price=50000, gst_rate=28
        # taxable = 50_000_000, cgst_rate=14, cgst=7_000_000
        req = _request("27", "27", [_item(quantity="1000", price="50000", gst_rate="28")])
        result = GSTInvoiceService.compute_invoice(req)
        assert result.totals.total_taxable_amount == Decimal("50000000.00")
        assert result.totals.total_cgst == Decimal("7000000.00")
        assert result.totals.grand_total == Decimal("64000000.00")

    def test_rounding_two_decimal_places(self):
        # qty=1, price=99.99, gst_rate=18 (intra)
        # taxable=99.99, cgst=round(99.99*0.09)=round(8.9991)=9.00
        req = _request("27", "27", [_item(quantity="1", price="99.99", gst_rate="18")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.taxable_amount == Decimal("99.99")
        assert item.cgst_amount == Decimal("9.00")
        assert item.sgst_amount == Decimal("9.00")
        assert item.line_total == Decimal("117.99")

    def test_fractional_gst_rate_5_percent(self):
        # qty=3, price=100, gst_rate=5 → taxable=300, cgst_rate=2.50, cgst=7.50
        req = _request("27", "27", [_item(quantity="3", price="100", gst_rate="5")])
        result = GSTInvoiceService.compute_invoice(req)
        item = result.items[0]
        assert item.cgst_rate == Decimal("2.50")
        assert item.cgst_amount == Decimal("7.50")
        assert item.sgst_amount == Decimal("7.50")
        assert result.totals.grand_total == Decimal("315.00")

    def test_invoice_number_auto_generated_when_absent(self):
        req = InvoiceCreateRequest(
            business=_party("27", gstin="27AABCU9603R1ZX"),
            customer=_party("27"),
            items=[_item()],
        )
        result = GSTInvoiceService.compute_invoice(req)
        assert result.invoice_number.startswith("INV-")
        assert len(result.invoice_number) > 4

    def test_invoice_number_preserved_when_provided(self):
        req = _request("27", "27", [_item()], invoice_number="MY-INV-999")
        result = GSTInvoiceService.compute_invoice(req)
        assert result.invoice_number == "MY-INV-999"

    def test_notes_propagated(self):
        req = InvoiceCreateRequest(
            invoice_number="N-001",
            business=_party("27", gstin="27AABCU9603R1ZX"),
            customer=_party("27"),
            items=[_item()],
            notes="Net 30 days payment",
        )
        result = GSTInvoiceService.compute_invoice(req)
        assert result.notes == "Net 30 days payment"


# ---------------------------------------------------------------------------
# 5. Validation Tests
# ---------------------------------------------------------------------------

class TestValidation:
    """Confirm that invalid inputs are rejected by Pydantic before hitting GST logic."""

    def test_empty_items_list_rejected(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            InvoiceCreateRequest(
                invoice_number="V-001",
                business=_party("27", gstin="27AABCU9603R1ZX"),
                customer=_party("27"),
                items=[],  # min_length=1
            )

    def test_negative_quantity_rejected(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            InvoiceItemInput(name="Bad Item", quantity=Decimal("-1"), price=Decimal("100"), gst_rate=Decimal("18"))

    def test_negative_price_rejected(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            InvoiceItemInput(name="Bad Item", quantity=Decimal("1"), price=Decimal("-10"), gst_rate=Decimal("18"))

    def test_gst_rate_above_100_rejected(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            InvoiceItemInput(name="Bad Item", quantity=Decimal("1"), price=Decimal("100"), gst_rate=Decimal("101"))

    def test_invalid_state_code_rejected(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            _party("ABC")  # must be exactly 2 digits

    def test_invalid_gstin_rejected(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            _party("27", gstin="INVALID")

    def test_due_date_before_invoice_date_rejected(self):
        from pydantic import ValidationError
        from datetime import date
        with pytest.raises(ValidationError):
            InvoiceCreateRequest(
                invoice_number="V-002",
                invoice_date=date(2024, 6, 1),
                due_date=date(2024, 5, 1),  # before invoice_date
                business=_party("27", gstin="27AABCU9603R1ZX"),
                customer=_party("27"),
                items=[_item()],
            )
