"""
core/logger.py — Structured JSON logging with rotation and app metrics.

Provides:
  - `app_logger`       : Pre-configured logger (JSON → console + rotating file).
  - `app_start_time`   : Epoch timestamp recorded at import time (for uptime).
  - `request_metrics`  : Shared dict of counters consumed by /health endpoint.

Log destinations:
  - Console (stdout)       : one JSON object per line.
  - File (logs/app.log)    : same format, auto-rotated at 5 MB, 5 backups.
"""

import json
import logging
import os
import sys
import time
from datetime import datetime, timezone
from logging.handlers import RotatingFileHandler


# ---------------------------------------------------------------------------
# JSON Formatter
# ---------------------------------------------------------------------------

class JSONFormatter(logging.Formatter):
    """Formats each log record as a single-line JSON object."""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Attach extra fields injected via `extra={}` in logging calls
        for key in (
            "request_id",
            "method",
            "path",
            "status_code",
            "response_time_ms",
        ):
            value = getattr(record, key, None)
            if value is not None:
                log_data[key] = value

        # Attach stack trace for exceptions
        if record.exc_info and record.exc_info[0] is not None:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data)


# ---------------------------------------------------------------------------
# Logger factory
# ---------------------------------------------------------------------------

def setup_logger(
    name: str = "business_tools",
    log_level: str = "INFO",
    log_file: str = "logs/app.log",
    max_bytes: int = 5 * 1024 * 1024,   # 5 MB per file
    backup_count: int = 5,               # keep 5 rotated backups
) -> logging.Logger:
    """Create and configure a JSON logger with console + rotating file output."""

    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, log_level.upper(), logging.INFO))

    # Prevent duplicate handlers on repeated calls (e.g. test re-imports)
    if logger.handlers:
        return logger

    json_formatter = JSONFormatter()

    # --- Console handler (stdout) ---
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(json_formatter)
    logger.addHandler(console_handler)

    # --- Rotating file handler ---
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=max_bytes,
        backupCount=backup_count,
    )
    file_handler.setFormatter(json_formatter)
    logger.addHandler(file_handler)

    return logger


# ---------------------------------------------------------------------------
# Default application logger — import this everywhere
# ---------------------------------------------------------------------------
app_logger = setup_logger()


# ---------------------------------------------------------------------------
# Application metrics — shared counters for the /health endpoint
# ---------------------------------------------------------------------------
app_start_time = time.time()

request_metrics: dict = {
    "total_requests": 0,
    "total_errors": 0,
    "error_counts_by_status": {},
}
