import pytest
from models.db_models import Service, User
from core.security import hash_password

def _seed_service(db_session, user_id, name="Test Service", category="Consulting", code="S001", **kwargs):
    service = Service(
        user_id=user_id,
        code=code,
        name=name,
        category=category,
        selling_price=kwargs.get("selling_price", 150.0),
        gst_percent=kwargs.get("gst_percent", 18.0),
        status=kwargs.get("status", "active")
    )
    db_session.add(service)
    db_session.commit()
    db_session.refresh(service)
    return service

class TestServiceCreate:
    def test_create_service_success(self, auth_client):
        payload = {
            "name": "Delivery Charge",
            "category": "Delivery",
            "sellingPrice": 150.0,
            "gstPercent": 18.0,
            "status": "active"
        }
        resp = auth_client.post("/api/v1/services", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["message"] == "Service created successfully"
        s_data = data["data"]
        assert "id" in s_data
        assert s_data["code"] == "S001"
        assert s_data["name"] == "Delivery Charge"
        assert s_data["category"] == "Delivery"
        assert s_data["sellingPrice"] == 150.0
        assert s_data["gstPercent"] == 18.0
        assert s_data["status"] == "active"

    def test_create_service_code_increment(self, auth_client, db_session, test_user):
        _seed_service(db_session, test_user.id, code="S001")
        _seed_service(db_session, test_user.id, code="S002")

        payload = {
            "name": "Another Service",
            "category": "Consulting",
            "sellingPrice": 500.0,
            "gstPercent": 18.0
        }
        resp = auth_client.post("/api/v1/services", json=payload)
        assert resp.status_code == 200
        assert resp.json()["data"]["code"] == "S003"

    def test_create_service_missing_required_returns_422(self, auth_client):
        payload = {"name": "No Price"}
        resp = auth_client.post("/api/v1/services", json=payload)
        assert resp.status_code == 422

class TestServiceList:
    def test_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/services")
        assert resp.status_code == 200
        assert resp.json()["success"] is True
        assert resp.json()["data"] == []

    def test_list_all_for_user(self, auth_client, db_session, test_user):
        _seed_service(db_session, test_user.id, name="S1", code="S001")
        _seed_service(db_session, test_user.id, name="S2", code="S002")

        resp = auth_client.get("/api/v1/services")
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert len(data) == 2
        assert {s["code"] for s in data} == {"S001", "S002"}

    def test_search_by_code(self, auth_client, db_session, test_user):
        _seed_service(db_session, test_user.id, name="S1", code="S001")
        _seed_service(db_session, test_user.id, name="S2", code="S002")

        resp = auth_client.get("/api/v1/services?q=S002")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["code"] == "S002"

    def test_search_by_name(self, auth_client, db_session, test_user):
        _seed_service(db_session, test_user.id, name="Development", code="S001")
        _seed_service(db_session, test_user.id, name="Consultation", code="S002")

        resp = auth_client.get("/api/v1/services?q=Consultation")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["name"] == "Consultation"

    def test_search_by_category(self, auth_client, db_session, test_user):
        _seed_service(db_session, test_user.id, name="S1", category="Consulting")
        _seed_service(db_session, test_user.id, name="S2", category="Support")

        resp = auth_client.get("/api/v1/services?q=Support")
        data = resp.json()["data"]
        assert len(data) == 1
        assert data[0]["name"] == "S2"

class TestServiceGetById:
    def test_get_service_success(self, auth_client, db_session, test_user):
        s = _seed_service(db_session, test_user.id)
        resp = auth_client.get(f"/api/v1/services/{s.id}")
        assert resp.status_code == 200
        assert resp.json()["data"]["name"] == "Test Service"

    def test_get_service_not_found(self, auth_client):
        resp = auth_client.get("/api/v1/services/999")
        assert resp.status_code == 404

class TestServiceUpdate:
    def test_update_service_success(self, auth_client, db_session, test_user):
        s = _seed_service(db_session, test_user.id, name="Old Name")
        payload = {
            "name": "New Name",
            "sellingPrice": 200.0
        }
        resp = auth_client.put(f"/api/v1/services/{s.id}", json=payload)
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["name"] == "New Name"
        assert data["sellingPrice"] == 200.0

    def test_update_service_not_found(self, auth_client):
        payload = {"name": "No Body"}
        resp = auth_client.put("/api/v1/services/999", json=payload)
        assert resp.status_code == 404

class TestServiceDelete:
    def test_delete_service_success(self, auth_client, db_session, test_user):
        s = _seed_service(db_session, test_user.id)
        resp = auth_client.delete(f"/api/v1/services/{s.id}")
        assert resp.status_code == 200
        assert resp.json()["message"] == "Service deleted successfully"

        # verify no longer accessible
        resp_get = auth_client.get(f"/api/v1/services/{s.id}")
        assert resp_get.status_code == 404

    def test_delete_service_not_found(self, auth_client):
        resp = auth_client.delete("/api/v1/services/999")
        assert resp.status_code == 404

class TestServiceUserOwnership:
    def test_user_cannot_access_other_user_service(self, auth_client, db_session):
        other_user = User(
            username="otheruser",
            email="other@example.com",
            hashed_password=hash_password("password123"),
        )
        db_session.add(other_user)
        db_session.commit()
        db_session.refresh(other_user)

        s = _seed_service(db_session, other_user.id, name="Other Service")

        resp_list = auth_client.get("/api/v1/services")
        assert resp_list.json()["data"] == []

        resp_get = auth_client.get(f"/api/v1/services/{s.id}")
        assert resp_get.status_code == 404

        resp_put = auth_client.put(f"/api/v1/services/{s.id}", json={"name": "Hacked"})
        assert resp_put.status_code == 404

        resp_del = auth_client.delete(f"/api/v1/services/{s.id}")
        assert resp_del.status_code == 404
