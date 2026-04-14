# Teardown script for Demo 2
Write-Host "Tearing down Demo 2 environment..." -ForegroundColor Cyan

Write-Host "`nDeleting k3d cluster 'm3-demo2'..." -ForegroundColor Yellow
k3d cluster delete m3-demo2

Write-Host "`nTeardown complete!" -ForegroundColor Green
