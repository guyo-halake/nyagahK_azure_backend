# 🚨 Production Incident Response Runbook & SRE Investigation Guide
> Service: **Nyaga Law Practice Management & Statutory Remuneration Engine**
> Cloud: **Microsoft Azure (ACR, App Service, Log Analytics, Application Insights)**

---

## 1. Incident Severity Classification

| Severity Level | Definition | Max Response Time | Action Required |
| :--- | :--- | :--- | :--- |
| **SEV-1 (Critical)** | Complete service outage or statutory fee calculation failure. | < 15 minutes | Immediate rollback via slot swap; notify senior partners. |
| **SEV-2 (High)** | Elevated latency (> 1.5s), elevated 5xx error rate (> 5%), or email gateway drop. | < 30 minutes | Triage logs via KQL; isolate failing dependency. |
| **SEV-3 (Medium)** | Non-blocking telemetry or UI warning; core fee calculation unaffected. | < 4 hours | Scheduled patch and deployment through `staging`. |

---

## 2. Immediate Triage Workflow (First 5 Minutes)

### Step 1: Check Live Service Health
Query the public liveness and readiness probes:
```bash
# 1. Liveness Probe
curl -i https://nyagahkithinji-advocates.azurewebsites.net/api/v1/health

# 2. Readiness Probe (Subsystem verification)
curl -i https://nyagahkithinji-advocates.azurewebsites.net/api/v1/health/ready
```

### Step 2: Emergency Zero-Downtime Rollback
If a newly deployed build in production is failing, perform an instant **Azure Slot Swap** to revert traffic back to the known good staging image:
```bash
az webapp deployment slot swap \
  --resource-group rg-nyagahfee-prod \
  --name nyagahkithinji-advocates \
  --slot staging \
  --target-slot production
```
*Effect*: Azure shifts 100% of incoming production traffic back to the prior stable slot in under 10 seconds.

---

## 3. Investigating via Azure Log Analytics (KQL Queries)

All application logs are streamed in structured JSON to the Log Analytics Workspace (`log-nyagahkithinji-advocates-production`).

### Query A: Find All 500 Internal Server Errors (Last 1 Hour)
```kusto
AppServiceConsoleLogs
| where TimeGenerated > ago(1h)
| extend LogData = parse_json(ResultDescription)
| where LogData.level == "ERROR" or LogData.status_code >= 500
| project TimeGenerated, CorrelationId = LogData.correlation_id, StatusCode = LogData.status_code, Message = LogData.message, Exception = LogData.exception
| order by TimeGenerated desc
```

### Query B: Trace an Incident by `CorrelationId` (`X-Correlation-ID`)
When an advocate reports a failed transaction with a Correlation ID from the frontend:
```kusto
AppServiceConsoleLogs
| extend LogData = parse_json(ResultDescription)
| where LogData.correlation_id == "PASTE_CORRELATION_ID_HERE"
| project TimeGenerated, LogData.level, LogData.message, LogData.latency_ms
| order by TimeGenerated asc
```

### Query C: Compute P95 and P99 Latency Percentiles
```kusto
AppServiceHTTPLogs
| where TimeGenerated > ago(6h)
| summarize P50 = percentile(TimeTaken, 50), P95 = percentile(TimeTaken, 95), P99 = percentile(TimeTaken, 99) by bin(TimeGenerated, 15m)
| render timechart
```

---

## 4. Post-Incident Review (PIR) Template

Following resolution of any SEV-1 or SEV-2 incident, complete the PIR within 24 hours:

```markdown
# 📋 Post-Incident Review (PIR): [INCIDENT-ID]

### 1. Executive Summary
- **Date / Time**: YYYY-MM-DD HH:MM UTC
- **Duration**: XX minutes
- **Impact**: e.g., "Advocates unable to generate Fee Notes between 14:00 - 14:25 UTC."
- **Root Cause**: e.g., "Missing environment variable for SMTP gateway causing 500 error in email dispatch."

### 2. Timeline (UTC)
- **14:00**: Issue initiated following commit SHA `xyz`.
- **14:05**: Azure Metric Alert `alert-high-5xx-errors` fired.
- **14:12**: SRE confirmed 500 error spikes in Log Analytics via Correlation ID.
- **14:15**: Executed `az webapp deployment slot swap` rollback to staging.
- **14:18**: Health endpoints returned 200 OK. Incident closed.

### 3. Root Cause Analysis (5 Whys)
1. Why did the fee notes fail? -> Email dispatch service threw an unhandled exception.
2. Why did it throw an exception? -> SMTP credentials were not present in the staging slot.
3. Why were they absent? -> Manual configuration drift between slots.
4. Why was it manual? -> Terraform app settings did not bind SMTP secret reference.
5. Preventative measure -> Managed identity Key Vault binding added to Terraform `app_service.tf`.

### 4. Corrective Action Items
- [ ] Add pre-deployment readiness check to `cd-azure.yml`.
- [ ] Update Terraform to enforce Key Vault secret references across all slots.
```
