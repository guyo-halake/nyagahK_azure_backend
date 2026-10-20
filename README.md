# Nyaga Law — Remuneration API & Infrastructure

FastAPI microservice that calculates legal fees and taxation bills under the Kenyan Advocates Remuneration Order (LN 64/1962, 2014 Amendment).

Frontend repository: [nyagakithinji-Bill-of-Costs](https://github.com/guyo-halake/nyagakithinji-Bill-of-Costs).

## Tech Stack
- **API**: Python 3.11, FastAPI, Pydantic, Uvicorn
- **Container**: Multi-stage Docker (non-root `appuser`, CIS compliant)
- **Cloud**: Azure App Service (Linux), Azure Container Registry (ACR), VNet
- **IaC**: Terraform (`azurerm` provider)
- **CI/CD**: GitHub Actions (Pytest, Trivy container scanner, Azure deploy)

## Quick Start

### Direct (Python)
```bash
python -m venv .venv
source .venv/bin/activate    # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

### Docker
```bash
docker compose up --build
```
- API Docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/api/v1/health`

## System Specifications
- **Runtime Environment**: Python 3.11-slim (Debian Linux base), Uvicorn ASGI worker
- **Container Security**: Multi-stage distroless build, non-root user (UID 10001 `appuser`), read-only rootfs capable
- **Cloud Infrastructure**: Azure App Service (Linux B1 Basic / P1v3 Production), Azure Container Registry (Premium with Private Link)
- **Networking & Isolation**: Azure Virtual Network (10.0.0.0/16) with App Service VNet Integration & subnet delegation
- **Database & Persistence**: Supabase PostgreSQL over TLS 1.3 with connection pooling
- **Telemetry & Monitoring**: Azure Monitor, Log Analytics workspace, automated daily health audit workflow

## Testing
```bash
python -m pytest app/tests -v
```

## Infrastructure (Terraform)
Located in `azure/terraform/`:
- `network.tf`: VNet and Subnets with App Service delegation
- `acr.tf`: Container Registry with Managed Identity (passwordless)
- `app_service.tf`: Web App with Staging/Production slots for zero-downtime swaps
- `monitoring.tf`: Log Analytics workspace and alert rules

See `azure/INCIDENT_RESPONSE_RUNBOOK.md` for triage steps and rollback commands.
