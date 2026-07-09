"""
test_salary_routes.py — Integration tests for all Salary CRUD endpoints.

Endpoints under test:
  POST   /api/v1/salary/generate
  GET    /api/v1/salary/list
  GET    /api/v1/salary/{id}
  PUT    /api/v1/salary/{id}
  DELETE /api/v1/salary/{id}

All routes require JWT authentication. Tests use the `auth_client` fixture which
injects a valid Bearer token for a pre-seeded `test_user`.

Tests that need existing DB rows seed them via the ORM using `_seed_salary`.
Total salary recalculation on update is fully verified.
"""

import pytest

from models.db_models import Salary


# ---------------------------------------------------------------------------
# Helper — seed a salary directly in the DB
# ---------------------------------------------------------------------------

def _seed_salary(
    db_session,
    user,
    employee_name: str = "John Doe",
    base_salary: float = 50000.0,
    bonus: float = 5000.0,
) -> Salary:
    """Insert a Salary row with correct total and return it."""
    s = Salary(
        employee_name=employee_name,
        base_salary=base_salary,
        bonus=bonus,
        total_salary=base_salary + bonus,
        user_id=user.id,
    )
    db_session.add(s)
    db_session.commit()
    db_session.refresh(s)
    return s


# ---------------------------------------------------------------------------
# 1. POST /api/v1/salary/generate
# ---------------------------------------------------------------------------

