"""
test_quotation_routes.py — Integration tests for all Quotation CRUD endpoints.

Endpoints under test:
  POST   /api/v1/quotation/create
  GET    /api/v1/quotation/list
  GET    /api/v1/quotation/{id}
  PUT    /api/v1/quotation/{id}
  DELETE /api/v1/quotation/{id}

All routes require JWT authentication. Tests use the `auth_client` fixture which
injects a valid Bearer token for a pre-seeded `test_user`.

Tests that need existing DB rows seed them via the ORM using `_seed_quotation`.
"""

import pytest

from models.db_models import Quotation, QuotationItem


# ---------------------------------------------------------------------------
# Helper — seed a quotation directly in the DB
# ---------------------------------------------------------------------------

def _seed_quotation(
    db_session,
    user,
    client_name: str = "Test Client Pvt Ltd",
    total: float = 5000.0,
    status: str = "Draft",
    items: list[dict] | None = None,
) -> Quotation:
    """Insert a Quotation (with optional items) and return it."""
    q = Quotation(
        client_name=client_name,
        total=total,
        status=status,
        user_id=user.id,
    )
    db_session.add(q)
    db_session.flush()

    for it in (items or [{"name": "Default Item", "price": 1000.0, "quantity": 5}]):
        db_session.add(QuotationItem(
            quotation_id=q.id,
            name=it["name"],
            price=it["price"],
            quantity=it["quantity"],
        ))

    db_session.commit()
    db_session.refresh(q)
    return q


# ---------------------------------------------------------------------------
# 1. POST /api/v1/quotation/create
# ---------------------------------------------------------------------------

