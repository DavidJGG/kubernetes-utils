# Teardown script for Demo 1
Write-Host "Tearing down Demo 1 environment..." -ForegroundColor Cyan

Write-Host "`nDeleting k3d cluster 'm3-demo1'..." -ForegroundColor Yellow
k3d cluster delete m3-demo1

Write-Host "`nTeardown complete!" -ForegroundColor Green
