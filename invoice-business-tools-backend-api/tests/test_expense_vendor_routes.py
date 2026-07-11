# pyrefly: ignore [missing-import]
import pytest

def _vendor(name: str = "Acme Supplies", email: str = "acme@example.com") -> dict:
    return {
        "name": name,
        "email": email,
        "phone": "555-0199",
        "address": "123 Industrial Way",
        "gstin": "27AAAAA1111A1Z1",
        "contactPerson": "John Doe"
    }

def _expense(vendor_id: int, expense_number: str = "EXP-2026-001") -> dict:
    return {
        "vendor_id": vendor_id,
        "expense_number": expense_number,
        "expense_date": "2026-07-06",
        "expected_delivery_date": "2026-07-15",
        "status": "Draft",
        "notes": "Test expense notes",
        "title": "Item Expense Title",
        "description": "Item Expense Description",
        "totalAmount": 0.00,
        "items": [
            {
                "name": "Widget A",
                "quantity": 10.0,
                "price": 100.0,
                "gst_rate": 18.0,
                "line_total": 1180.0
            },
            {
                "name": "Widget B",
                "quantity": 5.0,
                "price": 200.0,
                "gst_rate": 18.0,
                "line_total": 1180.0
            }
        ]
    }

# ---------------------------------------------------------------------------
# Test Vendors
# ---------------------------------------------------------------------------

class TestVendors:
    def test_create_vendor(self, client):
        resp = client.post("/api/v1/vendors/add", json=_vendor())
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["name"] == "Acme Supplies"
        assert data["data"]["contactPerson"] == "John Doe"
        assert "id" in data["data"]

    def test_list_vendors(self, client):
        # Add a vendor
        client.post("/api/v1/vendors/add", json=_vendor(name="List Vendor"))
        
        resp = client.get("/api/v1/vendors/list")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]) >= 1
        # Check that the alias is serialized properly
        assert "contactPerson" in data["data"][0]

    def test_get_vendor_by_id(self, client):
        # Create
        create_resp = client.post("/api/v1/vendors/add", json=_vendor(name="Get Vendor"))
        vendor_id = create_resp.json()["data"]["id"]
        
        # Get
        resp = client.get(f"/api/v1/vendors/{vendor_id}")
        assert resp.status_code == 200
        assert resp.json()["data"]["name"] == "Get Vendor"
        assert resp.json()["data"]["contactPerson"] == "John Doe"

    def test_update_vendor(self, client):
        create_resp = client.post("/api/v1/vendors/add", json=_vendor(name="Old Name"))
        vendor_id = create_resp.json()["data"]["id"]
        
        resp = client.put(f"/api/v1/vendors/{vendor_id}", json={"name": "New Name", "contactPerson": "Jane Smith"})
        assert resp.status_code == 200
        assert resp.json()["data"]["name"] == "New Name"
        assert resp.json()["data"]["contactPerson"] == "Jane Smith"

    def test_delete_vendor(self, client):
        create_resp = client.post("/api/v1/vendors/add", json=_vendor(name="To Delete"))
        vendor_id = create_resp.json()["data"]["id"]
        
        resp = client.delete(f"/api/v1/vendors/{vendor_id}")
        assert resp.status_code == 200
        assert resp.json()["success"] is True
        
        # Get should now fail
        get_resp = client.get(f"/api/v1/vendors/{vendor_id}")
        assert get_resp.status_code == 404


# ---------------------------------------------------------------------------
# Test Expenses
# ---------------------------------------------------------------------------

class TestExpenses:
    def test_create_expense(self, client):
        # First create a vendor
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor())
        vendor_id = vendor_resp.json()["data"]["id"]
        
        # Create Expense
        expense_payload = _expense(vendor_id, expense_number="EXP-CREATE-001")
        resp = client.post("/api/v1/expenses/create", json=expense_payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["expenseNumber"] == "EXP-CREATE-001"
        assert data["data"]["title"] == "Item Expense Title"
        assert data["data"]["description"] == "Item Expense Description"
        assert data["data"]["totalAmount"] == 2360.0  # Sum of line_totals
        assert len(data["data"]["items"]) == 2

    def test_create_flat_expense(self, client):
        # First create a vendor
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor())
        vendor_id = vendor_resp.json()["data"]["id"]
        
        # Create flat expense without items
        flat_expense_payload = {
            "vendor_id": vendor_id,
            "expense_number": "EXP-FLAT-001",
            "expense_date": "2026-07-06",
            "expected_delivery_date": "2026-07-15",
            "status": "Draft",
            "notes": "Test flat expense",
            "title": "Flat Expense Title",
            "description": "Flat Expense Description",
            "totalAmount": 1500.50,
            "items": None
        }
        resp = client.post("/api/v1/expenses/create", json=flat_expense_payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["expenseNumber"] == "EXP-FLAT-001"
        assert data["data"]["title"] == "Flat Expense Title"
        assert data["data"]["description"] == "Flat Expense Description"
        assert data["data"]["totalAmount"] == 1500.50
        assert data["data"]["items"] == []

    def test_list_expenses(self, client):
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor())
        vendor_id = vendor_resp.json()["data"]["id"]
        client.post("/api/v1/expenses/create", json=_expense(vendor_id, expense_number="EXP-LIST-001"))
        
        resp = client.get("/api/v1/expenses/list")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]) >= 1

