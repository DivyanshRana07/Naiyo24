# Docker Setup Guide

This guide will help you run the Invoice Business Tools Backend API with PostgreSQL database using Docker.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)
- At least 2GB of free disk space

## Quick Start

### 1. Start the Containers

From the backend directory, run:

```bash
docker-compose up -d
```

This will:
- Pull PostgreSQL 15 Alpine image
- Build the FastAPI backend image
- Create a network for the services
- Start PostgreSQL database
- Wait for database to be healthy
- Run Alembic migrations automatically
- Start the FastAPI server on port 8000

### 2. Check Container Status

```bash
docker-compose ps
```

You should see both containers running:
- `invoice-db` (PostgreSQL)
- `invoice-backend` (FastAPI)

### 3. View Logs

**All logs:**
```bash
docker-compose logs -f
```

**Backend only:**
```bash
docker-compose logs -f backend
```

**Database only:**
```bash
docker-compose logs -f db
```

### 4. Test the API

Open your browser and visit:
- Health Check: http://localhost:8000/health
- API Docs: http://localhost:8000/docs
- Root: http://localhost:8000

Or use curl:
```bash
curl http://localhost:8000/health
```

### 5. Stop the Containers

**Stop but keep data:**
```bash
docker-compose stop
```

**Stop and remove containers (keeps data):**
```bash
docker-compose down
```

**Stop, remove containers and volumes (deletes all data):**
```bash
docker-compose down -v
```

## Architecture

```
┌─────────────────────────────────────────┐
│   Flutter Frontend (localhost:*)        │
│   (Running on host machine)             │
└──────────────┬──────────────────────────┘
               │
               │ HTTP Requests
               │ (localhost:8000)
               ▼
┌─────────────────────────────────────────┐
│   FastAPI Backend (invoice-backend)     │
│   - Port: 8000                          │
│   - Auto migrations on startup          │
│   - Health checks                       │
└──────────────┬──────────────────────────┘
               │
               │ PostgreSQL Connection
               │ (internal network)
               ▼
┌─────────────────────────────────────────┐
│   PostgreSQL Database (invoice-db)      │
│   - Port: 5432 (exposed)                │
│   - Persistent volume                   │
│   - Health checks                       │
└─────────────────────────────────────────┘
```

## Configuration

### Environment Variables

The `docker-compose.yml` file configures:

**Database:**
- `POSTGRES_USER`: invoice_user
- `POSTGRES_PASSWORD`: invoice_password_2026
- `POSTGRES_DB`: invoice_business_tools

**Backend:**
- `DATABASE_URL`: PostgreSQL connection string
- `APP_HOST`: 0.0.0.0 (listen on all interfaces)
- `APP_PORT`: 8000
- `SECRET_KEY`: JWT signing key (change in production!)

### Ports

- **8000**: FastAPI backend (mapped to host)
- **5432**: PostgreSQL database (mapped to host for debugging)

## Database Management

### Run Migrations Manually

If you need to run migrations manually:

```bash
docker-compose exec backend alembic upgrade head
```

### Create New Migration

```bash
docker-compose exec backend alembic revision --autogenerate -m "your migration message"
```

### Access PostgreSQL CLI

```bash
docker-compose exec db psql -U invoice_user -d invoice_business_tools
```

Common psql commands:
- `\dt` - List all tables
- `\d table_name` - Describe table structure
- `\q` - Quit

### Backup Database

```bash
docker-compose exec db pg_dump -U invoice_user invoice_business_tools > backup.sql
```

### Restore Database

```bash
docker-compose exec -T db psql -U invoice_user invoice_business_tools < backup.sql
```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker-compose logs backend
docker-compose logs db
```

**Common issues:**
1. Port 8000 already in use
2. Port 5432 already in use (local PostgreSQL running)
3. Not enough memory allocated to Docker

### Database Connection Failed

**Verify database is healthy:**
```bash
docker-compose exec db pg_isready -U invoice_user
```

**Check network connectivity:**
```bash
docker-compose exec backend ping db
```

### Reset Everything

If you want to start fresh:

```bash
# Stop and remove everything including volumes
docker-compose down -v

# Remove built images
docker rmi invoice-business-tools-backend-api-backend

# Start fresh
docker-compose up -d --build
```

### View Backend Application Logs

Application logs are stored in `./logs/app.log` on the host machine:

```bash
tail -f logs/app.log
```

## Development Workflow

### Make Code Changes

1. Edit your Python files
2. Rebuild and restart:

```bash
docker-compose up -d --build
```

Or for faster iteration (without rebuilding):

```bash
docker-compose restart backend
```

### Access Backend Shell

```bash
docker-compose exec backend bash
```

### Install New Python Package

1. Add package to `requirements.txt`
2. Rebuild the image:

```bash
docker-compose up -d --build backend
```

## Production Considerations

### Security

**Before deploying to production:**

1. **Change SECRET_KEY** in docker-compose.yml:
   ```yaml
   SECRET_KEY: ${SECRET_KEY}  # Use environment variable
   ```

2. **Use strong database password**:
   ```yaml
   POSTGRES_PASSWORD: ${DB_PASSWORD}  # Use environment variable
   ```

3. **Restrict CORS origins** in `main.py`:
   ```python
   allow_origins=["https://yourdomain.com"]
   ```

4. **Use external secrets management**:
   - AWS Secrets Manager
   - HashiCorp Vault
   - Kubernetes Secrets

### Scaling

For production, consider:
- Using managed PostgreSQL (AWS RDS, Azure Database, etc.)
- Running multiple backend replicas with load balancer
- Using Docker Swarm or Kubernetes for orchestration
- Adding Redis for caching
- Setting up monitoring (Prometheus, Grafana)

### Networking

If deploying on cloud, update frontend API URL:

**Flutter** (`lib/api_services/api_routes.dart`):
```dart
static const String baseUrl = 'https://api.yourdomain.com/api/v1';
```

## Monitoring

### Check Resource Usage

```bash
docker stats
```

### Check Container Health

```bash
docker inspect --format='{{.State.Health.Status}}' invoice-backend
docker inspect --format='{{.State.Health.Status}}' invoice-db
```

## Clean Up

### Remove Stopped Containers

```bash
docker-compose rm
```

### Remove Unused Images

```bash
docker image prune -a
```

### Remove All (including volumes)

```bash
docker-compose down -v
docker system prune -a
```

## Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Verify health: `docker-compose ps`
3. Test connectivity: `curl http://localhost:8000/health`
4. Check database: `docker-compose exec db pg_isready`

## Next Steps

After backend is running:
1. Test API endpoints using http://localhost:8000/docs
2. Create a test user via `/api/v1/auth/register`
3. Run Flutter frontend and point it to `http://localhost:8000/api/v1`
4. Test invoice creation, PDF download, and other features
