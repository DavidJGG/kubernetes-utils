# Wait for Falco alert to appear in Elasticsearch
# Usage: ./wait-alert.ps1 <rule-name>

param(
    [Parameter(Mandatory=$true)]
    [string]$RuleName,
    [int]$TimeoutSeconds = 60
)

Write-Host "Waiting for Falco alert: $RuleName..." -ForegroundColor Yellow

$startTime = Get-Date
$alertFound = $false
$encodedRule = [System.Uri]::EscapeDataString("*$RuleName*")

while (-not $alertFound -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    try {
        $response = curl -s "http://localhost:9200/falco-alerts/_search?q=rule.keyword:$encodedRule+AND+output_fields.k8smeta.ns.name:wiredbrain&size=1" 2>$null | ConvertFrom-Json
        if ($response.hits.total.value -gt 0) {
            $alertFound = $true
        }
    } catch {
        # ES not ready or index doesn't exist yet
    }

    if (-not $alertFound) {
        Start-Sleep -Seconds 2
    }
}

if ($alertFound) {
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    Write-Host "`nAlert found (${elapsed}s)" -ForegroundColor Green
} else {
    Write-Host "`nTimeout waiting for alert" -ForegroundColor Red
    exit 1
}
