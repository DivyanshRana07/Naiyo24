import httpx
import time
import sys

def run_tests():
    base_url = "http://127.0.0.1:8000"
    client = httpx.Client(base_url=base_url)

    print("1. Checking /health")
    try:
        r = client.get("/health")
        print(f"Health Status: {r.status_code}")
        print(f"Health Response: {r.json()}")
        assert r.status_code == 200
    except Exception as e:
        print(f"Failed to connect to health endpoint: {e}")
        sys.exit(1)

    print("\n2. Registering a test user")
    user_data = {"username": f"demouser_{int(time.time())}", "email": f"demo_{int(time.time())}@example.com", "password": "password123"}
    r = client.post("/api/v1/auth/register", json=user_data)
    print(f"Register Status: {r.status_code}")
    print(f"Register Response: {r.json()}")

    print("\n3. Logging in")
    login_data = {"username": user_data["username"], "password": "password123"}
    r = client.post("/api/v1/auth/login", data=login_data) # Uses form data for OAuth2
    print(f"Login Status: {r.status_code}")
    token_data = r.json()
    print(f"Token received: {'access_token' in token_data}")
    
    token = token_data.get("access_token")
    if not token:
        print("Failed to get token!")
        sys.exit(1)

    print("\n4. Testing Expense API (Auth required)")
    headers = {"Authorization": f"Bearer {token}"}
    expense_data = {
        "title": "Server Verification Expense",
        "amount": 100.50,
        "category": "Testing",
        "expense_date": "2026-06-12"
    }
    r = client.post("/api/v1/expenses/add", json=expense_data, headers=headers)
    print(f"Add Expense Status: {r.status_code}")
    print(f"Add Expense Response: {r.json()}")

    print("\n5. Testing Validation Error (Logging & Exception Handling)")
    bad_expense_data = {
        "amount": "not_a_number" # This should trigger a 422
    }
    r = client.post("/api/v1/expenses/add", json=bad_expense_data, headers=headers)
    print(f"Bad Request Status: {r.status_code} (Expected 422)")
    print(f"Bad Request Response: {r.json()}")

if __name__ == "__main__":
    run_tests()
