# 🚀 Quick Start Guide - Docker Setup

Get the Invoice Business Tools Backend running in 5 minutes!

## ✅ Prerequisites

1. **Docker Desktop** - Download from https://www.docker.com/products/docker-desktop
   - Make sure Docker Desktop is running (check system tray icon)
   - Requires Windows 10/11 with WSL2 enabled

2. **Port Availability** - Make sure these ports are free:
   - `8000` - Backend API
   - `5432` - PostgreSQL Database

## 🎯 Step-by-Step Setup

### Step 1: Start Docker Desktop

Open Docker Desktop and wait for it to fully start (whale icon should be stable).

### Step 2: Start the Backend

Open Command Prompt or PowerShell in the backend directory and run:

```batch
start-docker.bat
```

Or manually:

```bash
docker-compose up -d --build
```

**What happens:**
- Downloads PostgreSQL image (~80MB)
- Builds backend Docker image
- Starts PostgreSQL database
- Waits for database to be healthy
- Runs Alembic migrations to create tables
- Starts FastAPI server on port 8000

**Expected output:**
```
[+] Building 45.2s (12/12) FINISHED
[+] Running 3/3
 ✔ Network invoice-business-tools-backend-api_invoice-network  Created
 ✔ Container invoice-db                                        Healthy
 ✔ Container invoice-backend                                   Started
```

### Step 3: Verify It's Running

**Option 1: Open in browser**
- http://localhost:8000/health
- http://localhost:8000/docs (Interactive API documentation)

**Option 2: Use curl**
```bash
curl http://localhost:8000/health
```

**Expected response:**
```json
{
  "success": true,
  "message": "Service is healthy",
  "uptime_seconds": 12.5,
  "total_requests": 1,
  "total_errors": 0
}
```

### Step 4: View Logs (Optional)

To see what's happening:

```batch
logs-docker.bat
```

Or manually:

```bash
docker-compose logs -f
```

Press `Ctrl+C` to stop viewing logs (containers keep running).

## 🎨 Test with Flutter Frontend

Now that the backend is running, you can test with the Flutter app:

### 1. Update Frontend API URL (if needed)

The Flutter frontend is already configured to use `http://localhost:8000/api/v1`.

Check `lib/api_services/api_routes.dart`:
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

### 2. Run Flutter App

Navigate to the Flutter project directory:

```bash
cd c:\Users\NITRO\Desktop\newRepo\naiyo24_business_tool
flutter run -d chrome
```

Or use your IDE (VS Code, Android Studio) to run the app.

### 3. Test Core Features

**Create a Customer:**
1. Go to Customers section
2. Add a new customer with GST details
3. Check backend database to verify it's saved

**Create an Invoice:**
1. Go to Invoices section
2. Create a new invoice with line items
3. Select intra-state or inter-state customer
4. Verify GST calculation (CGST+SGST or IGST)
5. Download PDF invoice

**Check Database:**
```bash
docker-compose exec db psql -U invoice_user -d invoice_business_tools
```

Then run:
```sql
\dt                                    -- List all tables
SELECT * FROM users;                   -- View users
SELECT * FROM invoices;                -- View invoices
SELECT * FROM customers;               -- View customers
\q                                     -- Quit
```

## 🛠️ Common Commands

### View Running Containers
```bash
docker-compose ps
```

### Stop Backend (keeps data)
```batch
stop-docker.bat
```

Or manually:
```bash
docker-compose stop
```

### Start Again
```bash
docker-compose up -d
```

### View Logs
```batch
logs-docker.bat
```

### Restart Backend
```bash
docker-compose restart backend
```

### Access Backend Shell
```bash
docker-compose exec backend bash
```

### Run Database Migrations
```bash
docker-compose exec backend alembic upgrade head
```

### Stop and Remove Everything
```bash
# Keeps data
docker-compose down

# Removes ALL data (fresh start)
docker-compose down -v
```

## 🐛 Troubleshooting

### "Docker is not running"

**Solution:** Open Docker Desktop and wait for it to start.

### "Port 8000 is already in use"

**Solution:** Stop any other application using port 8000:
```bash
# Find what's using the port
netstat -ano | findstr :8000

# Or change the port in docker-compose.yml
ports:
  - "8001:8000"  # Use 8001 instead
```

### "Port 5432 is already in use"

**Solution:** You probably have PostgreSQL installed locally:
```bash
# Stop local PostgreSQL service
net stop postgresql-x64-15

# Or change the port in docker-compose.yml
ports:
  - "5433:5432"  # Use 5433 instead
```

### Backend won't start

**Check logs:**
```bash
docker-compose logs backend
```

**Common issues:**
1. Database migration failed - Try: `docker-compose exec backend alembic upgrade head`
2. Python errors - Rebuild: `docker-compose up -d --build backend`

### "Failed to connect to database"

**Verify database is healthy:**
```bash
docker-compose ps
```

Look for `db` with status "healthy".

**Test connection:**
```bash
docker-compose exec backend python -c "from db import engine; print(engine.connect())"
```

### Start Fresh

If everything is broken:

```bash
# Stop and remove everything
docker-compose down -v

# Remove built images
docker rmi invoice-business-tools-backend-api-backend

# Rebuild and start
docker-compose up -d --build
```

## 📊 API Endpoints

Once running, you can test these endpoints:

### Health Check
```bash
curl http://localhost:8000/health
```

### Authentication
```bash
# Register new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "full_name": "Test User"
  }'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### List Invoices
```bash
curl http://localhost:8000/api/v1/invoices/list
```

### API Documentation
Open http://localhost:8000/docs for interactive API documentation.

## 🎯 Next Steps

1. ✅ Backend running in Docker
2. ✅ Database initialized with migrations
3. 🔄 Test with Flutter frontend
4. 🔄 Create sample invoices and test PDF generation
5. 🔄 Verify GST calculations (intra-state vs inter-state)
6. 🔄 Test stock management
7. ⏳ Implement authentication in frontend (later phase)

## 🔒 Production Deployment

For production deployment, see `DOCKER_SETUP.md` for:
- Security best practices
- Environment variable management
- Scaling strategies
- Monitoring setup
- Backup procedures

## 📝 Files Created

- `Dockerfile` - Backend container definition
- `docker-compose.yml` - Multi-container orchestration
- `.dockerignore` - Files to exclude from image
- `.env.docker` - Example Docker environment config
- `start-docker.bat` - Quick start script (Windows)
- `stop-docker.bat` - Quick stop script (Windows)
- `logs-docker.bat` - View logs script (Windows)
- `DOCKER_SETUP.md` - Comprehensive Docker guide
- `QUICK_START.md` - This file

## 🎉 Success Checklist

- [ ] Docker Desktop is running
- [ ] `docker-compose up -d` completed successfully
- [ ] http://localhost:8000/health returns healthy status
- [ ] http://localhost:8000/docs shows API documentation
- [ ] Flutter frontend connects to backend
- [ ] Can create customers
- [ ] Can create invoices
- [ ] Can download PDF invoices
- [ ] Database persists data between restarts

**Happy Coding! 🚀**
