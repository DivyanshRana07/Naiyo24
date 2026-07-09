"""
test_expense_routes.py — Integration tests for all Expense CRUD endpoints.

Endpoints under test:
  POST   /api/v1/expenses/add
  GET    /api/v1/expenses/list
  GET    /api/v1/expenses/{id}
  PUT    /api/v1/expenses/{id}
  DELETE /api/v1/expenses/{id}

Strategy:
  - Full CRUD lifecycle tested end-to-end.
  - DB state verified after each mutating operation.
  - Both success and failure paths covered.
"""

import pytest

# ---------------------------------------------------------------------------
# Payload factory
# ---------------------------------------------------------------------------

def _expense(
    title: str = "Office Supplies",
    amount: float = 500.00,
    category: str = "Office",
    expense_date: str = "2024-01-15",
) -> dict:
    return {
        "title": title,
        "amount": amount,
        "category": category,
        "expense_date": expense_date,
    }


# ---------------------------------------------------------------------------
# Helper — create an expense and return its id
# ---------------------------------------------------------------------------

def _create_expense(auth_client, **kwargs) -> int:
    resp = auth_client.post("/api/v1/expenses/add", json=_expense(**kwargs))
    assert resp.status_code == 200, f"Setup failed: {resp.text}"
    return resp.json()["data"]["id"]


# ---------------------------------------------------------------------------
# 1. POST /api/v1/expenses/add
# ---------------------------------------------------------------------------

class TestExpenseAdd:

    def test_returns_200(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense())
        assert resp.status_code == 200

    def test_success_flag_true(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense())
        assert resp.json()["success"] is True

    def test_message_in_response(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense())
        assert "message" in resp.json()

    def test_response_contains_id(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense())
        assert "id" in resp.json()["data"]

    def test_title_persisted(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense(title="Travel Ticket"))
        assert resp.json()["data"]["title"] == "Travel Ticket"

    def test_amount_persisted(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense(amount=999.99))
        assert float(resp.json()["data"]["amount"]) == pytest.approx(999.99)

    def test_category_persisted(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense(category="Travel"))
        assert resp.json()["data"]["category"] == "Travel"

    def test_expense_date_persisted(self, auth_client):
        resp = auth_client.post("/api/v1/expenses/add", json=_expense(expense_date="2024-03-20"))
        assert resp.json()["data"]["expense_date"] == "2024-03-20"

    def test_id_auto_increments(self, auth_client):
        id1 = _create_expense(auth_client, title="First")
        id2 = _create_expense(auth_client, title="Second")
        assert id2 > id1

    def test_missing_title_returns_422(self, auth_client):
        payload = _expense()
        del payload["title"]
        resp = auth_client.post("/api/v1/expenses/add", json=payload)
        assert resp.status_code == 422

    def test_missing_amount_returns_422(self, auth_client):
        payload = _expense()
        del payload["amount"]
        resp = auth_client.post("/api/v1/expenses/add", json=payload)
        assert resp.status_code == 422

    def test_string_amount_returns_422(self, auth_client):
        payload = _expense()
        payload["amount"] = "not-a-number"
        resp = auth_client.post("/api/v1/expenses/add", json=payload)
        assert resp.status_code == 422

    def test_validation_error_success_flag_false(self, auth_client):
        payload = _expense()
        del payload["title"]
        resp = auth_client.post("/api/v1/expenses/add", json=payload)
        assert resp.json()["success"] is False

    def test_optional_category_absent(self, auth_client):
        payload = {"title": "Misc", "amount": 100.0}
        resp = auth_client.post("/api/v1/expenses/add", json=payload)
        assert resp.status_code == 200

    def test_optional_date_absent(self, auth_client):
        payload = {"title": "Misc", "amount": 100.0}
        resp = auth_client.post("/api/v1/expenses/add", json=payload)
        assert resp.status_code == 200


# ---------------------------------------------------------------------------
# 2. GET /api/v1/expenses/list
# ---------------------------------------------------------------------------

