import os
import time
# pyrefly: ignore [missing-import]
from fastapi import FastAPI, HTTPException, Request, status
# pyrefly: ignore [missing-import]
from fastapi.encoders import jsonable_encoder
# pyrefly: ignore [missing-import]
from fastapi.exceptions import RequestValidationError
# pyrefly: ignore [missing-import]
from fastapi.responses import JSONResponse
# pyrefly: ignore [missing-import]
from dotenv import load_dotenv
from routes.dashboard import router as dashboard_router

# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware

# pyrefly: ignore [missing-import]
import uvicorn

from core.logger import app_logger, app_start_time, request_metrics
from middleware.logging_middleware import LoggingMiddleware

# Import all models to ensure SQLAlchemy registers them
import models.db_models  # noqa: F401

# Import Routers
from routes.auth import router as auth_router
from routes.invoice_generator import router as invoice_router
from routes.quotation import router as quotation_router
from routes.vendor import router as vendor_router
from routes.expense import router as expense_router
from routes.customer import router as customer_router
from routes.item import router as item_router
from routes.service import router as service_router

from routes.activity import router as activity_router
from routes.lead import router as lead_router


# Load Environment Variables
load_dotenv()

# Create FastAPI App
app = FastAPI(
    title="Invoice & Business Tools Backend",
    version="1.0.0",
    description="Backend focused on GST invoice generation with extensible architecture."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Logging Middleware — logs every request/response with timing and request IDs
app.add_middleware(LoggingMiddleware)

# App Configuration
APP_HOST = os.getenv("APP_HOST", "127.0.0.1")
APP_PORT = int(os.getenv("APP_PORT", "8000"))


# Root Endpoint
@app.get("/", tags=["Health"])
def root():
    return {
        "success": True,
        "message": "Invoice & Business Tools Backend is running successfully"
    }


# Health Check Endpoint
@app.get("/health", tags=["Health"])
def health_check():
    uptime_seconds = round(time.time() - app_start_time, 2)
    return {
        "success": True,
        "message": "Service is healthy",
        "uptime_seconds": uptime_seconds,
        "total_requests": request_metrics["total_requests"],
        "total_errors": request_metrics["total_errors"],
        "error_counts_by_status": request_metrics["error_counts_by_status"],
    }


# Include All Routers with API Versioning
app.include_router(
    auth_router,
    prefix="/api/v1"
)

app.include_router(
    invoice_router,
    prefix="/api/v1"
)

app.include_router(
    dashboard_router,
    prefix="/api/v1"
)

app.include_router(
    quotation_router,
    prefix="/api/v1"
)

app.include_router(
    vendor_router,
    prefix="/api/v1"
)

app.include_router(
    expense_router,
    prefix="/api/v1"
)


app.include_router(
    customer_router,
    prefix="/api/v1"
)

app.include_router(
    item_router,
    prefix="/api/v1"
)


app.include_router(
    service_router,
    prefix="/api/v1"
)

app.include_router(
    activity_router,
    prefix="/api/v1"
)

app.include_router(
    lead_router,
    prefix="/api/v1"
)



# Validation Error Handler
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError
):
    errors = exc.errors()
    print("FastAPI Validation Errors:", errors)
    app_logger.warning(
        f"Validation error on {request.method} {request.url.path}: {errors}",
        extra={"method": request.method, "path": str(request.url.path)},
    )

    def _safe(v):
        """Recursively convert non-JSON-serializable values to strings."""
        if isinstance(v, dict):
            return {k: _safe(val) for k, val in v.items()}
        if isinstance(v, list):
            return [_safe(i) for i in v]
        if isinstance(v, (str, int, float, bool, type(None))):
            return v
        return str(v)

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "message": "Validation failed",
            "errors": [_safe(e) for e in exc.errors()]
        }
    )


# HTTP Exception Handler
@app.exception_handler(HTTPException)
async def http_exception_handler(
    request: Request,
    exc: HTTPException
):
    app_logger.warning(
        f"HTTP {exc.status_code} on {request.method} {request.url.path}: {exc.detail}",
        extra={
            "method": request.method,
            "path": str(request.url.path),
            "status_code": exc.status_code,
        },
    )
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "message": str(exc.detail)
        }
    )


# Global Exception Handler
@app.exception_handler(Exception)
async def global_exception_handler(
    request: Request,
    exc: Exception
):
    app_logger.error(
        f"Unhandled exception on {request.method} {request.url.path}: {str(exc)}",
        extra={"method": request.method, "path": str(request.url.path)},
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "Internal Server Error"
        }
    )


# Run FastAPI Server
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=APP_HOST,
        port=APP_PORT,
        reload=True
    )