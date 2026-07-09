import pytest
from models.db_models import Customer, User
from core.security import hash_password

def _seed_customer(db_session, user_id, name="Test Customer", mobile="9876543210", code="C001", **kwargs):
    customer = Customer(
        user_id=user_id,
        code=code,
        name=name,
        mobile=mobile,
        email=kwargs.get("email"),
        address=kwargs.get("address"),
        gst_number=kwargs.get("gst_number"),
        opening_balance=kwargs.get("opening_balance", 0.0),
        credit_limit=kwargs.get("credit_limit", 0.0),
        status=kwargs.get("status", "active")
    )
    db_session.add(customer)
    db_session.commit()
    db_session.refresh(customer)
    return customer

class TestCustomerCreate:
    def test_create_customer_success(self, auth_client):
        payload = {
            "name": "Rahul Pharmacy",
            "mobile": "9876543211",
            "email": "rahul@pharmacy.com",
            "address": "Baghajatin, Kolkata",
            "gstNumber": "19ABCDE1234F1Z5",
            "openingBalance": 1500.0,
            "creditLimit": 20000.0,
            "status": "active"
        }
        resp = auth_client.post("/api/v1/customers", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["message"] == "Customer created successfully"
        customer_data = data["data"]
        assert "id" in customer_data
        assert customer_data["code"] == "C001"
        assert customer_data["name"] == "Rahul Pharmacy"
        assert customer_data["mobile"] == "9876543211"
        assert customer_data["email"] == "rahul@pharmacy.com"
        assert customer_data["address"] == "Baghajatin, Kolkata"
        assert customer_data["gstNumber"] == "19ABCDE1234F1Z5"
        assert customer_data["openingBalance"] == 1500.0
        assert customer_data["creditLimit"] == 20000.0
        assert customer_data["status"] == "active"

    def test_create_customer_defaults(self, auth_client):
        payload = {
            "name": "Quick Client",
            "mobile": "9999988888"
        }
        resp = auth_client.post("/api/v1/customers", json=payload)
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["openingBalance"] == 0.0
        assert data["creditLimit"] == 0.0
        assert data["status"] == "active"

    def test_create_customer_code_increment(self, auth_client, db_session, test_user):
        # Seed two customers
        _seed_customer(db_session, test_user.id, code="C001")
        _seed_customer(db_session, test_user.id, code="C002")

        payload = {
            "name": "Third Client",
            "mobile": "1234567890"
        }
        resp = auth_client.post("/api/v1/customers", json=payload)
        assert resp.status_code == 200
        assert resp.json()["data"]["code"] == "C003"

    def test_create_customer_missing_name_returns_422(self, auth_client):
        payload = {"mobile": "9876543210"}
        resp = auth_client.post("/api/v1/customers", json=payload)
        assert resp.status_code == 422

    def test_create_customer_missing_mobile_returns_422(self, auth_client):
        payload = {"name": "No Mobile"}
        resp = auth_client.post("/api/v1/customers", json=payload)
        assert resp.status_code == 422

class TestCustomerList:
    def test_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/customers")
        assert resp.status_code == 200
        assert resp.json()["success"] is True
        assert resp.json()["data"] == []

    def test_list_all_for_user(self, auth_client, db_session, test_user):
        _seed_customer(db_session, test_user.id, name="Customer 1", code="C001")
        _seed_customer(db_session, test_user.id, name="Customer 2", code="C002")

        resp = auth_client.get("/api/v1/customers")
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert len(data) == 2
        assert {c["code"] for c in data} == {"C001", "C002"}

    def test_search_by_code(self, auth_client, db_session, test_user):
        _seed_customer(db_session, test_user.id, name="A Store", code="C001")
        _seed_customer(db_session, test_user.id, name="B Store", code="C002")

        resp = auth_client.get("/api/v1/customers?q=C002")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["code"] == "C002"

    def test_search_by_name(self, auth_client, db_session, test_user):
        _seed_customer(db_session, test_user.id, name="Rahul Pharmacy", code="C001")
        _seed_customer(db_session, test_user.id, name="Gopal Pharmacy", code="C002")

        resp = auth_client.get("/api/v1/customers?q=Gopal")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["name"] == "Gopal Pharmacy"

    def test_search_by_mobile(self, auth_client, db_session, test_user):
        _seed_customer(db_session, test_user.id, name="A", mobile="9876543210")
        _seed_customer(db_session, test_user.id, name="B", mobile="8888877777")

        resp = auth_client.get("/api/v1/customers?q=88888")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["name"] == "B"

class TestCustomerGetById:
    def test_get_customer_success(self, auth_client, db_session, test_user):
        c = _seed_customer(db_session, test_user.id)
        resp = auth_client.get(f"/api/v1/customers/{c.id}")
        assert resp.status_code == 200
        assert resp.json()["data"]["name"] == "Test Customer"

    def test_get_customer_not_found(self, auth_client):
        resp = auth_client.get("/api/v1/customers/999")
        assert resp.status_code == 404

class TestCustomerUpdate:
    def test_update_customer_success(self, auth_client, db_session, test_user):
        c = _seed_customer(db_session, test_user.id, name="Old Name")
        payload = {
            "name": "New Name",
            "creditLimit": 50000.0
        }
        resp = auth_client.put(f"/api/v1/customers/{c.id}", json=payload)
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["name"] == "New Name"
        assert data["creditLimit"] == 50000.0

    def test_update_customer_not_found(self, auth_client):
        payload = {"name": "No Body"}
        resp = auth_client.put("/api/v1/customers/999", json=payload)
        assert resp.status_code == 404

class TestCustomerDelete:
    def test_delete_customer_success(self, auth_client, db_session, test_user):
        c = _seed_customer(db_session, test_user.id)
        resp = auth_client.delete(f"/api/v1/customers/{c.id}")
        assert resp.status_code == 200
        assert resp.json()["message"] == "Customer deleted successfully"

        # verify no longer accessible
        resp_get = auth_client.get(f"/api/v1/customers/{c.id}")
        assert resp_get.status_code == 404

    def test_delete_customer_not_found(self, auth_client):
        resp = auth_client.delete("/api/v1/customers/999")
        assert resp.status_code == 404

class TestCustomerUserOwnership:
    def test_user_cannot_access_other_user_customer(self, auth_client, db_session):
        # Create another user
        other_user = User(
            username="otheruser",
            email="other@example.com",
            hashed_password=hash_password("password123"),
        )
        db_session.add(other_user)
        db_session.commit()
        db_session.refresh(other_user)

        # Seed customer under other user
        c = _seed_customer(db_session, other_user.id, name="Other User Customer")

        # Verify current user list is empty
        resp_list = auth_client.get("/api/v1/customers")
        assert resp_list.json()["data"] == []

        # Verify current user cannot fetch by ID
        resp_get = auth_client.get(f"/api/v1/customers/{c.id}")
        assert resp_get.status_code == 404

        # Verify current user cannot update
        resp_put = auth_client.put(f"/api/v1/customers/{c.id}", json={"name": "Hacked"})
        assert resp_put.status_code == 404

        # Verify current user cannot delete
        resp_del = auth_client.delete(f"/api/v1/customers/{c.id}")
        assert resp_del.status_code == 404
