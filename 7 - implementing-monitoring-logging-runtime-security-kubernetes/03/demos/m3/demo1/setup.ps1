# Setup script for Demo 1: Pod Security Standards and Namespace Isolation
# Creates k3d cluster and deploys WiredBrain app without PSA enforcement

Write-Host "Setting up Demo 1: Pod Security Standards" -ForegroundColor Cyan

$demoDir = $PSScriptRoot
if (-not $demoDir) { $demoDir = Get-Location }

# Create k3d cluster
Write-Host "`nCreating k3d cluster..." -ForegroundColor Yellow
k3d cluster create --config "$demoDir/k3d-config.yaml"

# Wait for cluster to be ready
Write-Host "`nWaiting for cluster to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Import images to k3d (pull only if not already present locally)
Write-Host "`nImporting images..." -ForegroundColor Yellow
$images = @(
    "sixeyed/wiredbrain-web:k8s-logging-m1",
    "sixeyed/wiredbrain-products-api:k8s-logging-m1",
    "sixeyed/wiredbrain-stock-api:k8s-logging-m1",
    "sixeyed/wiredbrain-db:k8s-logging-m1",
    "busybox:latest"
)
foreach ($image in $images) {
    if (-not (docker images -q $image)) {
        Write-Host "Pulling $image..." -ForegroundColor Gray
        docker pull $image
    }
    Write-Host "Importing $image..." -ForegroundColor Gray
    docker save $image | docker exec -i k3d-m3-demo1-server-0 ctr --namespace k8s.io images import -
}

# Deploy WiredBrain application
Write-Host "`nDeploying WiredBrain application..." -ForegroundColor Yellow
helm upgrade --install wiredbrain "$demoDir/../../charts/wiredbrain" `
    --namespace wiredbrain --create-namespace `
    --wait

# Verify deployment
Write-Host "`nVerifying deployment..." -ForegroundColor Yellow
kubectl get pods -n wiredbrain

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "k3d cluster 'm3-demo1' created"
Write-Host "WiredBrain app deployed to 'wiredbrain' namespace (no PSA enforcement)"
