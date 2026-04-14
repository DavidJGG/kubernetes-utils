# Wait for Prometheus alerts to fire
# Usage: ./wait-alerts.ps1

Write-Host "Waiting for alerts to fire..." -ForegroundColor Yellow

while ($true) {
    $response = curl -s http://localhost:9090/api/v1/alerts 2>$null
    if ($response -match '"state":"firing"') {
        break
    }
    Start-Sleep -Seconds 5
}

Write-Host "Alerts are firing" -ForegroundColor Green
