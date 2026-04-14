# Teardown script for Demo 1: Deploying Falco and Detecting Container Threats
# Deletes the k3d cluster and all resources

Write-Host "Tearing down Demo 1 environment..." -ForegroundColor Cyan

# Delete k3d cluster
Write-Host "`nDeleting k3d cluster 'm2-demo1'..." -ForegroundColor Yellow
k3d cluster delete m2-demo1

Write-Host "`nTeardown complete!" -ForegroundColor Green
