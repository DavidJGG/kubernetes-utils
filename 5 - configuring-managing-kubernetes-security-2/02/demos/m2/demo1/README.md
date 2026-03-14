# Demo: Container Image Scanning with Trivy + Kyverno

This demo demonstrates how to block container images with critical vulnerabilities using Trivy Operator scan results and Kyverno admission control.

## Prerequisites

- [Kubernetes](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) - Package manager for Kubernetes

## Demo

### Install Trivy Operator

Install Trivy Operator to scan container images and generate VulnerabilityReports:

```powershell
helm repo add aqua https://aquasecurity.github.io/helm-charts/

helm repo update
```

```powershell
helm install trivy-operator aqua/trivy-operator `
  --namespace trivy-system --create-namespace `
  --set="trivy.resources.limits.memory=4Gi" `
  --set="configFile.image.platform=linux/arm64" `
   --version 0.31.0 --wait
```

### Verify Trivy installation

Operator runs in the `trivy-system` namespace, monitoring for new resources:

```powershell
kubectl get pods -n trivy-system

kubectl get crd 
```

> Trivy Operator automatically scans all workload images and creates VulnerabilityReport custom resources with CVE details

### Deploy vulnerable application

Deploy the namespace and vulnerable application to see Trivy Operator in action:

- [vulnerable-app.yaml](/m2/demo1/initial-scan/vulnerable-app.yaml) - vulnerable app deployment

<!--HIGHLIGHT>
image: sixeyed/wiredbrain-products-api-bad:k8s-security-m2 
-->

```powershell
kubectl apply -f ./initial-scan/

kubectl get pods -n wiredbrain
```

Wait for Trivy Operator to create the VulnerabilityReport (this takes a few minutes):

```powershell
kubectl get vulnerabilityreport -n wiredbrain -w
```
<!--EXPECT-WATCH: replicaset-products-api-vulnerable-->

### Check the Trivy report

The report details all the CVEs and produces a summary:

```powershell
kubectl describe vulnerabilityreport -n wiredbrain 

kubectl get vulnerabilityreport -n wiredbrain -o yaml | yq .items[0].report.summary
```

> Shows `criticalCount: 4` from the Trivy scan - the image has CRITICAL CVEs

The deployment is allowed because there's no policy blocking it yet. Trivy Operator scans the image AFTER it's deployed.

Scale down the vulnerable deployment:

```powershell
kubectl scale -n wiredbrain deploy/products-api-vulnerable --replicas 0
```

> Deleting the Pod also deletes the VulnerabilityReport; scaling to zero retains it

### Install Kyverno

Add the Kyverno Helm repository and install Kyverno:

```powershell
helm repo add kyverno https://kyverno.github.io/kyverno/

helm repo update
```

```powershell
helm install kyverno kyverno/kyverno `
 --namespace kyverno --create-namespace `
 --version 3.5.2 --wait
```

### Verify Kyverno installation

Admission controllers run in the `kyverno` namespace, with additional CRDs:

Verify the installation:

```powershell
kubectl get pods -n kyverno

kubectl get crd -l app.kubernetes.io/instance=kyverno
```

> Kyverno is a policy engine designed for Kubernetes that validates and mutates resources via admission webhooks

### Deploy CVE blocking policy

Deploy a Kyverno policy that queries Trivy VulnerabilityReports and blocks images with critical CVEs:

- [block-critical-cves.yaml](/m2/demo1/admission-control/block-critical-cves.yaml) - Kyverno ClusterPolicy that queries VulnerabilityReports

<!--HIGHLIGHT>
kind: ClusterPolicy
- Deployment
- key: "{{ request.operation || 'CREATE' }}"
apiCall:
operator: GreaterThan
-->

```powershell
kubectl apply -f ./admission-control/

kubectl get clusterpolicy
```

> The policy uses `context` and `apiCall` to query VulnerabilityReports and blocks deployment based on actual scan results

### Test blocking with vulnerable image

Try to deploy the vulnerable app again - this time the policy will block it:

```powershell
kubectl apply -f ./initial-scan/

kubectl get pods -n wiredbrain
```

> **Blocked!** Error: "Image contains 4 CRITICAL severity CVEs and is blocked by security policy"

The admission webhook queries the existing VulnerabilityReport and prevents the vulnerable pods from running.

### Deploy secure image

Now deploy the same app with a patched image that has no critical CVEs:

- [secure-app.yaml](/m2/demo1/update-1/secure-app.yaml) - uses patched image with no critical CVEs, in a new namespace

<!--HIGHLIGHT>
namespace: wb-secure
image: sixeyed/wiredbrain-products-api:k8s-security-m2
-->

```powershell
kubectl apply -f ./update-1/

kubectl get pods -n wb-secure
```

> **Deployment succeeds!** The image passes the CVE policy check (first deployment is always allowed)

Wait for Trivy Operator to scan the secure image:

```powershell
kubectl get vulnerabilityreports -n wb-secure -w
```
<!--EXPECT-WATCH: sixeyed/wiredbrain-products-api-->

Check the summary:

```powershell
kubectl get vulnerabilityreport -n wb-secure -o yaml | yq .items[0].report.summary
```

> No critical CVEs. Scaling up will allow more Pods.
