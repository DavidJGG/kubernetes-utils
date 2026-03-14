# Demo: Comprehensive Security Policies with Kyverno

This demo demonstrates how to enforce multiple layers of container security using Kyverno admission control policies.

## Prerequisites

- [Kubernetes](https://kubernetes.io/docs/tasks/tools/) - Docker Desktop or any other Kubernetes cluster
- [Helm](https://helm.sh/docs/intro/install/) - Package manager for Kubernetes
- Trivy-operator and Kyverno deployed (see [setup.ps1](/m2/demo2/setup.ps1))

```
./setup.ps1
```

## Demo

### Deploy comprehensive security policies

Deploy a policy bundle that enforces two security rules and does audit-only on the third:

- [security-policies.yaml](/m2/demo2/admission-control/security-policies.yaml) - Kyverno ClusterPolicy with two enforced rules

<!--HIGHLIGHT>
validationFailureAction: Enforce
- name: restrict-image-registries
- key: "{{ request.object.spec.containers[].image
- "ghcr.io/wiredbrain/*"
- name: require-non-root
- key: "{{ request.object.spec.securityContext.runAsNonRoot
-->

- [vulnerability-report-policy.yaml](/m2/demo2/admission-control/vulnerability-report-policy.yaml) - ClusterPolicy with one audit-only  rule

<!--HIGHLIGHT>
validationFailureAction: Audit
- name: check-vulnerability-reports
urlPath: "/apis/aquasecurity.github.io/v1alpha1/
operator: GreaterThan
-->

1. **Registry restrictions** - only allow images from `ghcr.io/wiredbrain/`
2. **No root containers** - require `runAsNonRoot: true`
3. **No critical CVEs** - audit log for images with known critical vulnerabilities

```powershell
kubectl apply -f ./admission-control/

kubectl get clusterpolicy
```

View the policy details:

```powershell
kubectl get clusterpolicy -o yaml | yq .items[].spec.rules[].validate.message
```

> Shows the rules that will be applied to all workloads

### Test policy 1: Registry restrictions

Try to deploy a Pod using an unauthorized registry:

- [01-wrong-registry.yaml](/m2/demo2/test-deployments/01-wrong-registry.yaml) - uses a public Docker Hub image

<!--HIGHLIGHT>
image: docker.io/nginx:latest
-->

```powershell
kubectl apply -f ./test-deployments/01-wrong-registry.yaml
```

> **Blocked!** Error: "Images must be pulled from the approved registry: ghcr.io/wiredbrain/"

Even if the image is secure, it's blocked because it's not from the approved registry.

### Test policy 2: Running as root

Try to deploy a Pod without the required security context:

- [02-runs-as-root.yaml](/m2/demo2/test-deployments/02-runs-as-root.yaml) - no security context, will run as container image user

<!--HIGHLIGHT>
spec:
containers:
-->

```powershell
kubectl apply -f ./test-deployments/02-runs-as-root.yaml
```

> **Blocked!** Error: "Containers must run as non-root user for security"

This enforces defense in depth - even approved images must use proper security contexts.

### Test policy 3: Critical CVEs

Try to deploy a Pod with an image containing known critical vulnerabilities:

- [03-has-critical-cves.yaml](/m2/demo2/test-deployments/03-has-critical-cves.yaml) - the bad image with critical CVEs

<!--HIGHLIGHT>
runAsNonRoot: true
image: ghcr.io/wiredbrain/products-api-bad:k8s-security-m2
-->

```powershell
kubectl apply -f ./test-deployments/03-has-critical-cves.yaml
```

> **Allowed!** 

The CVE policy enables deployment of vulnerable images, but creates an audit log.

### Deploy fully compliant workload

Now deploy a Pod that satisfies all three security policies:

- [04-compliant.yaml](/m2/demo2/test-deployments/04-compliant.yaml) - Passes all security checks

<!--HIGHLIGHT>
runAsNonRoot: true
image: ghcr.io/wiredbrain/products-api:k8s-security-m2
-->

```powershell
kubectl apply -f ./test-deployments/04-compliant.yaml

kubectl get pods
```

> **Success!** The Pod meets all requirements:
> - ✓ Image from approved registry (`ghcr.io/wiredbrain/`)
> - ✓ Runs as non-root (user 65534)
> - ✓ No critical CVEs

Verify the security configuration:

```powershell
kubectl get pod test-compliant -o jsonpath='{.spec.securityContext}'

kubectl get pod test-compliant -o jsonpath='{.spec.containers[0].image}'
```

> Shows `runAsNonRoot: true`, `runAsUser: 65534`, and the approved image

### View policy reports

Kyverno tracks all policy evaluations:

```powershell
kubectl get policyreport -n default

kubectl describe policyreport -n default | head -50
```

> Shows pass/fail results for each policy rule on each resource
