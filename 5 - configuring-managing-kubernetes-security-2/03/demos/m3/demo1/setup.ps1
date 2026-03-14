# Setup script for Demo 1: Implementing Network Policies
# This script prepares the environment for the network policy demo using k3d

Write-Host "Starting setup for Network Policies demo..." -ForegroundColor Cyan

# Check if k3d is available
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: k3d is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install k3d:" -ForegroundColor Yellow
    Write-Host "  macOS:   brew install k3d" -ForegroundColor Cyan
    Write-Host "  Windows: choco install k3d" -ForegroundColor Cyan
    Write-Host "  Linux:   wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash" -ForegroundColor Cyan
    exit 1
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if k3d cluster exists
Write-Host "Checking for k3d cluster 'networkpolicy-demo'..." -ForegroundColor Yellow
$clusterExists = k3d cluster list 2>&1 | Select-String "networkpolicy-demo"

if (-not $clusterExists) {
    Write-Host "Creating k3d cluster with NetworkPolicy support..." -ForegroundColor Cyan
    k3d cluster create networkpolicy-demo `
        --agents 1 `
        --k3s-arg "--disable=traefik@server:0" `
        --port "8001:8001@loadbalancer"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create k3d cluster" -ForegroundColor Red
        exit 1
    }

    Write-Host "Waiting for cluster to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
} else {
    Write-Host "k3d cluster 'networkpolicy-demo' already exists" -ForegroundColor Green
    Write-Host "Setting kubectl context..." -ForegroundColor Yellow
    kubectl config use-context k3d-networkpolicy-demo 2>$null
}

$context = kubectl config current-context
Write-Host "Connected to Kubernetes cluster: $context" -ForegroundColor Green

# Verify NetworkPolicy support
Write-Host "`nVerifying NetworkPolicy support..." -ForegroundColor Yellow
$apiResources = kubectl api-resources | Select-String "networkpolicies"
if (-not $apiResources) {
    Write-Host "WARNING: NetworkPolicy resources not found in cluster" -ForegroundColor Red
    Write-Host "This demo requires NetworkPolicy support" -ForegroundColor Red
    exit 1
} else {
    Write-Host "NetworkPolicy API is available" -ForegroundColor Green
}

# Verify NetworkPolicy support in k3s
Write-Host "`nVerifying NetworkPolicy support in k3s..." -ForegroundColor Yellow
$k3sVersion = kubectl version --short 2>&1 | Select-String "Server Version"
if ($k3sVersion) {
    Write-Host "k3s cluster is running with built-in NetworkPolicy support" -ForegroundColor Green
    Write-Host "$k3sVersion" -ForegroundColor Gray
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "You can now follow the demo steps in README.md" -ForegroundColor Green
Write-Host "`nTo get started, run:" -ForegroundColor Cyan
Write-Host "  kubectl apply -f ./initial-deploy/" -ForegroundColor White
