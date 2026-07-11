# Invoice & Business Tools Backend

FastAPI backend for business utilities, focused on JWT authentication, GST invoice generation (JSON & PDF), expense tracking, client quotation generation, and salary management. 

Fully integrated with database persistence, relational schemas, validation middleware, and comprehensive unit tests.

---

## Features

- **User Authentication**: Secure JWT-based registration, login, and authorization. All business data is linked to specific users.
- **GST Invoice Generator**: Supports intra-state (CGST + SGST) and inter-state (IGST) tax calculation logic. Generates database-persisted invoices and renders premium downloadable PDF documents.
- **Customer Management**: Full CRUD operations for customer records with contact details and GST information.
- **Vendor Management**: Manage vendor records with contact persons and GST details.
- **Item & Service Catalog**: Track products and services with pricing, stock levels, and categories.
- **Expense Tracking**: Complete expense management with vendor linkage, line items, receipt attachments, and PDF export.
- **Quotation System**: Generate customized quotations for clients, calculates totals automatically, and manages quotation state (Draft, Sent, etc.).
- **Lead Management**: Track leads through pipeline stages (New, Contacted, Qualified, Converted, Lost).
- **Activity Logging**: Comprehensive activity tracking with PDF export functionality.
- **Dashboard Analytics**: Real-time statistics for revenue, expenses, and business metrics.
- **Robust Error Handling**: Standardized central validation, HTTP, and global exceptions with clean JSON responses.
- **Detailed Logging**: Middleware logging system recording latency, endpoints, and error metrics.

---

## Tech Stack

- **Python 3.11+**
- **FastAPI**: API structure and endpoints
- **Pydantic v2**: Secure schema validation
- **SQLAlchemy 2.x**: Relational ORM mapping
- **Alembic**: Database migrations
- **SQLite**: Default relational database (local persistence in `business_tools.db`)
- **Pytest**: Integration and unit testing suite
- **python-jose (cryptography) & bcrypt**: Password hashing and token authentication
- **fpdf2**: PDF generation

---

## Project Structure

```text
.
├── main.py                     # App entry point, CORS/Logging middleware & routers integration
├── db.py                       # DB engine, local session setup, and get_db dependency
├── alembic.ini                 # Alembic configuration
├── alembic/                    # Migration environment and historical schema scripts
├── core/
│   ├── dependencies.py         # JWT route auth checks (get_current_user)
│   ├── logger.py               # Custom metrics tracker and logger
│   └── security.py             # Password hashing and token helpers
├── middleware/
│   └── logging_middleware.py   # Latency and Request ID middleware
├── models/
│   ├── db_models.py            # Persisted SQLAlchemy tables (User, Invoice, Expense, etc.)
│   ├── invoice_generator.py    # Invoice calculation schemas and functions
│   └── quotation.py            # Quotation calculations
├── routes/                     # Router controllers exposing CRUD endpoints
│   ├── auth.py
│   ├── activity.py
│   ├── customer.py
│   ├── dashboard.py
│   ├── expense.py
│   ├── invoice_generator.py
│   ├── item.py
│   ├── lead.py
│   ├── quotation.py
│   ├── service.py
│   └── vendor.py
├── schemas/                    # Pydantic serializer/deserializer schemas
│   ├── auth.py
│   ├── activity_schema.py
│   ├── customer_schema.py
│   ├── expense_schema.py
│   ├── invoice_schema.py
│   ├── item_schema.py
│   ├── lead_schema.py
│   ├── quotation_schema.py
│   ├── service_schema.py
│   └── vendor_schema.py
├── services/                   # Business logic layer
│   ├── activity_service.py
│   ├── customer_service.py
│   ├── expense_service.py
│   ├── invoice_service.py
│   ├── item_service.py
│   ├── lead_service.py
│   ├── quotation_service.py
│   ├── service_service.py
│   ├── vendor_service.py
│   └── gst_invoice_generator/  # Specific GST math calculations and PDF renderer
└── tests/                      # Pytest unit and integration files
```

---

## Environment Configuration

Create a `.env` file in the root directory. To run via Docker, Docker Compose uses `.env.docker` dynamically. For local direct running:

```env
APP_HOST=127.0.0.1
APP_PORT=8000
SECRET_KEY=your_secret_jwt_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Database Configuration (Defaults to local SQLite or PostgreSQL connection string)
DATABASE_URL=sqlite:///./business_tools.db
# DATABASE_URL=postgresql+psycopg2://invoice_user:invoice_password_2026@localhost:5432/invoice_business_tools
```

---

## Setup and Installation

### Option A: Running with Docker (Recommended)
This starts both PostgreSQL and FastAPI in containers.

1. **Start** (runs checks, builds the docker containers, and tests local API health):
   * **Windows (PowerShell)**:
     ```powershell
     .\start-docker.ps1
     ```
   * **Manual Command**:
     ```bash
     docker compose up -d --build
     ```
2. **Stop**:
   * **Windows (PowerShell)**:
     ```powershell
     .\stop-docker.ps1
     ```
   * **Manual Command**:
     ```bash
     docker compose stop
     ```

