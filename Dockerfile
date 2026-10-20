# ==============================================================================
# Production Deterministic & Reproducible Multi-Stage Dockerfile
# Service: Nyaga Law Advocates — Legal Remuneration Engine & FastAPI Backend
# Architecture: AMD64 / ARM64 Compatible (Debian 12 Bookworm Slim)
# Security Standard: CIS Docker Benchmark 4.1 (Non-root user UID 10001)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Dependency Compiler & Virtualenv Builder
# Pinned Base: python:3.11.8-slim-bookworm for deterministic layer caching
# ------------------------------------------------------------------------------
FROM python:3.11.8-slim-bookworm AS builder

# Set build-time environment controls for deterministic pip compilation
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

# Install minimal compiler tools strictly needed for building C-extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential=12.9 \
    && rm -rf /var/lib/apt/lists/*

# Create isolated Python virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy pinned dependencies and install
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip==24.0 setuptools==69.1.0 wheel==0.42.0 && \
    pip install --no-cache-dir -r requirements.txt

# ------------------------------------------------------------------------------
# Stage 2: Runtime Production Image (Zero Compiler Tools, Non-Root Execution)
# ------------------------------------------------------------------------------
FROM python:3.11.8-slim-bookworm AS runner

# Metadata for Container Registries & Audit Scanners
LABEL org.opencontainers.image.title="Nyaga Law Remuneration Engine" \
      org.opencontainers.image.description="FastAPI service for Advocates Remuneration Order calculations and legal fee notes" \
      org.opencontainers.image.version="1.1.0" \
      org.opencontainers.image.vendor="Nyagah B. Kithinji & Co. Advocates" \
      org.opencontainers.image.licenses="Proprietary"

# Enforce secure runtime environment flags
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    PATH="/opt/venv/bin:$PATH"

# 1. Create unprivileged system group & user (UID/GID 10001)
# Eliminates container breakout vulnerabilities by preventing root process execution
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /sbin/nologin -d /app -M appuser

# 2. Install curl strictly for container liveness/readiness probes, purge cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl=7.88.1-10+deb12u8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. Copy compiled virtual environment from builder stage
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv

# 4. Copy application source with strict non-root ownership
COPY --chown=appuser:appgroup . /app

# Switch to non-root unprivileged runtime user
USER appuser

EXPOSE 8000

# 5. Native Container Health Probe: checks process responsiveness every 30 seconds
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

# 6. Launch ASGI server with graceful termination handling (SIGTERM)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
