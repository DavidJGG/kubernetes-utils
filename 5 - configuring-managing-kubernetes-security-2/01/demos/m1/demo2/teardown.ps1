# Demo 2 Teardown: Remove AKS Cluster and Resources
# This script removes all resources created for the demo

# Configuration variables (must match setup.ps1)
$resourceGroup = "rg-k8s-security-m1"
$clusterName = "aks-k8s-security-m1"

Write-Host "Demo 2 Teardown: AKS Cluster with Azure AD Integration" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Check if Azure CLI is installed and user is logged in
Write-Host "`nChecking Azure CLI login status..." -ForegroundColor Cyan
$loginStatus = az account show 2>$null
if (-not $loginStatus) {
    Write-Host "Please login to Azure CLI first using 'az login'" -ForegroundColor Red
    exit 1
}

# Display current subscription
$subscription = az account show --query "{Name:name, ID:id}" -o table
Write-Host "`nUsing Azure subscription:" -ForegroundColor Green
Write-Host $subscription

# Check if resource group exists
Write-Host "`nChecking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $resourceGroup

if ($rgExists -eq "false") {
    Write-Host "Resource group '$resourceGroup' does not exist. Nothing to clean up." -ForegroundColor Yellow
    exit 0
}

# Display resources to be deleted
Write-Host "`nResources in resource group '$resourceGroup':" -ForegroundColor Yellow
az resource list --resource-group $resourceGroup --query "[].{Name:name, Type:type}" -o table

# Prompt for confirmation
Write-Host "`nWARNING: This will delete the entire resource group and all resources within it." -ForegroundColor Red
$confirm = Read-Host "Are you sure you want to continue? Type 'yes' to confirm"

if ($confirm -ne 'yes') {
    Write-Host "Teardown cancelled." -ForegroundColor Yellow
    exit 0
}

# Delete the resource group (this deletes everything in it)
Write-Host "`nDeleting resource group: $resourceGroup..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

az group delete `
    --name $resourceGroup `
    --yes `
    --no-wait

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to initiate resource group deletion" -ForegroundColor Red
    exit 1
}

Write-Host "`nResource group deletion initiated." -ForegroundColor Green
Write-Host "Deletion is running in the background. To check status, run:" -ForegroundColor Cyan
Write-Host "  az group show --name $resourceGroup" -ForegroundColor White

# Remove cluster from kubectl config
Write-Host "`nRemoving cluster from kubectl config..." -ForegroundColor Cyan
kubectl config delete-context $clusterName 2>$null
kubectl config delete-cluster $clusterName 2>$null

Write-Host "`n================================" -ForegroundColor Green
Write-Host "Teardown Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`nThe resource group deletion is in progress."
Write-Host "You can verify completion with:"
Write-Host "  az group list --query \"[?name=='$resourceGroup']\" -o table"
