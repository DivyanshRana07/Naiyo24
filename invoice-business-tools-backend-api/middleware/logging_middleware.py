"""
middleware/logging_middleware.py — Global HTTP request/response logging.

For every request this middleware:
  1. Generates a unique request ID (first 8 hex chars of a UUID4).
  2. Increments the shared request_metrics counters.
  3. Logs the incoming request (method, path).
  4. Calls the actual route handler.
  5. Logs the outgoing response (status code, elapsed time in ms).
  6. Attaches the request ID as an ``X-Request-ID`` response header.
"""

import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from core.logger import app_logger, request_metrics


class LoggingMiddleware(BaseHTTPMiddleware):

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = uuid.uuid4().hex[:8]
        start_time = time.time()

        # --- Track total requests ---
        request_metrics["total_requests"] += 1

        # --- Log incoming request ---
        app_logger.info(
            f"→ {request.method} {request.url.path}",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": str(request.url.path),
            },
        )

        # --- Process request ---
        try:
            response = await call_next(request)
        except Exception:
            elapsed_ms = round((time.time() - start_time) * 1000, 2)
            app_logger.error(
                f"✗ {request.method} {request.url.path} — unhandled exception",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": str(request.url.path),
                    "response_time_ms": elapsed_ms,
                },
                exc_info=True,
            )
            request_metrics["total_errors"] += 1
            raise

        # --- Track error responses ---
        elapsed_ms = round((time.time() - start_time) * 1000, 2)

        if response.status_code >= 400:
            request_metrics["total_errors"] += 1
            status_key = str(response.status_code)
            request_metrics["error_counts_by_status"][status_key] = (
                request_metrics["error_counts_by_status"].get(status_key, 0) + 1
            )

        # --- Log outgoing response ---
        log_fn = app_logger.warning if response.status_code >= 400 else app_logger.info
        log_fn(
            f"← {request.method} {request.url.path} → {response.status_code} ({elapsed_ms} ms)",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": str(request.url.path),
                "status_code": response.status_code,
                "response_time_ms": elapsed_ms,
            },
        )

        # --- Attach request ID header for traceability ---
        response.headers["X-Request-ID"] = request_id
        return response
