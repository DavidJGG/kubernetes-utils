# Teardown script for Demo 2
Write-Host "Tearing down Demo 2 environment..." -ForegroundColor Cyan

Write-Host "`nDeleting k3d cluster 'm2-demo2'..." -ForegroundColor Yellow
k3d cluster delete m2-demo2

Write-Host "`nTeardown complete!" -ForegroundColor Green
