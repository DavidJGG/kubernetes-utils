# Wait for Prometheus to be scraping Falcosidekick successfully
# This ensures the metrics pipeline is ready before triggering events

param(
    [int]$TimeoutSeconds = 180
)

Write-Host "Waiting for Prometheus to scrape Falcosidekick..." -ForegroundColor Yellow

$startTime = Get-Date
$pipelineReady = $false

while (-not $pipelineReady -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    try {
        $response = curl -s "http://localhost:9090/api/v1/targets" 2>$null | ConvertFrom-Json
        $sidekickTargets = $response.data.activeTargets | Where-Object { $_.labels.job -eq "falcosidekick" -and $_.health -eq "up" }

        if ($sidekickTargets.Count -gt 0) {
            $pipelineReady = $true
        }
    } catch {
        # Prometheus not ready yet
    }

    if (-not $pipelineReady) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 3
    }
}

if ($pipelineReady) {
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    Write-Host "`nPrometheus scraping Falcosidekick (${elapsed}s)" -ForegroundColor Green
} else {
    Write-Host "`nTimeout waiting for Prometheus" -ForegroundColor Red
    exit 1
}