class TestExpenseList:

    def test_empty_list_returns_200(self, auth_client):
        resp = auth_client.get("/api/v1/expenses/list")
        assert resp.status_code == 200

    def test_empty_db_returns_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/expenses/list")
        assert resp.json()["data"] == []

    def test_single_expense_appears_in_list(self, auth_client):
        _create_expense(auth_client, title="Rent")
        resp = auth_client.get("/api/v1/expenses/list")
        assert len(resp.json()["data"]) == 1

    def test_multiple_expenses_appear_in_list(self, auth_client):
        for i in range(3):
            _create_expense(auth_client, title=f"Expense {i}")
        resp = auth_client.get("/api/v1/expenses/list")
        assert len(resp.json()["data"]) == 3

    def test_list_items_have_required_fields(self, auth_client):
        _create_expense(auth_client)
        resp = auth_client.get("/api/v1/expenses/list")
        item = resp.json()["data"][0]
        for field in ("id", "title", "amount"):
            assert field in item, f"Missing field: {field}"

    def test_success_flag_in_list_response(self, auth_client):
        resp = auth_client.get("/api/v1/expenses/list")
        assert resp.json()["success"] is True


# ---------------------------------------------------------------------------
# 3. GET /api/v1/expenses/{id}
# ---------------------------------------------------------------------------

class TestExpenseGetById:

    def test_existing_expense_returns_200(self, auth_client):
        expense_id = _create_expense(auth_client)
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.status_code == 200

    def test_returns_correct_expense(self, auth_client):
        expense_id = _create_expense(auth_client, title="Unique Title XYZ")
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.json()["data"]["title"] == "Unique Title XYZ"

    def test_returns_correct_id(self, auth_client):
        expense_id = _create_expense(auth_client)
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.json()["data"]["id"] == expense_id

    def test_nonexistent_id_returns_404(self, auth_client):
        resp = auth_client.get("/api/v1/expenses/99999")
        assert resp.status_code == 404

    def test_404_success_flag_false(self, auth_client):
        resp = auth_client.get("/api/v1/expenses/99999")
        assert resp.json()["success"] is False

    def test_get_is_isolated_between_tests(self, auth_client):
        # Only one expense was created in THIS test — id is fresh
        expense_id = _create_expense(auth_client, title="Isolated")
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.status_code == 200


# ---------------------------------------------------------------------------
# 4. PUT /api/v1/expenses/{id}
# ---------------------------------------------------------------------------

class TestExpenseUpdate:

    def test_update_title_returns_200(self, auth_client):
        expense_id = _create_expense(auth_client)
        resp = auth_client.put(f"/api/v1/expenses/{expense_id}", json={"title": "Updated Title"})
        assert resp.status_code == 200

    def test_title_updated_in_response(self, auth_client):
        expense_id = _create_expense(auth_client, title="Old Title")
        resp = auth_client.put(f"/api/v1/expenses/{expense_id}", json={"title": "New Title"})
        assert resp.json()["data"]["title"] == "New Title"

    def test_amount_updated_in_response(self, auth_client):
        expense_id = _create_expense(auth_client, amount=100.0)
        resp = auth_client.put(f"/api/v1/expenses/{expense_id}", json={"amount": 750.50})
        assert float(resp.json()["data"]["amount"]) == pytest.approx(750.50)

    def test_partial_update_preserves_other_fields(self, auth_client):
        expense_id = _create_expense(auth_client, title="Preserve Me", amount=200.0, category="Travel")
        # Only update amount — title and category should remain unchanged
        auth_client.put(f"/api/v1/expenses/{expense_id}", json={"amount": 300.0})
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        data = resp.json()["data"]
        assert data["title"] == "Preserve Me"
        assert data["category"] == "Travel"
        assert float(data["amount"]) == pytest.approx(300.0)

    def test_update_persists_to_db(self, auth_client):
        expense_id = _create_expense(auth_client, title="Before")
        auth_client.put(f"/api/v1/expenses/{expense_id}", json={"title": "After"})
        # Re-fetch from DB via GET
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.json()["data"]["title"] == "After"

    def test_update_nonexistent_returns_404(self, auth_client):
        resp = auth_client.put("/api/v1/expenses/99999", json={"title": "Ghost"})
        assert resp.status_code == 404

    def test_success_flag_on_update(self, auth_client):
        expense_id = _create_expense(auth_client)
        resp = auth_client.put(f"/api/v1/expenses/{expense_id}", json={"title": "Updated"})
        assert resp.json()["success"] is True

    def test_category_updated(self, auth_client):
        expense_id = _create_expense(auth_client, category="Office")
        auth_client.put(f"/api/v1/expenses/{expense_id}", json={"category": "Travel"})
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.json()["data"]["category"] == "Travel"


