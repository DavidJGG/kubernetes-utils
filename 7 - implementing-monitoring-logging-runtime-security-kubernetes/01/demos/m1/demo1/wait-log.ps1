# Wait for log files to be available
# Usage: ./wait-log.ps1 <filename>
#   audit.log    - waits for Fluent Bit to start tailing the audit log
#   filtered.log - waits for filtered log file to be created

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile
)

switch ($LogFile) {
    "audit.log" {
        Write-Host "Waiting for Fluent Bit to tail audit log..." -ForegroundColor Yellow
        while (-not (kubectl logs -n logging -l app.kubernetes.io/name=fluent-bit 2>$null | Select-String 'audit.log')) {
            Start-Sleep -Seconds 5
        }
        Write-Host "Fluent Bit is tailing audit log" -ForegroundColor Green
    }
    "filtered.log" {
        Write-Host "Waiting for filtered log file..." -ForegroundColor Yellow
        while ($true) {
            kubectl exec -n kube-system log-reader -- test -f /var/log/kubernetes/audit/filtered.log 2>$null
            if ($LASTEXITCODE -eq 0) { break }
            Start-Sleep -Seconds 5
        }
        Write-Host "Filtered log file created" -ForegroundColor Green
    }
    default {
        Write-Error "Unknown log file: $LogFile. Use 'audit.log' or 'filtered.log'"
        exit 1
    }
}
