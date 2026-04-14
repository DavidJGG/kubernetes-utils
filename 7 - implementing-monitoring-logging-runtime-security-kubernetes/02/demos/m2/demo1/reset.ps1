# Reset Falco alerts in Elasticsearch for retesting
# Usage: ./reset.ps1

Write-Host "Deleting Falco alerts from Elasticsearch..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Method Delete -Uri "http://localhost:9200/falco-alerts" -ErrorAction Stop
    Write-Host "Index deleted" -ForegroundColor Green
}
catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "Index doesn't exist" -ForegroundColor Gray
    }
    else {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

Write-Host "Restarting Fluent Bit to re-read logs..." -ForegroundColor Yellow
kubectl rollout restart daemonset/fluent-bit -n logging
kubectl rollout status daemonset/fluent-bit -n logging --timeout=60s

Write-Host "Reset complete - alerts will be re-indexed" -ForegroundColor Cyan
