#!/usr/bin/env pwsh

# Azure Kubernetes Security Demo - Setup Script
# Creates AKS cluster with Key Vault integration for CSI Secrets Store Driver
# This script is idempotent - safe to run multiple times

param(
    [string]$ResourceGroup = "psod-k8s-security-rg",
    [string]$Location = "eastus",
    [string]$ClusterName = "psod-aks",
    [string]$KeyVaultName = "psod-kv-m3d2",
    [int]$NodeCount = 2,
    [string]$NodeSize = "Standard_D2s_v3"
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Azure K8s Security Demo - Setup" -ForegroundColor Cyan
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
Write-Host "✓ Subscription: $($account.name)" -ForegroundColor Green
Write-Host ""

# Create Resource Group
Write-Host "Checking resource group '$ResourceGroup'..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "true") {
    Write-Host "✓ Resource group already exists" -ForegroundColor Green
} else {
    Write-Host "Creating resource group..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location --output none
    Write-Host "✓ Resource group created" -ForegroundColor Green
}
Write-Host ""

# Create or check AKS Cluster
Write-Host "Checking AKS cluster '$ClusterName'..." -ForegroundColor Yellow
$aksExists = az aks show --resource-group $ResourceGroup --name $ClusterName 2>$null
if ($aksExists) {
    Write-Host "✓ AKS cluster already exists" -ForegroundColor Green

    # Check if cluster is running
    $aksState = az aks show --resource-group $ResourceGroup --name $ClusterName --query "powerState.code" -o tsv
    if ($aksState -eq "Stopped") {
        Write-Host "Cluster is stopped. Starting cluster..." -ForegroundColor Yellow
        Write-Host "  (This may take 2-3 minutes)" -ForegroundColor Gray
        az aks start --resource-group $ResourceGroup --name $ClusterName
        Write-Host "✓ Cluster started" -ForegroundColor Green
    }
} else {
    Write-Host "Creating AKS cluster..." -ForegroundColor Yellow
    Write-Host "  (This may take 5-10 minutes)" -ForegroundColor Gray
    az aks create `
        --resource-group $ResourceGroup `
        --name $ClusterName `
        --node-count $NodeCount `
        --node-vm-size $NodeSize `
        --enable-managed-identity `
        --enable-addons azure-keyvault-secrets-provider `
        --enable-oidc-issuer `
        --enable-workload-identity `
        --generate-ssh-keys `
        --output none

    Write-Host "✓ AKS cluster created" -ForegroundColor Green
}
Write-Host ""

# Get AKS credentials
Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing
Write-Host "✓ Credentials configured" -ForegroundColor Green
Write-Host ""

# Verify cluster connection
Write-Host "Verifying cluster connection..." -ForegroundColor Yellow
kubectl get nodes
Write-Host ""

