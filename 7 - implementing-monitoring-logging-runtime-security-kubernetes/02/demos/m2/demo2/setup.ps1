# Setup script for Demo 2: Custom Rules and Prometheus Integration
# Creates k3d cluster and deploys WiredBrain app. Falco and Prometheus deployed during demo.

Write-Host "Setting up Demo 2: Custom Rules and Prometheus Integration" -ForegroundColor Cyan

$demoDir = $PSScriptRoot
if (-not $demoDir) { $demoDir = Get-Location }

# Create k3d cluster
Write-Host "`nCreating k3d cluster..." -ForegroundColor Yellow
k3d cluster create --config "$demoDir/k3d-config.yaml"

# Wait for cluster to be ready
Write-Host "`nWaiting for cluster to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Mount tracefs (required for Falco)
Write-Host "`nConfiguring node..." -ForegroundColor Yellow
docker exec k3d-m2-demo2-server-0 sh -c 'mount -t tracefs nodev /sys/kernel/tracing 2>/dev/null || true'

# Import images to k3d (pull only if not already present locally)
Write-Host "`nImporting images..." -ForegroundColor Yellow
$images = @(
    "sixeyed/wiredbrain-web:k8s-logging-m1",
    "sixeyed/wiredbrain-products-api:k8s-logging-m1",
    "sixeyed/wiredbrain-stock-api:k8s-logging-m1",
    "sixeyed/wiredbrain-db:k8s-logging-m1",
    "docker.io/falcosecurity/falco:0.42.1",
    "docker.io/falcosecurity/falcoctl:0.12.0",
    "docker.io/falcosecurity/falcosidekick:2.30.0",
    "quay.io/prometheus/prometheus:v3.1.0",
    "busybox:latest",
    "bash:5"
)
foreach ($image in $images) {
    if (-not (docker images -q $image)) {
        Write-Host "Pulling $image..." -ForegroundColor Gray
        docker pull $image
    }
    Write-Host "Importing $image..." -ForegroundColor Gray
    if ($image -eq "docker.io/falcosecurity/falco:0.42.1") {
        # Use direct ctr import for falco image (k3d import has issues with this image)
        docker save $image | docker exec -i k3d-m2-demo2-server-0 ctr --namespace k8s.io images import -
    } else {
        k3d image import $image -c m2-demo2
    }
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
Write-Host "k3d cluster 'm2-demo2' created"
Write-Host "WiredBrain app deployed to 'wiredbrain' namespace"
Write-Host "`nDeploy Falco, Falcosidekick, and Prometheus during the demo walkthrough"
