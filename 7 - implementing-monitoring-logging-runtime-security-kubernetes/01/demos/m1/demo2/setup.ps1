# Setup script for Demo 2: Building Security Alerting Rules with Prometheus
# Creates k3d cluster with audit logging - monitoring stack deployed during demo

Write-Host "Setting up Demo 2: Security Alerting with Prometheus" -ForegroundColor Cyan

# Create k3d cluster with audit logging
Write-Host "`nCreating k3d cluster with audit logging..." -ForegroundColor Yellow
k3d cluster create --config k3d-config.yaml

# Wait for cluster to be ready
Write-Host "`nWaiting for cluster to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Create audit log directory
Write-Host "`nConfiguring audit log directory..." -ForegroundColor Yellow
docker exec k3d-m1-demo2-server-0 mkdir -p /var/log/kubernetes/audit

# Import images to k3d (pull only if not already present locally)
# Note: Using docker save | ctr import as k3d image import is unreliable
Write-Host "`nImporting images..." -ForegroundColor Yellow
$images = @(
    "sixeyed/wiredbrain-web:k8s-logging-m1",
    "sixeyed/wiredbrain-products-api:k8s-logging-m1",
    "sixeyed/wiredbrain-stock-api:k8s-logging-m1",
    "sixeyed/wiredbrain-db:k8s-logging-m1",
    "cr.fluentbit.io/fluent/fluent-bit:4.0.1",
    "quay.io/prometheus/prometheus:v3.1.0",
    "quay.io/prometheus/alertmanager:v0.27.0",
    "busybox:latest"
)
foreach ($image in $images) {
    if (-not (docker images -q $image)) {
        Write-Host "Pulling $image..." -ForegroundColor Gray
        docker pull $image
    }
    Write-Host "Importing $image..." -ForegroundColor Gray
    docker save $image | docker exec -i k3d-m1-demo2-server-0 ctr --namespace k8s.io images import -
}

# Deploy WiredBrain application
Write-Host "`nDeploying WiredBrain application..." -ForegroundColor Yellow
helm upgrade --install wiredbrain ../../charts/wiredbrain `
    --namespace wiredbrain --create-namespace `
    --wait

# Verify deployment
Write-Host "`nVerifying deployment..." -ForegroundColor Yellow
kubectl get pods -n wiredbrain

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "k3d cluster 'm1-demo2' created with audit logging enabled"
Write-Host "WiredBrain app deployed to 'wiredbrain' namespace"
Write-Host "`nDeploy Fluent Bit and Prometheus during the demo walkthrough"
