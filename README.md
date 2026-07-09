# Naiyo24: Invoice & Business Tools Suite

A modern, full-featured business management tool designed for small to medium businesses. The suite combines a responsive, aesthetic **Flutter web/mobile frontend** with a robust **FastAPI backend** to manage invoices, client quotations, leads, inventory, expenses, salary payrolls, and professional accounting ledgers with automatic GST calculation.

---

## 📌 Project Architecture & Structure

This repository is structured as a monorepo consisting of two primary sub-projects:

```text
Naiyo24/
├── invoice-business-tools-backend-api/   # Python FastAPI Backend
│   ├── alembic/                         # Database migrations
│   ├── core/                            # JWT Security, Logger, configuration
│   ├── models/                          # SQLAlchemy database models
│   ├── routes/                          # FastAPI REST API endpoints
│   ├── schemas/                         # Pydantic validation schemas
│   ├── services/                        # Business logic & GST engine
│   ├── tests/                           # Python Pytest files
│   ├── Dockerfile                       # Container definition for backend
│   └── docker-compose.yml               # Complete DB + API service stack
│
└── naiyo24_business_tool/               # Flutter Frontend
    ├── lib/
    │   ├── api_services/                # Client-side API integration layers
    │   ├── models/                      # Frontend data models matching the API
    │   ├── notifiers/                   # State management using Riverpod notifier classes
    │   ├── screens/                     # Views (Dashboard, Invoice Creation, Customers, etc.)
    │   ├── theme/                       # Aesthetic Dark & Light design styles
    │   └── widgets/                     # Reusable modular UI components
    └── pubspec.yaml                     # Flutter package dependencies
```

---

## 🛠️ Features

- **GST Invoicing Engine**: Automated intra-state (CGST + SGST) and inter-state (IGST) split calculation with clean UI and premium PDF invoice download.
- **Double-Entry Accounting & Ledgers**: Tracks accounts (Assets, Liabilities, Equity, Income, Expenses) with active group structures.
- **Lead & Customer Relationship Management**: Handles lead pipelines (New, Contacted, Qualified, Converted) and conversions.
- **Quotation & Proposal Builder**: Easily draft, approve, and track custom quotes.
- **Stock & Inventory Control**: Integrated product items and service configurations.
- **Security & Authorization**: JWT token auth ensuring user-specific data compartmentalization.
- **Dark Mode Support**: Aesthetic theme switching built natively with unified styles.

---

## 🚀 Getting Started

### 📋 Prerequisites
Make sure you have the following installed on your machine:
- **Docker Desktop** (Recommended for easiest database setup)
- **Python 3.11+**
- **Flutter SDK** (Channel stable)
- **Google Chrome** (For running Flutter Web)

---

## 1. Starting the Backend API

You can start the backend either using **Docker (Recommended)** or **Locally**.

### Option A: Running with Docker (Recommended)
This spins up both a PostgreSQL database and the FastAPI application inside containers. You can run Docker Compose manually or use the provided automation scripts:

#### Using Automation Scripts (Windows PowerShell)
1. Navigate to the backend directory:
   ```powershell
   cd invoice-business-tools-backend-api
   ```
2. **Start** the services (checks Docker health, builds images, runs containers, and tests local API connectivity):
   ```powershell
   .\start-docker.ps1
   ```
3. **Stop** the services (stops containers safely without dropping the database volume):
   ```powershell
   .\stop-docker.ps1
   ```

#### Or Run Manually via Docker CLI
1. Navigate to the backend directory:
   ```bash
   cd invoice-business-tools-backend-api
   ```
2. Start the services:
   ```bash
   docker compose up -d --build
   ```
3. Verify backend health by opening `http://localhost:8000/health` in your browser.
4. Access interactive API documentation (Swagger UI) at `http://localhost:8000/docs`.

To stop the Docker containers manually:
```bash
docker compose down
```

---

### Option B: Running Locally (Manual Setup)
Use this option if you want to run the FastAPI app directly without Docker containerization.

1. Navigate to the backend directory:
   ```bash
   cd invoice-business-tools-backend-api
   ```
2. Create and activate a Python virtual environment:
   * **Windows (PowerShell)**:
     ```powershell
     python -m venv .venv
     .venv\Scripts\Activate.ps1
     ```
   * **macOS/Linux**:
     ```bash
     python3 -m venv .venv
     source .venv/bin/activate
     ```
3. Install the dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Copy/Create a `.env` file in the backend root matching your local database config. (Defaults to PostgreSQL or local SQLite).
5. Run the database migrations using Alembic:
   ```bash
   alembic upgrade head
   ```
6. Start the development server:
   ```bash
   uvicorn main:app --reload
   ```

---

## 2. Starting the Flutter Frontend

1. Navigate to the frontend directory:
   ```bash
   cd naiyo24_business_tool
   ```
2. Fetch required package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application in Chrome (Web):
   ```bash
   flutter run -d chrome
   ```

---

## 🧪 Testing the API

To verify backend calculations and integration flows, run the pytest suite from inside the backend directory:
```bash
pytest
```
You can also execute the quick smoke test script to verify endpoint routing:
```bash
python verify_api.py
```
