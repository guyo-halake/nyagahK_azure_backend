import os
import sys
import json
import logging
import time
import uuid
from typing import Callable
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for direct ingestion into Azure Log Analytics & App Insights."""
    def format(self, record: logging.LogRecord) -> str:
        log_obj = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "service": "nyaga-law-backend",
            "environment": os.environ.get("APP_ENV", "production"),
            "logger": record.name,
            "message": record.getMessage()
        }
        if hasattr(record, "correlation_id"):
            log_obj["correlation_id"] = record.correlation_id
        if hasattr(record, "http_status"):
            log_obj["status_code"] = record.http_status
        if hasattr(record, "latency_ms"):
            log_obj["latency_ms"] = record.latency_ms
        if record.exc_info:
            log_obj["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_obj)

def setup_structured_logging():
    """Configure standard library logging to output structured JSON to stdout."""
    logger = logging.getLogger("nyaga_law")
    logger.setLevel(logging.INFO)
    logger.propagate = False

    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(JSONFormatter())
        logger.addHandler(handler)
    return logger

structured_logger = setup_structured_logging()

class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Assigns unique X-Correlation-ID to every request for end-to-end distributed tracing."""
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
        request.state.correlation_id = correlation_id

        start_time = time.perf_counter()
        try:
            response = await call_next(request)
            latency_ms = round((time.perf_counter() - start_time) * 1000, 2)
            response.headers["X-Correlation-ID"] = correlation_id

            # Log request telemetry in JSON format
            extra = {
                "correlation_id": correlation_id,
                "http_status": response.status_code,
                "latency_ms": latency_ms
            }
            log_msg = f"{request.method} {request.url.path} -> {response.status_code} ({latency_ms}ms)"
            structured_logger.info(log_msg, extra=extra)
            return response
        except Exception as e:
            latency_ms = round((time.perf_counter() - start_time) * 1000, 2)
            extra = {
                "correlation_id": correlation_id,
                "http_status": 500,
                "latency_ms": latency_ms
            }
            structured_logger.error(f"Unhandled error on {request.method} {request.url.path}: {str(e)}", exc_info=True, extra=extra)
            raise e
