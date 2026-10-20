# Nyaga Law — Remuneration API & Infrastructure

FastAPI microservice that calculates legal fees and taxation bills under the Kenyan Advocates Remuneration Order (LN 64/1962, 2014 Amendment).

Frontend repository: [nyagakithinji-Bill-of-Costs](https://github.com/guyo-halake/nyagakithinji-Bill-of-Costs).

## Tech Stack
- **API**: Python 3.11, FastAPI, Pydantic, Uvicorn
- **Container**: Multi-stage Docker (non-root \ppuser\, CIS compliant)
- **Cloud**: Azure App Service (Linux), Azure Container Registry (ACR), VNet
- **IaC**: Terraform (\zurerm\ provider)
- **CI/CD**: GitHub Actions (Pytest, Trivy container scanner, Azure deploy)

## Quick Start

### Direct (Python)
\\ash
python -m venv .venv
source .venv/bin/activate    # or .venv\\Scripts\\activate on Windows
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
\
### Docker
\\ash
docker compose up --build
\- API Docs: \http://localhost:8000/docs- Health check: \http://localhost:8000/api/v1/health
## Testing
\\ash
python -m pytest app/tests -v
\
## Infrastructure (Terraform)
Located in \zure/terraform/\:
- etwork.tf\: VNet and Subnets with App Service delegation
- \cr.tf\: Container Registry with Managed Identity (passwordless)
- \pp_service.tf\: Web App with Staging/Production slots for zero-downtime swaps
- \monitoring.tf\: Log Analytics workspace and alert rules

See \zure/INCIDENT_RESPONSE_RUNBOOK.md\ for triage steps and rollback commands.