# Create or check Key Vault
Write-Host "Checking Key Vault '$KeyVaultName'..." -ForegroundColor Yellow
$kvExists = az keyvault show --name $KeyVaultName --resource-group $ResourceGroup 2>$null
if ($kvExists) {
    Write-Host "✓ Key Vault already exists" -ForegroundColor Green
} else {
    Write-Host "Creating Key Vault..." -ForegroundColor Yellow
    az keyvault create `
        --name $KeyVaultName `
        --resource-group $ResourceGroup `
        --location $Location `
        --enable-rbac-authorization false `
        --output none

    Write-Host "✓ Key Vault created" -ForegroundColor Green
}
Write-Host ""

# Create User Assigned Managed Identity for Workload Identity
Write-Host "Configuring Workload Identity..." -ForegroundColor Yellow
$identityName = "wiredbrain-identity"

$identityExists = az identity show --resource-group $ResourceGroup --name $identityName 2>$null
if ($identityExists) {
    Write-Host "✓ Managed identity already exists" -ForegroundColor Green
    $identity = $identityExists | ConvertFrom-Json
} else {
    Write-Host "Creating managed identity..." -ForegroundColor Yellow
    $identity = az identity create `
        --resource-group $ResourceGroup `
        --name $identityName `
        --location $Location `
        --output json | ConvertFrom-Json
    Write-Host "✓ Managed identity created" -ForegroundColor Green
}

$identityClientId = $identity.clientId
$identityObjectId = $identity.principalId

# Grant Key Vault access to the managed identity
az keyvault set-policy `
    --name $KeyVaultName `
    --object-id $identityObjectId `
    --secret-permissions get list `
    --output none

Write-Host "✓ Key Vault access configured" -ForegroundColor Green

# Get AKS OIDC Issuer URL
$oidcIssuer = az aks show `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --query "oidcIssuerProfile.issuerUrl" `
    --output tsv

# Create federated identity credential
$federatedCredName = "wiredbrain-federated-credential"
$serviceAccountNamespace = "wiredbrain"
$serviceAccountName = "workload-identity-sa"

$fedCredExists = az identity federated-credential show `
    --resource-group $ResourceGroup `
    --identity-name $identityName `
    --name $federatedCredName 2>$null

if ($fedCredExists) {
    Write-Host "Deleting existing federated credential to recreate with correct settings..." -ForegroundColor Yellow
    az identity federated-credential delete `
        --resource-group $ResourceGroup `
        --identity-name $identityName `
        --name $federatedCredName `
        --yes `
        --output none
}

Write-Host "Creating federated identity credential..." -ForegroundColor Yellow
az identity federated-credential create `
    --resource-group $ResourceGroup `
    --identity-name $identityName `
    --name $federatedCredName `
    --issuer $oidcIssuer `
    --subject "system:serviceaccount:${serviceAccountNamespace}:${serviceAccountName}" `
    --audiences "api://AzureADTokenExchange" `
    --output none
Write-Host "✓ Federated credential created" -ForegroundColor Green

Write-Host ""

# Store database secrets in Key Vault (idempotent)
Write-Host "Storing database secrets in Key Vault..." -ForegroundColor Yellow

$dbPassword = "w!r3d"

# Postgres password
$secretExists = az keyvault secret show --vault-name $KeyVaultName --name postgres-password 2>$null
if ($secretExists) {
    Write-Host "✓ postgres-password already exists" -ForegroundColor Green
} else {
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name postgres-password `
        --value $dbPassword `
        --output none
    Write-Host "✓ postgres-password stored" -ForegroundColor Green
}

# Database connection string for Go app
$connectionString = "host=products-db port=5432 user=postgres password=$dbPassword dbname=postgres sslmode=disable"
$secretExists = az keyvault secret show --vault-name $KeyVaultName --name db-connection-string 2>$null
if ($secretExists) {
    Write-Host "✓ db-connection-string already exists" -ForegroundColor Green
} else {
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name db-connection-string `
        --value $connectionString `
        --output none
    Write-Host "✓ db-connection-string stored" -ForegroundColor Green
}

# Spring Boot application.properties
$appProperties = "spring.datasource.password=$dbPassword"
$secretExists = az keyvault secret show --vault-name $KeyVaultName --name application-properties 2>$null
if ($secretExists) {
    Write-Host "✓ application-properties already exists" -ForegroundColor Green
} else {
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name application-properties `
        --value $appProperties `
        --output none
    Write-Host "✓ application-properties stored" -ForegroundColor Green
}

Write-Host ""

# Verify CSI Driver installation
Write-Host "Verifying Secrets Store CSI Driver..." -ForegroundColor Yellow
$csiPods = kubectl get pods -n kube-system -l app=secrets-store-csi-driver --no-headers 2>$null
if ($csiPods) {
    Write-Host "✓ CSI Driver is installed" -ForegroundColor Green
} else {
    Write-Host "⚠ CSI Driver pods not found (may still be starting)" -ForegroundColor Yellow
}
Write-Host ""

# Display configuration summary
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource Group:         $ResourceGroup" -ForegroundColor White
Write-Host "AKS Cluster:            $ClusterName" -ForegroundColor White
Write-Host "Key Vault:              $KeyVaultName" -ForegroundColor White
Write-Host "Location:               $Location" -ForegroundColor White
Write-Host ""
Write-Host "Workload Identity:" -ForegroundColor Cyan
Write-Host "  Client ID:            $identityClientId" -ForegroundColor Gray
Write-Host "  Service Account:      $serviceAccountNamespace/$serviceAccountName" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Follow the README.md to run the demo" -ForegroundColor White
Write-Host "  2. Run './teardown.ps1 -Stop' to pause or './teardown.ps1' to delete all resources" -ForegroundColor White
Write-Host ""
