# Wait for Falco pipeline to be fully initialized
# Verifies: Falco detecting events AND alerts flowing to Elasticsearch
# Run this after deploying Falco to ensure the full pipeline is ready

param(
    [int]$TimeoutSeconds = 300
)

Write-Host "Waiting for Falco to initialize..." -ForegroundColor Yellow

$startTime = Get-Date
$falcoReady = $false

# Phase 1: Wait for Falco to detect events
while (-not $falcoReady -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    # Check if Falco pod is ready
    $podReady = kubectl get pods -n falco -l app.kubernetes.io/name=falco -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
    if ($podReady -ne "true") {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
        continue
    }

    # Trigger a test event and check if Falco detects it
    kubectl exec -n falco daemonset/falco -c falco -- cat /etc/shadow 2>$null | Out-Null
    Start-Sleep -Seconds 2

    $logs = kubectl logs -n falco daemonset/falco -c falco --since=5s 2>$null
    if ($logs -match '"rule"') {
        $falcoReady = $true
    } else {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
    }
}

if (-not $falcoReady) {
    Write-Host "`nTimeout waiting for Falco" -ForegroundColor Red
    exit 1
}

Write-Host "`nFalco is detecting events" -ForegroundColor Green

# Phase 2: Wait for alerts to reach Elasticsearch
Write-Host "Waiting for Elasticsearch pipeline..." -ForegroundColor Yellow

$esReady = $false

while (-not $esReady -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    # Check if any alerts have reached Elasticsearch
    try {
        $response = curl -s "http://localhost:9200/falco-alerts/_count" 2>$null | ConvertFrom-Json
        if ($response.count -gt 0) {
            $esReady = $true
        } else {
            Start-Sleep -Seconds 5
        }
    } catch {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 5
    }
}

if ($esReady) {
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    Write-Host "`nPipeline ready (${elapsed}s)" -ForegroundColor Green
} else {
    Write-Host "`nTimeout waiting for Elasticsearch" -ForegroundColor Red
    exit 1
}