class TestSalaryGenerate:

    def test_returns_200(self, auth_client):
        payload = {"employee_name": "Jane", "base_salary": 50000.0, "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.status_code == 200

    def test_success_flag_true(self, auth_client):
        payload = {"employee_name": "Jane", "base_salary": 50000.0, "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.json()["success"] is True

    def test_response_contains_id(self, auth_client):
        payload = {"employee_name": "Jane", "base_salary": 50000.0, "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert "id" in resp.json()["data"]

    def test_employee_name_persisted(self, auth_client):
        payload = {"employee_name": "Unique Name XYZ", "base_salary": 50000.0, "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.json()["data"]["employee_name"] == "Unique Name XYZ"

    def test_total_salary_calculated(self, auth_client):
        payload = {"employee_name": "Jane", "base_salary": 50000.0, "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert float(resp.json()["data"]["total_salary"]) == pytest.approx(55000.0)

    def test_total_salary_with_zero_bonus(self, auth_client):
        payload = {"employee_name": "Jane", "base_salary": 50000.0, "bonus": 0.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert float(resp.json()["data"]["total_salary"]) == pytest.approx(50000.0)

    def test_missing_employee_name_returns_422(self, auth_client):
        payload = {"base_salary": 50000.0, "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.status_code == 422

    def test_missing_base_salary_returns_422(self, auth_client):
        payload = {"employee_name": "Test", "bonus": 5000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.status_code == 422

    def test_missing_bonus_returns_422(self, auth_client):
        payload = {"employee_name": "Test", "base_salary": 50000.0}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.status_code == 422

    def test_validation_error_success_flag_false(self, auth_client):
        payload = {"employee_name": "Test"}
        resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert resp.json()["success"] is False

    def test_empty_body_returns_422(self, auth_client):
        resp = auth_client.post("/api/v1/salary/generate", json={})
        assert resp.status_code == 422


# ---------------------------------------------------------------------------
# 2. GET /api/v1/salary/list
# ---------------------------------------------------------------------------

class TestSalaryList:

    def test_empty_list_returns_200(self, auth_client):
        resp = auth_client.get("/api/v1/salary/list")
        assert resp.status_code == 200

    def test_empty_db_returns_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/salary/list")
        assert resp.json()["data"] == []

    def test_single_salary_appears_in_list(self, auth_client, db_session, test_user):
        _seed_salary(db_session, test_user)
        resp = auth_client.get("/api/v1/salary/list")
        assert len(resp.json()["data"]) == 1

    def test_multiple_salaries_appear_in_list(self, auth_client, db_session, test_user):
        for i in range(3):
            _seed_salary(db_session, test_user, employee_name=f"Employee {i}")
        resp = auth_client.get("/api/v1/salary/list")
        assert len(resp.json()["data"]) == 3

    def test_list_items_have_required_fields(self, auth_client, db_session, test_user):
        _seed_salary(db_session, test_user)
        resp = auth_client.get("/api/v1/salary/list")
        item = resp.json()["data"][0]
        for field in ("id", "employee_name", "base_salary", "bonus", "total_salary"):
            assert field in item, f"Missing field: {field}"

    def test_success_flag_in_list_response(self, auth_client):
        resp = auth_client.get("/api/v1/salary/list")
        assert resp.json()["success"] is True


# ---------------------------------------------------------------------------
# 3. GET /api/v1/salary/{id}
# ---------------------------------------------------------------------------

class TestSalaryGetById:

    def test_existing_salary_returns_200(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        assert resp.status_code == 200

    def test_returns_correct_salary(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, employee_name="Unique Employee XYZ")
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        assert resp.json()["data"]["employee_name"] == "Unique Employee XYZ"

    def test_returns_correct_id(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        assert resp.json()["data"]["id"] == s.id

    def test_total_matches_base_plus_bonus(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, base_salary=40000, bonus=6000)
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        data = resp.json()["data"]
        assert float(data["total_salary"]) == pytest.approx(
            float(data["base_salary"]) + float(data["bonus"])
        )

    def test_nonexistent_id_returns_404(self, auth_client):
        resp = auth_client.get("/api/v1/salary/99999")
        assert resp.status_code == 404

    def test_404_success_flag_false(self, auth_client):
        resp = auth_client.get("/api/v1/salary/99999")
        assert resp.json()["success"] is False


# ---------------------------------------------------------------------------
# 4. PUT /api/v1/salary/{id}
# ---------------------------------------------------------------------------

class TestSalaryUpdate:

    def test_update_name_returns_200(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        resp = auth_client.put(f"/api/v1/salary/{s.id}", json={"employee_name": "Updated"})
        assert resp.status_code == 200

    def test_employee_name_updated_in_response(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, employee_name="Old Name")
        resp = auth_client.put(f"/api/v1/salary/{s.id}", json={"employee_name": "New Name"})
        assert resp.json()["data"]["employee_name"] == "New Name"

    def test_base_salary_updated_and_total_recalculated(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, base_salary=50000, bonus=5000)
        resp = auth_client.put(f"/api/v1/salary/{s.id}", json={"base_salary": 60000.0})
        data = resp.json()["data"]
        assert float(data["base_salary"]) == pytest.approx(60000.0)
        assert float(data["total_salary"]) == pytest.approx(65000.0)

    def test_bonus_updated_and_total_recalculated(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, base_salary=50000, bonus=5000)
        resp = auth_client.put(f"/api/v1/salary/{s.id}", json={"bonus": 10000.0})
        data = resp.json()["data"]
        assert float(data["bonus"]) == pytest.approx(10000.0)
        assert float(data["total_salary"]) == pytest.approx(60000.0)

    def test_both_updated_and_total_recalculated(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, base_salary=30000, bonus=2000)
        resp = auth_client.put(
            f"/api/v1/salary/{s.id}",
            json={"base_salary": 70000.0, "bonus": 15000.0},
        )
        data = resp.json()["data"]
        assert float(data["total_salary"]) == pytest.approx(85000.0)

    def test_partial_update_preserves_other_fields(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, employee_name="Preserve Me", base_salary=40000, bonus=4000)
        auth_client.put(f"/api/v1/salary/{s.id}", json={"bonus": 8000.0})
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        data = resp.json()["data"]
        assert data["employee_name"] == "Preserve Me"
        assert float(data["base_salary"]) == pytest.approx(40000.0)
        assert float(data["bonus"]) == pytest.approx(8000.0)

    def test_update_persists_to_db(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, employee_name="Before")
        auth_client.put(f"/api/v1/salary/{s.id}", json={"employee_name": "After"})
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        assert resp.json()["data"]["employee_name"] == "After"

    def test_update_nonexistent_returns_404(self, auth_client):
        resp = auth_client.put("/api/v1/salary/99999", json={"bonus": 5000.0})
        assert resp.status_code == 404

    def test_success_flag_on_update(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        resp = auth_client.put(f"/api/v1/salary/{s.id}", json={"bonus": 9000.0})
        assert resp.json()["success"] is True


# ---------------------------------------------------------------------------
# 5. DELETE /api/v1/salary/{id}
# ---------------------------------------------------------------------------

class TestSalaryDelete:

    def test_delete_existing_returns_200(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        resp = auth_client.delete(f"/api/v1/salary/{s.id}")
        assert resp.status_code == 200

    def test_delete_success_flag_true(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        resp = auth_client.delete(f"/api/v1/salary/{s.id}")
        assert resp.json()["success"] is True

    def test_deleted_record_not_fetchable(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user)
        auth_client.delete(f"/api/v1/salary/{s.id}")
        resp = auth_client.get(f"/api/v1/salary/{s.id}")
        assert resp.status_code == 404

    def test_deleted_record_absent_from_list(self, auth_client, db_session, test_user):
        s = _seed_salary(db_session, test_user, employee_name="To Be Deleted")
        auth_client.delete(f"/api/v1/salary/{s.id}")
        resp = auth_client.get("/api/v1/salary/list")
        ids = [item["id"] for item in resp.json()["data"]]
        assert s.id not in ids

    def test_delete_nonexistent_returns_404(self, auth_client):
        resp = auth_client.delete("/api/v1/salary/99999")
        assert resp.status_code == 404

    def test_delete_nonexistent_success_false(self, auth_client):
        resp = auth_client.delete("/api/v1/salary/99999")
        assert resp.json()["success"] is False

    def test_other_salaries_unaffected_after_delete(self, auth_client, db_session, test_user):
        s1 = _seed_salary(db_session, test_user, employee_name="Keep Me")
        s2 = _seed_salary(db_session, test_user, employee_name="Delete Me")
        auth_client.delete(f"/api/v1/salary/{s2.id}")
        resp = auth_client.get(f"/api/v1/salary/{s1.id}")
        assert resp.status_code == 200
        assert resp.json()["data"]["employee_name"] == "Keep Me"


# ---------------------------------------------------------------------------
# 6. Full lifecycle
# ---------------------------------------------------------------------------

class TestSalaryCRUDLifecycle:

    def test_full_lifecycle(self, auth_client):
        # Create via API
        payload = {"employee_name": "Lifecycle Employee", "base_salary": 50000.0, "bonus": 5000.0}
        create_resp = auth_client.post("/api/v1/salary/generate", json=payload)
        assert create_resp.status_code == 200
        s_id = create_resp.json()["data"]["id"]
        assert float(create_resp.json()["data"]["total_salary"]) == pytest.approx(55000.0)

        # Read back
        get_resp = auth_client.get(f"/api/v1/salary/{s_id}")
        assert get_resp.status_code == 200
        assert get_resp.json()["data"]["employee_name"] == "Lifecycle Employee"

        # Appears in list
        list_resp = auth_client.get("/api/v1/salary/list")
        assert any(item["id"] == s_id for item in list_resp.json()["data"])

        # Update with recalculation
        update_resp = auth_client.put(
            f"/api/v1/salary/{s_id}",
            json={"base_salary": 60000.0, "bonus": 10000.0},
        )
        assert update_resp.status_code == 200
        assert float(update_resp.json()["data"]["total_salary"]) == pytest.approx(70000.0)

        # Delete
        delete_resp = auth_client.delete(f"/api/v1/salary/{s_id}")
        assert delete_resp.status_code == 200

        # Verify deleted
        final_resp = auth_client.get(f"/api/v1/salary/{s_id}")
        assert final_resp.status_code == 404
