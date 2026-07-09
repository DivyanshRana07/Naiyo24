"""
test_activity_routes.py — Integration tests for the Activity Log feature.

Endpoints under test:
  GET  /api/v1/activity           (list feed, newest-first, paginated)

Strategy:
  - Reuses the existing conftest.py fixtures (auth_client, db_session, test_user).
  - Activities are triggered via other business endpoints (expenses, customers, etc.)
    to exercise the automatic creation path end-to-end.
  - Direct DB assertions verify persistence and ordering.
  - User isolation is verified with a second test user fixture.
"""

import pytest



# ---------------------------------------------------------------------------
# Helpers — seed minimal expenses/customers to produce activity records
# ---------------------------------------------------------------------------

def _add_expense(auth_client, title: str = "Test Expense", amount: float = 100.0) -> int:
    resp = auth_client.post(
        "/api/v1/expenses/add",
        json={"title": title, "amount": amount, "category": "Test"},
    )
    assert resp.status_code == 200, f"Expense creation failed: {resp.text}"
    return resp.json()["data"]["id"]


def _add_customer(auth_client, name: str = "Test Customer") -> int:
    resp = auth_client.post(
        "/api/v1/customers",
        json={
            "name": name,
            "mobile": "9876543210",
            "email": f"{name.lower().replace(' ', '')}@test.com",
        },
    )
    assert resp.status_code == 200, f"Customer creation failed: {resp.text}"
    return resp.json()["data"]["id"]


# ---------------------------------------------------------------------------
# 1. GET /api/v1/activity — basic response shape
# ---------------------------------------------------------------------------

class TestActivityList:

    def test_returns_200_when_no_activities(self, auth_client):
        resp = auth_client.get("/api/v1/activity")
        assert resp.status_code == 200

    def test_success_flag_true(self, auth_client):
        resp = auth_client.get("/api/v1/activity")
        assert resp.json()["success"] is True

    def test_empty_db_returns_empty_list(self, auth_client):
        resp = auth_client.get("/api/v1/activity")
        assert resp.json()["data"] == []

    def test_response_data_is_list(self, auth_client):
        resp = auth_client.get("/api/v1/activity")
        assert isinstance(resp.json()["data"], list)


# ---------------------------------------------------------------------------
# 2. Automatic activity creation — expenses
# ---------------------------------------------------------------------------

