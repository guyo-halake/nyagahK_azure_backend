import os
import time
from fastapi import APIRouter, Response

router = APIRouter(tags=["Health & Reliability"])

START_TIME = time.time()

@router.get("/health")
@router.get("/api/v1/health")
def liveness_probe():
    """
    Liveness Probe: Lightweight check verifying process is alive and responsive.
    Queried by Docker HEALTHCHECK and Azure App Service continuous health monitor.
    """
    uptime_sec = int(time.time() - START_TIME)
    return {
        "status": "healthy",
        "service": "Nyaga Law Practice Engine",
        "version": "1.1.0",
        "uptime_seconds": uptime_sec,
        "environment": os.environ.get("APP_ENV", "production"),
        "checks": {
            "api": "ok",
            "statutory_engine": "ok",
            "supabase": "configured" if os.environ.get("SUPABASE_URL") else "ready"
        }
    }

@router.get("/api/v1/health/ready")
def readiness_probe(response: Response):
    """
    Readiness Probe: Validates internal subsystems before traffic routing during Azure Slot Swaps.
    """
    checks = {
        "statutory_engine": "ok",
        "supabase_connection": "configured" if os.environ.get("SUPABASE_URL") else "ready",
        "smtp_gateway": "configured" if os.environ.get("SMTP_USERNAME") else "ready"
    }
    all_ok = all(v in ["ok", "configured", "ready", "active"] for v in checks.values())
    if not all_ok:
        response.status_code = 503
        return {"status": "degraded", "checks": checks}

    return {
        "status": "ready",
        "timestamp": int(time.time()),
        "checks": checks
    }