class TestQuotationCreate:

    def test_returns_200(self, auth_client):
        payload = {
            "client_name": "Test Client",
            "items": [{"name": "Widget", "price": 100.0, "quantity": 5}],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.status_code == 200

    def test_success_flag_true(self, auth_client):
        payload = {
            "client_name": "Test Client",
            "items": [{"name": "Widget", "price": 100.0, "quantity": 5}],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.json()["success"] is True

    def test_response_contains_id(self, auth_client):
        payload = {
            "client_name": "Test Client",
            "items": [{"name": "Widget", "price": 100.0, "quantity": 5}],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert "id" in resp.json()["data"]

    def test_client_name_persisted(self, auth_client):
        payload = {
            "client_name": "Unique Client ABC",
            "items": [{"name": "Widget", "price": 100.0, "quantity": 5}],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.json()["data"]["client_name"] == "Unique Client ABC"

    def test_total_calculated_single_item(self, auth_client):
        payload = {
            "client_name": "Test",
            "items": [{"name": "Widget", "price": 200.0, "quantity": 3}],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert float(resp.json()["data"]["total"]) == pytest.approx(600.0)

    def test_total_calculated_multiple_items(self, auth_client):
        payload = {
            "client_name": "Test",
            "items": [
                {"name": "A", "price": 100.0, "quantity": 2},
                {"name": "B", "price": 50.0, "quantity": 4},
            ],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        # 100*2 + 50*4 = 400
        assert float(resp.json()["data"]["total"]) == pytest.approx(400.0)

    def test_default_status_is_draft(self, auth_client):
        payload = {
            "client_name": "Test",
            "items": [{"name": "Widget", "price": 100.0, "quantity": 1}],
        }
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.json()["data"]["status"] == "Draft"

    def test_missing_client_name_returns_422(self, auth_client):
        payload = {"items": [{"name": "X", "price": 10.0, "quantity": 1}]}
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.status_code == 422

    def test_missing_items_returns_422(self, auth_client):
        payload = {"client_name": "Test"}
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.status_code == 422

    def test_validation_error_success_flag_false(self, auth_client):
        payload = {"items": [{"name": "X", "price": 10.0, "quantity": 1}]}
        resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert resp.json()["success"] is False


# ---------------------------------------------------------------------------
# 2. GET /api/v1/quotation/list
# ---------------------------------------------------------------------------

class TestQuotationList:

    def test_empty_list_returns_200(self, auth_client):
        resp = auth_client.get("/api/v1/quotation/list")
        assert resp.status_code == 200

    def test_empty_db_returns_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/quotation/list")
        assert resp.json()["data"] == []

    def test_single_quotation_appears_in_list(self, auth_client, db_session, test_user):
        _seed_quotation(db_session, test_user)
        resp = auth_client.get("/api/v1/quotation/list")
        assert len(resp.json()["data"]) == 1

    def test_multiple_quotations_appear_in_list(self, auth_client, db_session, test_user):
        for i in range(3):
            _seed_quotation(db_session, test_user, client_name=f"Client {i}")
        resp = auth_client.get("/api/v1/quotation/list")
        assert len(resp.json()["data"]) == 3

    def test_list_items_have_required_fields(self, auth_client, db_session, test_user):
        _seed_quotation(db_session, test_user)
        resp = auth_client.get("/api/v1/quotation/list")
        item = resp.json()["data"][0]
        for field in ("id", "client_name", "total", "status"):
            assert field in item, f"Missing field: {field}"

    def test_success_flag_in_list_response(self, auth_client):
        resp = auth_client.get("/api/v1/quotation/list")
        assert resp.json()["success"] is True


# ---------------------------------------------------------------------------
# 3. GET /api/v1/quotation/{id}
# ---------------------------------------------------------------------------

class TestQuotationGetById:

    def test_existing_quotation_returns_200(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        assert resp.status_code == 200

    def test_returns_correct_quotation(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user, client_name="Unique Client XYZ")
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        assert resp.json()["data"]["client_name"] == "Unique Client XYZ"

    def test_returns_correct_id(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        assert resp.json()["data"]["id"] == q.id

    def test_nonexistent_id_returns_404(self, auth_client):
        resp = auth_client.get("/api/v1/quotation/99999")
        assert resp.status_code == 404

    def test_404_success_flag_false(self, auth_client):
        resp = auth_client.get("/api/v1/quotation/99999")
        assert resp.json()["success"] is False

    def test_get_includes_items(self, auth_client, db_session, test_user):
        items = [
            {"name": "Item A", "price": 100.0, "quantity": 2},
            {"name": "Item B", "price": 200.0, "quantity": 1},
        ]
        q = _seed_quotation(db_session, test_user, items=items, total=400.0)
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        assert len(resp.json()["data"]["items"]) == 2


# ---------------------------------------------------------------------------
# 4. PUT /api/v1/quotation/{id}
# ---------------------------------------------------------------------------

class TestQuotationUpdate:

    def test_update_status_returns_200(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        resp = auth_client.put(f"/api/v1/quotation/{q.id}", json={"status": "Sent"})
        assert resp.status_code == 200

    def test_status_updated_in_response(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user, status="Draft")
        resp = auth_client.put(f"/api/v1/quotation/{q.id}", json={"status": "Approved"})
        assert resp.json()["data"]["status"] == "Approved"

    def test_client_name_updated_in_response(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user, client_name="Old Name")
        resp = auth_client.put(f"/api/v1/quotation/{q.id}", json={"client_name": "New Name"})
        assert resp.json()["data"]["client_name"] == "New Name"

    def test_partial_update_preserves_other_fields(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user, client_name="Preserve Me", status="Draft")
        auth_client.put(f"/api/v1/quotation/{q.id}", json={"status": "Sent"})
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        data = resp.json()["data"]
        assert data["client_name"] == "Preserve Me"
        assert data["status"] == "Sent"

    def test_update_persists_to_db(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user, status="Draft")
        auth_client.put(f"/api/v1/quotation/{q.id}", json={"status": "Accepted"})
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        assert resp.json()["data"]["status"] == "Accepted"

    def test_update_nonexistent_returns_404(self, auth_client):
        resp = auth_client.put("/api/v1/quotation/99999", json={"status": "Sent"})
        assert resp.status_code == 404

    def test_success_flag_on_update(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        resp = auth_client.put(f"/api/v1/quotation/{q.id}", json={"status": "Sent"})
        assert resp.json()["success"] is True


# ---------------------------------------------------------------------------
# 5. DELETE /api/v1/quotation/{id}
# ---------------------------------------------------------------------------

class TestQuotationDelete:

    def test_delete_existing_returns_200(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        resp = auth_client.delete(f"/api/v1/quotation/{q.id}")
        assert resp.status_code == 200

    def test_delete_success_flag_true(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        resp = auth_client.delete(f"/api/v1/quotation/{q.id}")
        assert resp.json()["success"] is True

    def test_deleted_record_not_fetchable(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user)
        auth_client.delete(f"/api/v1/quotation/{q.id}")
        resp = auth_client.get(f"/api/v1/quotation/{q.id}")
        assert resp.status_code == 404

    def test_deleted_record_absent_from_list(self, auth_client, db_session, test_user):
        q = _seed_quotation(db_session, test_user, client_name="To Be Deleted")
        auth_client.delete(f"/api/v1/quotation/{q.id}")
        resp = auth_client.get("/api/v1/quotation/list")
        ids = [item["id"] for item in resp.json()["data"]]
        assert q.id not in ids

    def test_delete_nonexistent_returns_404(self, auth_client):
        resp = auth_client.delete("/api/v1/quotation/99999")
        assert resp.status_code == 404

    def test_delete_nonexistent_success_false(self, auth_client):
        resp = auth_client.delete("/api/v1/quotation/99999")
        assert resp.json()["success"] is False

    def test_other_quotations_unaffected_after_delete(self, auth_client, db_session, test_user):
        q1 = _seed_quotation(db_session, test_user, client_name="Keep Me")
        q2 = _seed_quotation(db_session, test_user, client_name="Delete Me")
        auth_client.delete(f"/api/v1/quotation/{q2.id}")
        resp = auth_client.get(f"/api/v1/quotation/{q1.id}")
        assert resp.status_code == 200
        assert resp.json()["data"]["client_name"] == "Keep Me"

    def test_cascade_deletes_quotation_items(self, auth_client, db_session, test_user):
        """Deleting a quotation must also remove its QuotationItem rows."""
        items = [
            {"name": "Item A", "price": 100.0, "quantity": 2},
            {"name": "Item B", "price": 200.0, "quantity": 1},
        ]
        q = _seed_quotation(db_session, test_user, items=items, total=400.0)
        q_id = q.id

        count_before = db_session.query(QuotationItem).filter(
            QuotationItem.quotation_id == q_id
        ).count()
        assert count_before == 2

        auth_client.delete(f"/api/v1/quotation/{q_id}")

        db_session.expire_all()
        count_after = db_session.query(QuotationItem).filter(
            QuotationItem.quotation_id == q_id
        ).count()
        assert count_after == 0


# ---------------------------------------------------------------------------
# 6. Full CRUD lifecycle
# ---------------------------------------------------------------------------

class TestQuotationCRUDLifecycle:

    def test_full_lifecycle(self, auth_client, db_session, test_user):
        # Create via API
        payload = {
            "client_name": "Lifecycle Client",
            "items": [{"name": "Service", "price": 500.0, "quantity": 2}],
        }
        create_resp = auth_client.post("/api/v1/quotation/create", json=payload)
        assert create_resp.status_code == 200
        q_id = create_resp.json()["data"]["id"]

        # Read back by ID
        get_resp = auth_client.get(f"/api/v1/quotation/{q_id}")
        assert get_resp.status_code == 200
        assert get_resp.json()["data"]["client_name"] == "Lifecycle Client"

        # Appears in list
        list_resp = auth_client.get("/api/v1/quotation/list")
        assert any(item["id"] == q_id for item in list_resp.json()["data"])

        # Update status
        update_resp = auth_client.put(
            f"/api/v1/quotation/{q_id}",
            json={"status": "Approved", "client_name": "Updated Client"},
        )
        assert update_resp.status_code == 200

        # Verify update persisted
        verify_resp = auth_client.get(f"/api/v1/quotation/{q_id}")
        assert verify_resp.json()["data"]["status"] == "Approved"
        assert verify_resp.json()["data"]["client_name"] == "Updated Client"

        # Delete
        delete_resp = auth_client.delete(f"/api/v1/quotation/{q_id}")
        assert delete_resp.status_code == 200

        # Verify deleted
        final_resp = auth_client.get(f"/api/v1/quotation/{q_id}")
        assert final_resp.status_code == 404