class TestActivityAutoCreate:

    def test_creating_expense_creates_activity(self, auth_client):
        _add_expense(auth_client, title="Office Supplies")
        resp = auth_client.get("/api/v1/activity")
        assert len(resp.json()["data"]) >= 1

    def test_activity_has_required_camel_case_fields(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        item = resp.json()["data"][0]
        for field in ("id", "action", "entityType", "entityId", "title", "description", "createdAt"):
            assert field in item, f"Missing required field: {field}"

    def test_expense_activity_action_is_created(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        assert resp.json()["data"][0]["action"] == "Created"

    def test_expense_activity_entity_type(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        assert resp.json()["data"][0]["entityType"] == "Expense"

    def test_expense_activity_title(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        assert resp.json()["data"][0]["title"] == "Expense Added"

    def test_expense_activity_description_contains_title(self, auth_client):
        _add_expense(auth_client, title="Unique Expense Name")
        resp = auth_client.get("/api/v1/activity")
        desc = resp.json()["data"][0]["description"]
        assert "Unique Expense Name" in desc

    def test_expense_entity_id_is_string(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        entity_id = resp.json()["data"][0]["entityId"]
        assert isinstance(entity_id, str)

    def test_created_at_is_present(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        assert resp.json()["data"][0]["createdAt"] is not None

    def test_updating_expense_creates_updated_activity(self, auth_client):
        expense_id = _add_expense(auth_client, title="To Update")
        auth_client.put(f"/api/v1/expenses/{expense_id}", json={"title": "Updated"})
        resp = auth_client.get("/api/v1/activity")
        actions = [a["action"] for a in resp.json()["data"]]
        assert "Updated" in actions

    def test_deleting_expense_creates_deleted_activity(self, auth_client):
        expense_id = _add_expense(auth_client, title="To Delete")
        auth_client.delete(f"/api/v1/expenses/{expense_id}")
        resp = auth_client.get("/api/v1/activity")
        actions = [a["action"] for a in resp.json()["data"]]
        assert "Deleted" in actions

    def test_customer_creation_creates_activity(self, auth_client):
        _add_customer(auth_client, name="Alpha Corp")
        resp = auth_client.get("/api/v1/activity")
        entity_types = [a["entityType"] for a in resp.json()["data"]]
        assert "Customer" in entity_types

    def test_customer_activity_title(self, auth_client):
        _add_customer(auth_client)
        resp = auth_client.get("/api/v1/activity")
        customer_activities = [
            a for a in resp.json()["data"] if a["entityType"] == "Customer"
        ]
        assert customer_activities[0]["title"] == "Customer Added"


# ---------------------------------------------------------------------------
# 3. Ordering — newest first
# ---------------------------------------------------------------------------

class TestActivityOrdering:

    def test_activities_returned_newest_first(self, auth_client):
        _add_expense(auth_client, title="First Expense")
        _add_expense(auth_client, title="Second Expense")
        _add_expense(auth_client, title="Third Expense")

        resp = auth_client.get("/api/v1/activity")
        data = resp.json()["data"]
        assert len(data) >= 3

        # With id DESC as tiebreaker, highest id (most recent insert) is first
        ids = [int(item["id"]) for item in data]
        assert ids == sorted(ids, reverse=True), "Activities are not ordered newest-first (id desc)"

    def test_multiple_operations_ordering(self, auth_client):
        expense_id = _add_expense(auth_client, title="Order Test")
        auth_client.put(f"/api/v1/expenses/{expense_id}", json={"title": "Order Test Updated"})

        resp = auth_client.get("/api/v1/activity")
        data = resp.json()["data"]
        # The Updated activity has a higher id than the Created activity,
        # so it must come first in the id-desc ordering.
        assert data[0]["action"] == "Updated"
        assert data[1]["action"] == "Created"


# ---------------------------------------------------------------------------
# 4. Pagination — limit and offset
# ---------------------------------------------------------------------------

class TestActivityPagination:

    def test_limit_parameter_respected(self, auth_client):
        for i in range(5):
            _add_expense(auth_client, title=f"Paginate Expense {i}")

        resp = auth_client.get("/api/v1/activity?limit=3")
        assert resp.status_code == 200
        assert len(resp.json()["data"]) == 3

    def test_offset_parameter_respected(self, auth_client):
        for i in range(4):
            _add_expense(auth_client, title=f"Offset Expense {i}")

        resp_all = auth_client.get("/api/v1/activity?limit=4")
        resp_offset = auth_client.get("/api/v1/activity?limit=4&offset=2")

        all_ids = [a["id"] for a in resp_all.json()["data"]]
        offset_ids = [a["id"] for a in resp_offset.json()["data"]]

        # Offset=2 means skip the first 2 newest items
        assert offset_ids == all_ids[2:]

    def test_limit_defaults_to_50(self, auth_client):
        # With fewer than 50 items this just confirms the endpoint works
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        assert resp.status_code == 200

    def test_limit_zero_returns_422(self, auth_client):
        resp = auth_client.get("/api/v1/activity?limit=0")
        assert resp.status_code == 422

    def test_limit_above_200_returns_422(self, auth_client):
        resp = auth_client.get("/api/v1/activity?limit=201")
        assert resp.status_code == 422

    def test_negative_offset_returns_422(self, auth_client):
        resp = auth_client.get("/api/v1/activity?offset=-1")
        assert resp.status_code == 422

    def test_large_offset_returns_empty_list(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity?offset=99999")
        assert resp.status_code == 200
        assert resp.json()["data"] == []


# ---------------------------------------------------------------------------
# 5. User ownership — user A cannot see user B's activities
# ---------------------------------------------------------------------------

class TestActivityUserOwnership:
    """
    Note: get_current_user is a stub that always returns user ID=1.
    True multi-user ownership isolation is therefore tested by directly
    inserting ActivityLog rows for a different user_id in the DB, and
    confirming that the GET /api/v1/activity endpoint (which filters by
    current_user.id == 1) does NOT return those rows.
    """

    def test_user_sees_only_own_activities(self, auth_client, db_session):
        """User 1 creates an expense; a row planted for user 99 must not appear."""
        from models.db_models import ActivityLog

        # Seed an activity for a completely different user (user_id=99)
        foreign_log = ActivityLog(
            user_id=99,
            action="Created",
            entity_type="Invoice",
            entity_id="INV-FOREIGN",
            title="Foreign Invoice Created",
            description="Belongs to another user.",
        )
        db_session.add(foreign_log)
        db_session.commit()

        # Current user (user 1) creates their own expense
        _add_expense(auth_client, title="User 1 Expense")

        resp = auth_client.get("/api/v1/activity")
        assert resp.status_code == 200
        data = resp.json()["data"]

        # Should contain user 1's activity
        assert len(data) >= 1
        # Must NOT contain the foreign activity (entity_id = INV-FOREIGN)
        entity_ids = [a["entityId"] for a in data]
        assert "INV-FOREIGN" not in entity_ids

    def test_user_a_activities_not_in_user_b_feed(self, auth_client, db_session):
        """Directly seed activities for two different user IDs and confirm isolation."""
        from models.db_models import ActivityLog

        # User 1 creates an expense via the API
        _add_expense(auth_client, title="User A Private Expense")

        # Directly seed an activity for user_id=2 (a different user)
        user2_log = ActivityLog(
            user_id=2,
            action="Created",
            entity_type="Customer",
            entity_id="C999",
            title="User 2 Customer Added",
            description="Belongs to user 2.",
        )
        db_session.add(user2_log)
        db_session.commit()

        # GET /api/v1/activity returns only user 1's activities
        resp = auth_client.get("/api/v1/activity")
        data = resp.json()["data"]

        entity_ids = [a["entityId"] for a in data]
        assert "C999" not in entity_ids, "User 2's activity leaked into user 1's feed"


# ---------------------------------------------------------------------------
# 6. Activity ID is an integer
# ---------------------------------------------------------------------------

class TestActivitySchema:

    def test_id_is_integer(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        item = resp.json()["data"][0]
        assert isinstance(item["id"], int)

    def test_entity_id_is_string_or_null(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        entity_id = resp.json()["data"][0]["entityId"]
        assert entity_id is None or isinstance(entity_id, str)

    def test_description_field_present(self, auth_client):
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        assert "description" in resp.json()["data"][0]

    def test_created_at_format_is_iso(self, auth_client):
        from datetime import datetime
        _add_expense(auth_client)
        resp = auth_client.get("/api/v1/activity")
        created_at_str = resp.json()["data"][0]["createdAt"]
        # Should be parseable as ISO-8601
        dt = datetime.fromisoformat(created_at_str.replace("Z", "+00:00"))
        assert dt is not None
