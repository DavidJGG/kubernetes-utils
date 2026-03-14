helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo add kyverno https://kyverno.github.io/kyverno/

helm repo update

helm install trivy-operator aqua/trivy-operator `
  --namespace trivy-system --create-namespace `
  --set="trivy.resources.limits.memory=4Gi" `
  --set="configFile.image.platform=linux/arm64" `
   --version 0.31.0 --wait

helm install kyverno kyverno/kyverno `
 --namespace kyverno --create-namespace `
 --version 3.5.2 --wait

kubectl apply -f setup/

kubectl get vulnerabilityreport -w

kubectl scale deploy/products-api-vulnerable --replicas 0