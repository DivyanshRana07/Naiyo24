import pytest
from models.db_models import Product, User
from core.security import hash_password

def _seed_product(db_session, user_id, name="Test Product", category="Medicine", unit="Strip", code="P001", **kwargs):
    product = Product(
        user_id=user_id,
        code=code,
        name=name,
        category=category,
        unit=unit,
        purchase_price=kwargs.get("purchase_price", 10.0),
        selling_price=kwargs.get("selling_price", 20.0),
        stock_qty=kwargs.get("stock_qty", 100),
        gst_percent=kwargs.get("gst_percent", 12.0),
        status=kwargs.get("status", "active")
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)
    return product

class TestProductCreate:
    def test_create_product_success(self, auth_client):
        payload = {
            "name": "Paracetamol 650mg",
            "category": "Medicine",
            "unit": "Strip",
            "purchasePrice": 15.0,
            "sellingPrice": 22.0,
            "stockQty": 120,
            "gstPercent": 12.0,
            "status": "active"
        }
        resp = auth_client.post("/api/v1/products", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["message"] == "Product created successfully"
        p_data = data["data"]
        assert "id" in p_data
        assert p_data["code"] == "P001"
        assert p_data["name"] == "Paracetamol 650mg"
        assert p_data["category"] == "Medicine"
        assert p_data["unit"] == "Strip"
        assert p_data["purchasePrice"] == 15.0
        assert p_data["sellingPrice"] == 22.0
        assert p_data["stockQty"] == 120
        assert p_data["gstPercent"] == 12.0
        assert p_data["status"] == "active"

    def test_create_product_code_increment(self, auth_client, db_session, test_user):
        _seed_product(db_session, test_user.id, code="P001")
        _seed_product(db_session, test_user.id, code="P002")

        payload = {
            "name": "Widget C",
            "category": "Tools",
            "unit": "Pcs",
            "purchasePrice": 5.0,
            "sellingPrice": 8.0,
            "stockQty": 10,
            "gstPercent": 18.0
        }
        resp = auth_client.post("/api/v1/products", json=payload)
        assert resp.status_code == 200
        assert resp.json()["data"]["code"] == "P003"

    def test_create_product_missing_required_returns_422(self, auth_client):
        payload = {"name": "Incomplete Product"}
        resp = auth_client.post("/api/v1/products", json=payload)
        assert resp.status_code == 422

class TestProductList:
    def test_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/products")
        assert resp.status_code == 200
        assert resp.json()["success"] is True
        assert resp.json()["data"] == []

    def test_list_all_for_user(self, auth_client, db_session, test_user):
        _seed_product(db_session, test_user.id, name="P1", code="P001")
        _seed_product(db_session, test_user.id, name="P2", code="P002")

        resp = auth_client.get("/api/v1/products")
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert len(data) == 2
        assert {p["code"] for p in data} == {"P001", "P002"}

    def test_search_by_code(self, auth_client, db_session, test_user):
        _seed_product(db_session, test_user.id, name="P1", code="P001")
        _seed_product(db_session, test_user.id, name="P2", code="P002")

        resp = auth_client.get("/api/v1/products?q=P002")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["code"] == "P002"

    def test_search_by_name(self, auth_client, db_session, test_user):
        _seed_product(db_session, test_user.id, name="Acetaminophen", code="P001")
        _seed_product(db_session, test_user.id, name="Ibuprofen", code="P002")

        resp = auth_client.get("/api/v1/products?q=Ibuprofen")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["name"] == "Ibuprofen"

    def test_search_by_category(self, auth_client, db_session, test_user):
        _seed_product(db_session, test_user.id, name="A", category="Medicine")
        _seed_product(db_session, test_user.id, name="B", category="Device")

        resp = auth_client.get("/api/v1/products?q=Device")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["name"] == "B"

class TestProductGetById:
    def test_get_product_success(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id)
        resp = auth_client.get(f"/api/v1/products/{p.id}")
        assert resp.status_code == 200
        assert resp.json()["data"]["name"] == "Test Product"

    def test_get_product_not_found(self, auth_client):
        resp = auth_client.get("/api/v1/products/999")
        assert resp.status_code == 404

class TestProductUpdate:
    def test_update_product_success(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id, name="Old Name")
        payload = {
            "name": "New Name",
            "sellingPrice": 25.0
        }
        resp = auth_client.put(f"/api/v1/products/{p.id}", json=payload)
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["name"] == "New Name"
        assert data["sellingPrice"] == 25.0

    def test_update_product_not_found(self, auth_client):
        payload = {"name": "No Body"}
        resp = auth_client.put("/api/v1/products/999", json=payload)
        assert resp.status_code == 404

class TestProductStockPatch:
    def test_stock_deduct_success(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id, stock_qty=100)
        payload = {"deduct": 30}
        resp = auth_client.patch(f"/api/v1/products/{p.id}/stock", json=payload)
        assert resp.status_code == 200
        assert resp.json()["data"]["stockQty"] == 70

    def test_stock_restore_success(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id, stock_qty=100)
        payload = {"restore": 20}
        resp = auth_client.patch(f"/api/v1/products/{p.id}/stock", json=payload)
        assert resp.status_code == 200
        assert resp.json()["data"]["stockQty"] == 120

    def test_stock_deduct_insufficient_returns_400(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id, stock_qty=10)
        payload = {"deduct": 15}
        resp = auth_client.patch(f"/api/v1/products/{p.id}/stock", json=payload)
        assert resp.status_code == 400
        assert "Insufficient stock" in resp.json()["message"]

    def test_stock_deduct_negative_returns_400(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id, stock_qty=10)
        payload = {"deduct": -5}
        resp = auth_client.patch(f"/api/v1/products/{p.id}/stock", json=payload)
        assert resp.status_code == 400

    def test_stock_restore_negative_returns_400(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id, stock_qty=10)
        payload = {"restore": -5}
        resp = auth_client.patch(f"/api/v1/products/{p.id}/stock", json=payload)
        assert resp.status_code == 400

    def test_stock_update_not_found(self, auth_client):
        payload = {"deduct": 5}
        resp = auth_client.patch("/api/v1/products/999/stock", json=payload)
        assert resp.status_code == 404

class TestProductDelete:
    def test_delete_product_success(self, auth_client, db_session, test_user):
        p = _seed_product(db_session, test_user.id)
        resp = auth_client.delete(f"/api/v1/products/{p.id}")
        assert resp.status_code == 200
        assert resp.json()["message"] == "Product deleted successfully"

        # verify no longer accessible
        resp_get = auth_client.get(f"/api/v1/products/{p.id}")
        assert resp_get.status_code == 404

    def test_delete_product_not_found(self, auth_client):
        resp = auth_client.delete("/api/v1/products/999")
        assert resp.status_code == 404

class TestProductUserOwnership:
    def test_user_cannot_access_other_user_product(self, auth_client, db_session):
        other_user = User(
            username="otheruser",
            email="other@example.com",
            hashed_password=hash_password("password123"),
        )
        db_session.add(other_user)
        db_session.commit()
        db_session.refresh(other_user)

        p = _seed_product(db_session, other_user.id, name="Other Product")

        resp_list = auth_client.get("/api/v1/products")
        assert resp_list.json()["data"] == []

        resp_get = auth_client.get(f"/api/v1/products/{p.id}")
        assert resp_get.status_code == 404

        resp_put = auth_client.put(f"/api/v1/products/{p.id}", json={"name": "Hacked"})
        assert resp_put.status_code == 404

        resp_patch = auth_client.patch(f"/api/v1/products/{p.id}/stock", json={"deduct": 10})
        assert resp_patch.status_code == 404

        resp_del = auth_client.delete(f"/api/v1/products/{p.id}")
        assert resp_del.status_code == 404
