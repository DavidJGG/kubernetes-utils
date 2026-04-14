# Teardown script for Demo 2: Building Security Alerting Rules with Prometheus
# Deletes the k3d cluster and all resources

Write-Host "Tearing down Demo 2 resources..." -ForegroundColor Cyan

# Delete the k3d cluster
Write-Host "`nDeleting k3d cluster..." -ForegroundColor Yellow
k3d cluster delete m1-demo2

Write-Host "`nTeardown complete!" -ForegroundColor Green
