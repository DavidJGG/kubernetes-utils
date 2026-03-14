# Demo 2 Setup: AKS Cluster for MFA and RBAC Demo
# This script creates a basic AKS cluster without Azure AD integration (to be enabled during the demo)

# Configuration variables
$resourceGroup = "rg-k8s-security-m1"
$location = "westeurope"
$clusterName = "aks-k8s-security-m1"
$nodeCount = 1
$nodeSize = "Standard_D2as_v5"

# Check if Azure CLI is installed and user is logged in
Write-Host "Checking Azure CLI login status..." -ForegroundColor Cyan
$loginStatus = az account show 2>$null
if (-not $loginStatus) {
    Write-Host "Please login to Azure CLI first using 'az login'" -ForegroundColor Red
    exit 1
}

# Display current subscription
$subscription = az account show --query "{Name:name, ID:id}" -o table
Write-Host "`nUsing Azure subscription:" -ForegroundColor Green
Write-Host $subscription

# Prompt for confirmation
$confirm = Read-Host "`nDo you want to continue with this subscription? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Setup cancelled. Use 'az account set --subscription <subscription-id>' to change subscription." -ForegroundColor Yellow
    exit 0
}

# Create resource group
Write-Host "`nCreating resource group: $resourceGroup in $location..." -ForegroundColor Cyan
az group create `
    --name $resourceGroup `
    --location $location `
    --tags "demo=k8s-security" "module=m1" "demo=demo2"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create resource group" -ForegroundColor Red
    exit 1
}

# Create basic AKS cluster without Azure AD integration
Write-Host "`nCreating AKS cluster: $clusterName..." -ForegroundColor Cyan
Write-Host "This will take several minutes..." -ForegroundColor Yellow

az aks create `
    --resource-group $resourceGroup `
    --name $clusterName `
    --node-count $nodeCount `
    --node-vm-size $nodeSize

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create AKS cluster" -ForegroundColor Red
    exit 1
}

# Get cluster credentials
Write-Host "`nGetting cluster credentials..." -ForegroundColor Cyan
az aks get-credentials `
    --resource-group $resourceGroup `
    --name $clusterName `
    --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get cluster credentials" -ForegroundColor Red
    exit 1
}

# Display cluster information
Write-Host "`nCluster created successfully!" -ForegroundColor Green
Write-Host "`nCluster details:" -ForegroundColor Cyan
az aks show `
    --resource-group $resourceGroup `
    --name $clusterName `
    --query "{Name:name, Location:location, KubernetesVersion:kubernetesVersion, NodeCount:agentPoolProfiles[0].count}" `
    -o table

# Test kubectl access
Write-Host "`nTesting kubectl access..." -ForegroundColor Cyan
Write-Host "Note: Cluster is configured for local kubeconfig authentication (no Azure AD yet)..." -ForegroundColor Yellow

kubectl get nodes

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nWarning: kubectl access failed. Check your credentials." -ForegroundColor Red
} else {
    Write-Host "`nkubectl access verified!" -ForegroundColor Green
}

# Display next steps
Write-Host "`n================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`nResource Group: $resourceGroup"
Write-Host "Cluster Name: $clusterName"
Write-Host "Location: $location"
Write-Host "`nThe cluster is now ready for the demo:"
Write-Host "1. Verify kubectl access with local kubeconfig authentication"
Write-Host "2. Enable Azure AD integration during the demo"
Write-Host "3. Demonstrate kubelogin and device code flow"
Write-Host "4. Test MFA and RBAC permissions"
Write-Host "`nRefer to README.md for the complete demo flow."
Write-Host "`nTo clean up, run: ./teardown.ps1"