### Option B: Running Locally (Direct Python setup)

1. **Create and Activate Virtual Environment**
   * **macOS/Linux**:
     ```bash
     python3 -m venv .venv
     source .venv/bin/activate
     ```
   * **Windows (PowerShell)**:
     ```powershell
     python -m venv .venv
     .venv\Scripts\Activate.ps1
     ```

2. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run Database Migrations**
   ```bash
   alembic upgrade head
   ```

4. **Start the API Server**
   ```bash
   uvicorn main:app --reload
   ```

---

## API Endpoints

### 🔑 Authentication
* `POST /api/v1/auth/register` - Create a new user profile
* `POST /api/v1/auth/login` - Authenticate user credentials and retrieve JWT token
* `GET /api/v1/auth/me` - Fetch details of the currently authorized user (Requires Bearer token)

### 📄 Invoices
* `POST /api/v1/invoices/create` - Calculate GST and store a new invoice (intra/inter-state tax auto-split)
* `GET /api/v1/invoices/list` - Fetch all invoices created by the current user
* `GET /api/v1/invoices/{id}` - Retrieve detailed info for a single invoice
* `PUT /api/v1/invoices/{id}` - Modify metadata of an existing invoice (dates, notes)
* `DELETE /api/v1/invoices/{id}` - Remove an invoice and its child items from the database
* `GET /api/v1/invoices/{id}/download-pdf` - Renders and downloads a professional invoice PDF file

### 💰 Expenses
* `POST /api/v1/expenses/create` - Create a new expense with vendor, items, and receipt
* `GET /api/v1/expenses/list` - Retrieve all user expenses
* `GET /api/v1/expenses/{id}` - Fetch single expense details
* `PUT /api/v1/expenses/{id}` - Update expense information
* `DELETE /api/v1/expenses/{id}` - Delete an expense record
* `GET /api/v1/expenses/export-list-pdf` - Export all expenses as PDF report

### 📋 Quotations
* `POST /api/v1/quotation/create` - Draft a client quotation
* `GET /api/v1/quotation/list` - List all user quotations
* `GET /api/v1/quotation/{id}` - Retrieve a single quotation record
* `PUT /api/v1/quotation/{id}` - Update quotation details
* `DELETE /api/v1/quotation/{id}` - Delete a quotation record
* `GET /api/v1/quotation/{id}/download-pdf` - Download quotation as PDF
* `GET /api/v1/quotation/export-list-pdf` - Export all quotations as PDF report

### 👥 Customers
* `POST /api/v1/customers` - Create a new customer
* `GET /api/v1/customers` - List all customers
* `GET /api/v1/customers/{id}` - Get customer details
* `PUT /api/v1/customers/{id}` - Update customer information
* `DELETE /api/v1/customers/{id}` - Delete a customer
* `GET /api/v1/customers/export-list-pdf` - Export customers as PDF

### 🏢 Vendors
* `POST /api/v1/vendors/add` - Create a new vendor
* `GET /api/v1/vendors/list` - List all vendors
* `GET /api/v1/vendors/{id}` - Get vendor details
* `PUT /api/v1/vendors/{id}` - Update vendor information
* `DELETE /api/v1/vendors/{id}` - Delete a vendor
* `GET /api/v1/vendors/export-list-pdf` - Export vendors as PDF

### 📦 Items & Services
* `POST /api/v1/items` - Create a new item/product
* `GET /api/v1/items` - List all items
* `GET /api/v1/items/{id}` - Get item details
* `PUT /api/v1/items/{id}` - Update item information
* `DELETE /api/v1/items/{id}` - Delete an item
* `PUT /api/v1/items/{id}/stock` - Update item stock level
* `GET /api/v1/items/export-list-pdf` - Export items as PDF
* `POST /api/v1/services` - Create a new service
* `GET /api/v1/services` - List all services
* `PUT /api/v1/services/{id}` - Update service information
* `DELETE /api/v1/services/{id}` - Delete a service
* `GET /api/v1/services/export-list-pdf` - Export services as PDF

### 🎯 Leads
* `POST /api/v1/leads/create` - Create a new lead
* `GET /api/v1/leads/list` - List all leads
* `GET /api/v1/leads/{id}` - Get lead details
* `PUT /api/v1/leads/{id}` - Update lead information
* `DELETE /api/v1/leads/{id}` - Delete a lead
* `POST /api/v1/leads/{id}/convert` - Convert lead to customer

### 📊 Activity & Dashboard
* `GET /api/v1/activity` - Get activity log
* `DELETE /api/v1/activity/{id}` - Delete an activity entry
* `GET /api/v1/activity/export-list-pdf` - Export activity log as PDF
* `GET /api/v1/dashboard/stats` - Get dashboard statistics

---

## Testing & Verification

The project includes a robust test suite covering validation logic, database persistence, state transitions, calculations, and security access controls.

To run the automated test suite, execute:
```bash
pytest
```

To run a diagnostic script hitting basic local endpoints (requires uvicorn running):
```bash
python verify_api.py
```
