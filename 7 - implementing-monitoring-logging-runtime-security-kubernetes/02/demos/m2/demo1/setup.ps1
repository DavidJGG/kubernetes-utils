# Setup script for Demo 1: Deploying Falco and Detecting Container Threats
# Creates k3d cluster with WiredBrain, Elasticsearch, and Fluent Bit
# Falco is deployed during the demo walkthrough

Write-Host "Setting up Demo 1: Deploying Falco and Detecting Container Threats" -ForegroundColor Cyan

$demoDir = $PSScriptRoot
if (-not $demoDir) { $demoDir = Get-Location }

# Create k3d cluster
Write-Host "`nCreating k3d cluster..." -ForegroundColor Yellow
k3d cluster create --config "$demoDir/k3d-config.yaml"

# Wait for cluster to be ready
Write-Host "`nWaiting for cluster to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Create machine-id file (required by Fluent Bit) and mount tracefs (required for Falco)
Write-Host "`nConfiguring node..." -ForegroundColor Yellow
docker exec k3d-m2-demo1-server-0 sh -c 'cat /proc/sys/kernel/random/uuid | tr -d - > /etc/machine-id'
docker exec k3d-m2-demo1-server-0 sh -c 'mount -t tracefs nodev /sys/kernel/tracing 2>/dev/null || true'

# Import images to k3d (pull only if not already present locally)
Write-Host "`nImporting images..." -ForegroundColor Yellow
$images = @(
    "sixeyed/wiredbrain-web:k8s-logging-m1",
    "sixeyed/wiredbrain-products-api:k8s-logging-m1",
    "sixeyed/wiredbrain-stock-api:k8s-logging-m1",
    "sixeyed/wiredbrain-db:k8s-logging-m1",
    "docker.io/falcosecurity/falco:0.42.1",
    "docker.io/falcosecurity/falcoctl:0.12.0",
    "docker.elastic.co/elasticsearch/elasticsearch:8.5.1",
    "cr.fluentbit.io/fluent/fluent-bit:4.0.1",
    "busybox:latest"
)
foreach ($image in $images) {
    if (-not (docker images -q $image)) {
        Write-Host "Pulling $image..." -ForegroundColor Gray
        docker pull $image
    }
    Write-Host "Importing $image..." -ForegroundColor Gray
    if ($image -eq "docker.io/falcosecurity/falco:0.42.1") {
        # Use direct ctr import for falco image (k3d import has issues with this image)
        docker save $image | docker exec -i k3d-m2-demo1-server-0 ctr --namespace k8s.io images import -
    } else {
        k3d image import $image -c m2-demo1
    }
}
# Create logging namespace
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

# Deploy Elasticsearch for alert storage
Write-Host "`nDeploying Elasticsearch..." -ForegroundColor Yellow
kubectl apply -f "$demoDir/elasticsearch.yaml"
kubectl wait --for=condition=Ready pod -n logging -l app=elasticsearch --timeout=120s

# Deploy Fluent Bit to collect Falco logs
Write-Host "`nDeploying Fluent Bit..." -ForegroundColor Yellow
helm upgrade --install fluent-bit "$demoDir/charts/fluent-bit-0.49.0.tgz" `
    -f "$demoDir/fluent-bit-values.yaml" `
    --namespace logging `
    --wait

# Verify deployment
Write-Host "`nVerifying deployment..." -ForegroundColor Yellow
kubectl get pods -n logging

# Deploy WiredBrain application
Write-Host "`nDeploying WiredBrain application..." -ForegroundColor Yellow
helm upgrade --install wiredbrain "$demoDir/../../charts/wiredbrain" `
    --namespace wiredbrain --create-namespace `
    --wait

# Verify deployment
Write-Host "`nVerifying deployment..." -ForegroundColor Yellow
kubectl get pods -n wiredbrain

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "k3d cluster 'm2-demo1' created"
Write-Host "WiredBrain app deployed to 'wiredbrain' namespace"
Write-Host "Elasticsearch + Fluent Bit deployed to 'logging' namespace"
Write-Host "`nDeploy Falco during the demo walkthrough"