# ---------------------------------------------------------------------------
# 5. DELETE /api/v1/expenses/{id}
# ---------------------------------------------------------------------------

class TestExpenseDelete:

    def test_delete_existing_returns_200(self, auth_client):
        expense_id = _create_expense(auth_client)
        resp = auth_client.delete(f"/api/v1/expenses/{expense_id}")
        assert resp.status_code == 200

    def test_delete_success_flag_true(self, auth_client):
        expense_id = _create_expense(auth_client)
        resp = auth_client.delete(f"/api/v1/expenses/{expense_id}")
        assert resp.json()["success"] is True

    def test_deleted_record_not_fetchable(self, auth_client):
        expense_id = _create_expense(auth_client)
        auth_client.delete(f"/api/v1/expenses/{expense_id}")
        resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert resp.status_code == 404

    def test_deleted_record_absent_from_list(self, auth_client):
        expense_id = _create_expense(auth_client, title="To Be Deleted")
        auth_client.delete(f"/api/v1/expenses/{expense_id}")
        resp = auth_client.get("/api/v1/expenses/list")
        ids = [e["id"] for e in resp.json()["data"]]
        assert expense_id not in ids

    def test_delete_nonexistent_returns_404(self, auth_client):
        resp = auth_client.delete("/api/v1/expenses/99999")
        assert resp.status_code == 404

    def test_delete_nonexistent_success_false(self, auth_client):
        resp = auth_client.delete("/api/v1/expenses/99999")
        assert resp.json()["success"] is False

    def test_other_expenses_unaffected_after_delete(self, auth_client):
        id1 = _create_expense(auth_client, title="Keep Me")
        id2 = _create_expense(auth_client, title="Delete Me")
        auth_client.delete(f"/api/v1/expenses/{id2}")
        resp = auth_client.get(f"/api/v1/expenses/{id1}")
        assert resp.status_code == 200
        assert resp.json()["data"]["title"] == "Keep Me"


# ---------------------------------------------------------------------------
# 6. Full CRUD lifecycle test
# ---------------------------------------------------------------------------

class TestExpenseCRUDLifecycle:
    """
    End-to-end test: create → read → list → update → verify → delete → verify.
    Demonstrates the complete lifecycle in a single test.
    """

    def test_full_lifecycle(self, auth_client):
        # STEP 1: Create
        create_resp = auth_client.post("/api/v1/expenses/add", json=_expense(title="Lifecycle Expense", amount=250.0))
        assert create_resp.status_code == 200
        expense_id = create_resp.json()["data"]["id"]

        # STEP 2: Read back by ID
        get_resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert get_resp.status_code == 200
        assert get_resp.json()["data"]["title"] == "Lifecycle Expense"

        # STEP 3: Appears in list
        list_resp = auth_client.get("/api/v1/expenses/list")
        assert any(e["id"] == expense_id for e in list_resp.json()["data"])

        # STEP 4: Update
        update_resp = auth_client.put(f"/api/v1/expenses/{expense_id}", json={"amount": 500.0, "title": "Updated Expense"})
        assert update_resp.status_code == 200

        # STEP 5: Verify update persisted
        verify_resp = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert verify_resp.json()["data"]["title"] == "Updated Expense"
        assert float(verify_resp.json()["data"]["amount"]) == pytest.approx(500.0)

        # STEP 6: Delete
        delete_resp = auth_client.delete(f"/api/v1/expenses/{expense_id}")
        assert delete_resp.status_code == 200

        # STEP 7: Verify deleted
        final_get = auth_client.get(f"/api/v1/expenses/{expense_id}")
        assert final_get.status_code == 404
