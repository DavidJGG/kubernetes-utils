# Teardown script for Demo 1: Implementing Network Policies
# This script removes all resources created during the demo
#
# Usage:
#   ./teardown.ps1              # Clean up app and policies only
#   ./teardown.ps1 -Cluster     # Clean up everything including k3d cluster

param(
    [switch]$Cluster = $false
)

Write-Host "Starting cleanup..." -ForegroundColor Cyan

# Delete network policies
Write-Host "`nDeleting network policies..." -ForegroundColor Yellow
kubectl delete -f ./egress-control/ --ignore-not-found=true 2>$null
kubectl delete -f ./allow-policies/ --ignore-not-found=true 2>$null
kubectl delete -f ./default-deny/ --ignore-not-found=true 2>$null

# Delete application resources and namespace
Write-Host "`nDeleting application resources..." -ForegroundColor Yellow
kubectl delete -f ./initial-deploy/ --ignore-not-found=true 2>$null

# Verify namespace deletion
Write-Host "Waiting for namespace deletion..." -ForegroundColor Yellow
$timeout = 30
$elapsed = 0
while ((kubectl get namespace wiredbrain 2>$null) -and ($elapsed -lt $timeout)) {
    Start-Sleep -Seconds 2
    $elapsed += 2
    Write-Host "." -NoNewline -ForegroundColor Yellow
}
Write-Host ""

if (kubectl get namespace wiredbrain 2>$null) {
    Write-Host "WARNING: Namespace 'wiredbrain' still exists" -ForegroundColor Yellow
    Write-Host "It may take a few more moments to fully terminate" -ForegroundColor Yellow
} else {
    Write-Host "Namespace 'wiredbrain' deleted successfully" -ForegroundColor Green
}

# Optional: Delete k3d cluster
if ($Cluster) {
    Write-Host "`nDeleting k3d cluster..." -ForegroundColor Yellow
    k3d cluster delete networkpolicy-demo 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "k3d cluster 'networkpolicy-demo' deleted successfully" -ForegroundColor Green
    } else {
        Write-Host "k3d cluster 'networkpolicy-demo' not found or already deleted" -ForegroundColor Gray
    }
} else {
    Write-Host "`nk3d cluster 'networkpolicy-demo' is still running" -ForegroundColor Cyan
    Write-Host "To delete the cluster, run: ./teardown.ps1 -Cluster" -ForegroundColor Gray
}

Write-Host "`nCleanup complete!" -ForegroundColor Green
if ($Cluster) {
    Write-Host "All resources including k3d cluster have been removed." -ForegroundColor Green
} else {
    Write-Host "All network policies and application resources have been removed." -ForegroundColor Green
}
