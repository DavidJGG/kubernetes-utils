#!/usr/bin/env pwsh

# Azure Kubernetes Security Demo - Teardown Script
# Deletes all Azure resources created by setup.ps1
# OR stops the cluster without deleting resources (-Stop)

param(
    [string]$ResourceGroup = "psod-k8s-security-rg",
    [string]$ClusterName = "psod-aks",
    [switch]$Force,
    [switch]$Stop
)

Write-Host "==================================" -ForegroundColor Cyan
if ($Stop) {
    Write-Host "Azure K8s Demo - Stop Cluster" -ForegroundColor Cyan
} else {
    Write-Host "Azure K8s Demo - Full Teardown" -ForegroundColor Cyan
}
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check Azure CLI login
Write-Host "Checking Azure CLI authentication..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in to Azure. Running 'az login'..." -ForegroundColor Red
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Check if resource group exists
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "Resource group '$ResourceGroup' does not exist." -ForegroundColor Yellow
    Write-Host "Nothing to clean up." -ForegroundColor Green
    exit 0
}

# STOP MODE: Clean up deployments and stop cluster
if ($Stop) {
    Write-Host "Stop mode: Cleaning up deployments and stopping cluster..." -ForegroundColor Yellow
    Write-Host ""

    # Get AKS credentials if not already configured
    Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
    az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing 2>$null

    # Delete Helm release if it exists
    Write-Host "Checking for Helm releases..." -ForegroundColor Yellow
    $helmReleases = helm list -n wiredbrain -o json 2>$null | ConvertFrom-Json
    if ($helmReleases -and $helmReleases.Count -gt 0) {
        Write-Host "Uninstalling Helm release 'wiredbrain'..." -ForegroundColor Yellow
        helm uninstall wiredbrain -n wiredbrain
        Write-Host "✓ Helm release removed" -ForegroundColor Green
    } else {
        Write-Host "No Helm releases found" -ForegroundColor Gray
    }
    Write-Host ""

    # Delete wiredbrain namespace
    Write-Host "Deleting wiredbrain namespace..." -ForegroundColor Yellow
    $namespace = kubectl get namespace wiredbrain -o json 2>$null | ConvertFrom-Json
    if ($namespace) {
        kubectl delete namespace wiredbrain --wait=false
        Write-Host "✓ Namespace deletion initiated" -ForegroundColor Green
    } else {
        Write-Host "Namespace 'wiredbrain' not found" -ForegroundColor Gray
    }
    Write-Host ""

    # Stop AKS cluster
    Write-Host "Stopping AKS cluster '$ClusterName'..." -ForegroundColor Yellow
    Write-Host "  (This may take 2-3 minutes)" -ForegroundColor Gray
    az aks stop --resource-group $ResourceGroup --name $ClusterName

    Write-Host ""
    Write-Host "✓ Cluster stopped successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Stop Complete!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The AKS cluster and Key Vault are preserved but stopped." -ForegroundColor White
    Write-Host "You are not being charged for the stopped cluster nodes." -ForegroundColor Green
    Write-Host ""
    Write-Host "To restart the cluster later:" -ForegroundColor Cyan
    Write-Host "  az aks start --resource-group $ResourceGroup --name $ClusterName" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To fully delete all resources, run:" -ForegroundColor Cyan
    Write-Host "  ./teardown.ps1" -ForegroundColor Gray
    Write-Host ""

    exit 0
}

# FULL TEARDOWN MODE: Delete everything
Write-Host "Resources in '$ResourceGroup':" -ForegroundColor Yellow
az resource list --resource-group $ResourceGroup --output table
Write-Host ""

# Confirm deletion
if (-not $Force) {
    Write-Host "WARNING: This will PERMANENTLY DELETE ALL resources in '$ResourceGroup'" -ForegroundColor Red
    Write-Host "         including the AKS cluster, Key Vault, and all secrets" -ForegroundColor Red
    Write-Host ""
    Write-Host "To only stop the cluster without deleting, use: ./teardown.ps1 -Stop" -ForegroundColor Yellow
    Write-Host ""
    $confirmation = Read-Host "Type 'yes' to confirm PERMANENT deletion"
    if ($confirmation -ne "yes") {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Delete resource group
Write-Host ""
Write-Host "Deleting resource group '$ResourceGroup'..." -ForegroundColor Yellow
Write-Host "  (This may take 5-10 minutes)" -ForegroundColor Gray

az group delete --name $ResourceGroup --yes --no-wait

Write-Host ""
Write-Host "✓ Deletion initiated" -ForegroundColor Green
Write-Host ""
Write-Host "The resource group is being deleted in the background." -ForegroundColor White
Write-Host "You can check the status with:" -ForegroundColor White
Write-Host "  az group show --name $ResourceGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "To monitor deletion progress:" -ForegroundColor White
Write-Host "  az group wait --name $ResourceGroup --deleted" -ForegroundColor Gray
Write-Host ""
