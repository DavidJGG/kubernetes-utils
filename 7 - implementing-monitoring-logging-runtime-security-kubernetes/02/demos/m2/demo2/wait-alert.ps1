# Wait for a Prometheus alert to fire
# Usage: ./wait-alert.ps1 <alert-name>

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertName,
    [int]$TimeoutSeconds = 120
)

Write-Host "Waiting for alert: $AlertName..." -ForegroundColor Yellow

$startTime = Get-Date
$alertFired = $false

while (-not $alertFired -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    try {
        $response = curl -s "http://localhost:9090/api/v1/rules" 2>$null | ConvertFrom-Json
        $alert = $response.data.groups |
            ForEach-Object { $_.rules } |
            Where-Object { $_.name -eq $AlertName -and $_.state -eq "firing" }

        if ($alert) {
            $alertFired = $true
        }
    } catch {
        # Prometheus not ready yet
    }

    if (-not $alertFired) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 3
    }
}

if ($alertFired) {
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    Write-Host "`nAlert firing (${elapsed}s)" -ForegroundColor Green
} else {
    Write-Host "`nTimeout waiting for alert" -ForegroundColor Red
    exit 1
}
