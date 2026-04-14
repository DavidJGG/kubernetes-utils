# Demo: Enforcing Security Profiles with Kyverno

This demo uses Kyverno to enforce seccomp profiles on containers - extending the protection from Pod Security Standards with validation and mutation policies. PSA can only reject non-compliant pods; Kyverno can fix them automatically.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [k3d](https://k3d.io/) - k3s in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager

Run the [setup script](/m3/demo2/setup.ps1):

```powershell
./setup.ps1
```

> Creates a k3d cluster with the WiredBrain app.

## Demo

### Recap the gap from demo 1

In demo 1 we applied PSA Restricted to block dangerous pod configurations - privileged containers, hostPath mounts. But PSA only validates at admission; it can't fix non-compliant pods.

The WiredBrain pods are running without seccomp profiles.

```powershell
kubectl get pods -n wiredbrain `
  -o custom-columns="NAME:.metadata.name,SECCOMP:.spec.containers[0].securityContext.seccompProfile.type"
```

> All `<none>` - no seccomp profiles. If PSA Restricted was enforced here, these pods couldn't restart.

### Deploy Kyverno

Kyverno is an admission controller - it intercepts API requests to validate and mutate resources before they're created. 

- [kyverno-values.yaml](/m3/demo2/kyverno-values.yaml) - Helm values

<!--HIGHLIGHT>
admissionController
-->

> Four controllers: admission (validates/mutates at request time), background (evaluates existing resources), cleanup (expired resources), and reports (policy compliance).

```powershell
helm install kyverno ./charts/kyverno-3.6.2.tgz `
  -f kyverno-values.yaml `
  --namespace kyverno --create-namespace `
  --wait --timeout 5m

kubectl get pods -n kyverno
```

> All four controllers running.

### Validate seccomp profiles

A ClusterPolicy that requires every container to have a seccomp profile.

- [policies/require-seccomp.yaml](/m3/demo2/policies/require-seccomp.yaml) - Require seccomp

<!--HIGHLIGHT>
ClusterPolicy
validate
seccompProfile
RuntimeDefault | Localhost
-->

> Pattern syntax checks that `seccompProfile.type` is set to an approved value.

```powershell
kubectl apply -f policies/require-seccomp.yaml

kubectl get clusterpolicy require-seccomp-profile
```

### Test validation

Deploy a pod without a seccomp profile.

- [pods/no-seccomp.yaml](/m3/demo2/pods/no-seccomp.yaml) - No seccomp profile

<!--HIGHLIGHT>
containers
-->

```powershell
kubectl apply -f pods/no-seccomp.yaml
```

> Rejected - Kyverno blocks the pod with a clear message identifying the missing seccomp profile.

### Mutate to inject seccomp default

Instead of rejecting, Kyverno can mutate pods to inject a default seccomp profile - security by default.

- [policies/mutate-seccomp.yaml](/m3/demo2/policies/mutate-seccomp.yaml) - Inject seccomp

<!--HIGHLIGHT>
ClusterPolicy
mutate
containers
+(seccompProfile)
-->

> The `+()` prefix means "add if not present" - pods that already set a profile are left unchanged.

```powershell
kubectl apply -f policies/mutate-seccomp.yaml
```

### Test mutation

Deploy the same pod - mutation runs before validation, so Kyverno adds the seccomp profile and validation passes.

```powershell
kubectl apply -f pods/no-seccomp.yaml

kubectl get pod test-no-seccomp -n wiredbrain
```

> Pod admitted - Kyverno mutated it to add the RuntimeDefault seccomp profile.

### Verify seccomp is active

Check the pod spec to confirm the profile was injected.

```powershell
kubectl get pod test-no-seccomp -n wiredbrain `
  -o custom-columns="NAME:.metadata.name,SECCOMP:.spec.containers[0].securityContext.seccompProfile.type"
```

> `RuntimeDefault` - injected by Kyverno before the pod was admitted.

Verify the seccomp filter is active at runtime.

```powershell
kubectl exec test-no-seccomp -n wiredbrain -- grep Seccomp /proc/1/status
```

> `Seccomp: 2` - mode 2 means the seccomp filter is active, blocking dangerous syscalls.

### Seccomp blocking suspicious behaviour

Prove the filter does more than report a status - it actively blocks syscalls used in container escapes.

Try to create a new user namespace with `unshare` - a common container breakout technique.

```powershell
kubectl exec test-no-seccomp -n wiredbrain -- unshare -r whoami
```

> `Operation not permitted` - the `unshare` syscall is blocked. Attackers use namespace manipulation to escalate privileges and escape containers; seccomp stops that at the kernel level.

### Seccomp allows normal behaviour

Normal application behaviour is unaffected.

```powershell
kubectl exec test-no-seccomp -n wiredbrain -- whoami

kubectl exec test-no-seccomp -n wiredbrain -- ls /
```

> Standard syscalls work fine - seccomp only blocks the dangerous ones. RuntimeDefault is designed to let normal workloads run without modification.

### Check Existing Pods for seccomp

The WiredBrain pods were deployed before the Kyverno policy - are they protected?

```powershell
kubectl exec deploy/wiredbrain-web -n wiredbrain -- grep Seccomp /proc/1/status
```

> `Seccomp: 0` - mode 0 means unconfined. All syscalls are allowed, including the dangerous ones that seccomp is designed to block. These pods predate the mutation policy.

### Restart the Wiredbrain Pods

Restart the deployment so new pods are admitted through Kyverno.

```powershell
kubectl rollout restart deployment/wiredbrain-web -n wiredbrain

kubectl rollout status deployment/wiredbrain-web -n wiredbrain
```

Check the new pod.

```powershell
kubectl exec deploy/wiredbrain-web -n wiredbrain -- grep Seccomp /proc/1/status
```

> `Seccomp: 2` - the pod was recreated, and the new pod mutated at admission.

