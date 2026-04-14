# Teardown script for Demo 1: Audit Policies and Centralised Log Collection
# Deletes the k3d cluster and all resources

Write-Host "Tearing down Demo 1 resources..." -ForegroundColor Cyan

# Delete the k3d cluster (removes everything)
Write-Host "`nDeleting k3d cluster..." -ForegroundColor Yellow
k3d cluster delete m1-demo1

Write-Host "`nTeardown complete!" -ForegroundColor Green
