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

def _po(vendor_id: int, po_number: str = "PO-2026-001") -> dict:
    return {
        "vendor_id": vendor_id,
        "po_number": po_number,
        "po_date": "2026-07-06",
        "expected_delivery_date": "2026-07-15",
        "status": "Draft",
        "notes": "Test PO notes",
        "title": "Item PO Title",
        "description": "Item PO Description",
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
# Test Purchase Orders
# ---------------------------------------------------------------------------

class TestPurchaseOrders:
    def test_create_po(self, client):
        # First create a vendor
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor())
        vendor_id = vendor_resp.json()["data"]["id"]
        
        # Create PO
        po_payload = _po(vendor_id, po_number="PO-CREATE-001")
        resp = client.post("/api/v1/purchase-orders/create", json=po_payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["po_number"] == "PO-CREATE-001"
        assert data["data"]["title"] == "Item PO Title"
        assert data["data"]["description"] == "Item PO Description"
        assert data["data"]["totalAmount"] == 2360.0  # Sum of line_totals
        assert len(data["data"]["items"]) == 2

    def test_create_flat_po(self, client):
        # First create a vendor
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor())
        vendor_id = vendor_resp.json()["data"]["id"]
        
        # Create flat PO without items
        flat_po_payload = {
            "vendor_id": vendor_id,
            "po_number": "PO-FLAT-001",
            "po_date": "2026-07-06",
            "expected_delivery_date": "2026-07-15",
            "status": "Draft",
            "notes": "Test flat PO",
            "title": "Flat PO Title",
            "description": "Flat PO Description",
            "totalAmount": 1500.50,
            "items": None
        }
        resp = client.post("/api/v1/purchase-orders/create", json=flat_po_payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["po_number"] == "PO-FLAT-001"
        assert data["data"]["title"] == "Flat PO Title"
        assert data["data"]["description"] == "Flat PO Description"
        assert data["data"]["totalAmount"] == 1500.50
        assert data["data"]["items"] == []
        
        # Convert to expense and check amount
        po_id = data["data"]["id"]
        convert_resp = client.post(f"/api/v1/purchase-orders/{po_id}/convert-to-expense")
        assert convert_resp.status_code == 200
        convert_data = convert_resp.json()
        assert convert_data["success"] is True
        assert convert_data["data"]["amount"] == 1500.50
        assert convert_data["data"]["category"] == "Purchase Order"

    def test_list_pos(self, client):
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor())
        vendor_id = vendor_resp.json()["data"]["id"]
        client.post("/api/v1/purchase-orders/create", json=_po(vendor_id, po_number="PO-LIST-001"))
        
        resp = client.get("/api/v1/purchase-orders/list")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]) >= 1

    def test_convert_po_to_expense(self, client):
        # Create a vendor
        vendor_resp = client.post("/api/v1/vendors/add", json=_vendor(name="Convert Vendor"))
        vendor_id = vendor_resp.json()["data"]["id"]
        
        # Create PO
        po_payload = _po(vendor_id, po_number="PO-CONVERT-001")
        po_resp = client.post("/api/v1/purchase-orders/create", json=po_payload)
        po_id = po_resp.json()["data"]["id"]
        
        # Convert PO to Expense
        resp = client.post(f"/api/v1/purchase-orders/{po_id}/convert-to-expense")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["amount"] == 2360.0  # 1180 + 1180
        assert data["data"]["vendor_id"] == vendor_id
        assert data["data"]["purchase_order_id"] == po_id
        assert data["data"]["category"] == "Purchase Order"
        
        # Confirm PO status is updated to Billed
        po_get = client.get(f"/api/v1/purchase-orders/{po_id}")
        assert po_get.json()["data"]["status"] == "Billed"
