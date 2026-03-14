# Cleanup script for Demo 1: Container Image Scanning with Trivy + Kyverno
# This script reverses all installation steps from the demo

Write-Host "Starting cleanup..." -ForegroundColor Cyan

# Delete Kyverno ClusterPolicy
Write-Host "`nDeleting Kyverno ClusterPolicy..." -ForegroundColor Yellow
kubectl delete -f ./admission-control/ --ignore-not-found=true 2>$null

# Delete demo namespaces and resources
Write-Host "`nDeleting demo namespaces and resources..." -ForegroundColor Yellow
kubectl delete namespace wb-secure --ignore-not-found=true 2>$null
kubectl delete namespace wiredbrain --ignore-not-found=true 2>$null

# Uninstall Kyverno
Write-Host "`nUninstalling Kyverno..." -ForegroundColor Yellow
helm uninstall kyverno --namespace kyverno 2>$null
kubectl delete namespace kyverno --ignore-not-found=true 2>$null

# Uninstall Trivy Operator
Write-Host "`nUninstalling Trivy Operator..." -ForegroundColor Yellow
helm uninstall trivy-operator --namespace trivy-system 2>$null
kubectl delete namespace trivy-system --ignore-not-found=true 2>$null

# Clean up Trivy Operator cluster-scoped resources
Write-Host "Cleaning up Trivy Operator cluster resources..." -ForegroundColor Yellow
kubectl delete clusterroles -l app.kubernetes.io/managed-by=Helm --ignore-not-found=true 2>$null
kubectl delete clusterrolebindings -l app.kubernetes.io/managed-by=Helm --ignore-not-found=true 2>$null
kubectl delete crd vulnerabilityreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd configauditreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd exposedsecretreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd rbacassessmentreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd infraassessmentreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd clustercompliancereports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd clusterconfigauditreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd clusterinfraassessmentreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd clusterrbacassessmentreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd sbomreports.aquasecurity.github.io --ignore-not-found=true 2>$null
kubectl delete crd clustersbomreports.aquasecurity.github.io --ignore-not-found=true 2>$null

# Remove Helm repositories (optional)
Write-Host "`nRemoving Helm repositories..." -ForegroundColor Yellow
helm repo remove kyverno 2>$null
helm repo remove aqua 2>$null

Write-Host "`nCleanup complete!" -ForegroundColor Green
Write-Host "All resources, namespaces, and Helm charts have been removed." -ForegroundColor Green
