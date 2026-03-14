#!/usr/bin/env pwsh

# Detect current architecture from Docker
Write-Host "Detecting current architecture..." -ForegroundColor Cyan
$dockerInfo = docker info -f json | ConvertFrom-Json
$arch = $dockerInfo.Architecture

# Map architecture to compose file
$composeFile = switch ($arch) {
    "x86_64" { "docker-compose-linux-amd64.yml" }
    "aarch64" { "docker-compose-linux-arm64.yml" }
    "arm64" { "docker-compose-linux-arm64.yml" }
    default { throw "Unsupported architecture: $arch" }
}

Write-Host "Current architecture: $arch -> Using: $composeFile" -ForegroundColor Green

# Build and push images for current platform
Write-Host "`nBuilding and pushing images using $composeFile..." -ForegroundColor Cyan
docker compose -f docker-compose.yml -f $composeFile build --push

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build and push failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild and push completed" -ForegroundColor Green

# Extract images from compose files using yq
Write-Host "`nExtracting image list from compose files..." -ForegroundColor Cyan

# Get base images from main compose file
$baseServices = yq -o json '.services' docker-compose.yml | ConvertFrom-Json

# Get amd64 images
$amd64Services = yq -o json '.services' docker-compose-linux-amd64.yml | ConvertFrom-Json

# Get arm64 images
$arm64Services = yq -o json '.services' docker-compose-linux-arm64.yml | ConvertFrom-Json

# Build image list for manifest creation
$images = @()
$baseServices.PSObject.Properties | ForEach-Object {
    $serviceName = $_.Name
    $manifest = $_.Value.image

    $amd64Image = $amd64Services.$serviceName.image
    $arm64Image = $arm64Services.$serviceName.image

    if ($amd64Image -and $arm64Image) {
        $images += @{
            name = $serviceName
            manifest = $manifest
            amd64 = $amd64Image
            arm64 = $arm64Image
        }
        Write-Host "  Found: $serviceName -> $manifest" -ForegroundColor Gray
    }
}

Write-Host "Found $($images.Count) images to process" -ForegroundColor Green

# Create and push multi-arch manifests
Write-Host "`nCreating and pushing multi-arch manifests..." -ForegroundColor Cyan

foreach ($image in $images) {
    Write-Host "`nProcessing $($image.name)..." -ForegroundColor Yellow

    # Remove existing manifest if it exists
    docker manifest rm $image.manifest 2>$null

    # Create manifest
    Write-Host "  Creating manifest: $($image.manifest)" -ForegroundColor Gray
    docker manifest create $image.manifest `
        $image.amd64 `
        $image.arm64

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Failed to create manifest for $($image.name)" -ForegroundColor Red
        continue
    }

    # Annotate arm64 image
    docker manifest annotate $image.manifest $image.arm64 --arch arm64

    # Annotate amd64 image
    docker manifest annotate $image.manifest $image.amd64 --arch amd64

    # Push manifest
    Write-Host "  Pushing manifest: $($image.manifest)" -ForegroundColor Gray
    docker manifest push $image.manifest

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Successfully pushed manifest for $($image.name)" -ForegroundColor Green
    } else {
        Write-Host "  Failed to push manifest for $($image.name)" -ForegroundColor Red
    }
}

Write-Host "`nBuild process completed!" -ForegroundColor Green
Write-Host "Architecture built: $arch" -ForegroundColor Cyan
Write-Host "Multi-arch manifests created and pushed" -ForegroundColor Cyan
