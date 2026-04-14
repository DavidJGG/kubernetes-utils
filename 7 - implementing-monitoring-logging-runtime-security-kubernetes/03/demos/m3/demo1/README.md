# Demo: Enforcing Pod Security Standards and Namespace Isolation

This demo implements Kubernetes-native admission control using Pod Security Standards (PSA) to block dangerous pod configurations. We'll discover that while PSA handles the obvious threats, it has gaps that require additional tooling.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [k3d](https://k3d.io/) - k3s in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager

Run the [setup script](/m3/demo1/setup.ps1):

```powershell
./setup.ps1
```

> Creates a k3d cluster and deploys the WiredBrain app without PSA enforcement.

## Demo

### Show the unprotected namespace

Without PSA labels, any pod configuration is allowed - including dangerous ones:

```powershell
kubectl get ns wiredbrain --show-labels
```

> No PSA labels - the namespace accepts any pod configuration.

### Deploy dangerous pods (attacker scenario)

Show that privileged containers deploy in an unprotected namespace:

- [pods/privileged-pod.yaml](/m3/demo1/pods/privileged-pod.yaml) - Privileged container

<!--HIGHLIGHT>
privileged: true
-->

```powershell
kubectl apply -f pods/privileged-pod.yaml -n wiredbrain

kubectl get pod attacker-privileged -n wiredbrain

kubectl delete pod attacker-privileged -n wiredbrain --force
```

> Pod runs successfully - full host access, container escape possible.

### Apply Baseline enforcement

Apply PSA labels to enforce the Baseline profile - blocking the most dangerous configurations:

- [namespaces/baseline-namespace.yaml](/m3/demo1/namespaces/baseline-namespace.yaml) - Baseline enforcement

<!--HIGHLIGHT>
pod-security.kubernetes.io/enforce: baseline
pod-security.kubernetes.io/warn: restricted
-->

```powershell
kubectl apply -f namespaces/baseline-namespace.yaml
```

> Baseline blocks dangerous configs; warn on Restricted helps identify further hardening opportunities.

### Test Baseline enforcement

Try the same privileged pod - now blocked:

```powershell
kubectl apply -f pods/privileged-pod.yaml -n wiredbrain
```

> Error: violates PodSecurity "baseline:latest" - privileged containers blocked.

Test hostPath mounts - another common attack vector:

- [pods/hostpath-pod.yaml](/m3/demo1/pods/hostpath-pod.yaml) - HostPath volume

<!--HIGHLIGHT>
hostPath:
-->

```powershell
kubectl apply -f pods/hostpath-pod.yaml -n wiredbrain
```

> Blocked - hostPath gives access to host filesystem.

### Deploy compliant pods

Properly configured pods still deploy successfully:

- [pods/compliant-pod.yaml](/m3/demo1/pods/compliant-pod.yaml) - Secure pod configuration

<!--HIGHLIGHT>
runAsNonRoot: true
allowPrivilegeEscalation: false
-->

```powershell
kubectl apply -f pods/compliant-pod.yaml -n wiredbrain

kubectl get pod compliant-app -n wiredbrain
```

> Compliant pods work - security doesn't break legitimate workloads.

### Upgrade to Restricted enforcement

Change to the Restricted profile - the strictest built-in settings:

- [namespaces/restricted-namespace.yaml](/m3/demo1/namespaces/restricted-namespace.yaml) - Restricted enforcement

<!--HIGHLIGHT>
pod-security.kubernetes.io/enforce: restricted
-->

```powershell
kubectl apply -f namespaces/restricted-namespace.yaml
```

Try deploying a root container:

- [pods/root-pod.yaml](/m3/demo1/pods/root-pod.yaml) - Container running as root

<!--HIGHLIGHT>
runAsUser: 0
-->

```powershell
kubectl apply -f pods/root-pod.yaml -n wiredbrain
```

> Blocked - Restricted requires runAsNonRoot.

### Audit mode for migration

Use audit mode to identify violations without blocking - useful when migrating existing workloads:

- [namespaces/audit-namespace.yaml](/m3/demo1/namespaces/audit-namespace.yaml) - Audit-only mode

<!--HIGHLIGHT>
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
-->

```powershell
kubectl apply -f namespaces/audit-namespace.yaml

kubectl apply -f pods/root-pod.yaml -n audit-test

kubectl get pod attacker-root -n audit-test

kubectl delete ns audit-test --force
```

> Warning shown but pod allowed - violations logged for review before enforcing.

### Red team scenario replay

Show how PSA blocks the red team's attack techniques:

```powershell
kubectl apply -f pods/privileged-pod.yaml -n wiredbrain

kubectl apply -f pods/hostpath-pod.yaml -n wiredbrain
```

> Both attack vectors eliminated at admission - the attacker never gets a foothold.

### Handle vendor exceptions

A vendor backup agent requires root access and a hostPath mount - both blocked by Restricted enforcement:

- [pods/vendor-backup-pod.yaml](/m3/demo1/pods/vendor-backup-pod.yaml) - Vendor backup agent

<!--HIGHLIGHT>
runAsUser: 0
hostPath:
-->

Try deploying it to the restricted namespace:

```powershell
kubectl apply -f pods/vendor-backup-pod.yaml -n wiredbrain
```

> Blocked - the vendor pod violates Restricted policy. But we need this workload to run.

PSA only has three levels: Privileged, Baseline, and Restricted. HostPath is blocked by both Baseline and Restricted, so the vendor namespace needs Privileged enforcement:

- [namespaces/vendor-namespace.yaml](/m3/demo1/namespaces/vendor-namespace.yaml) - Privileged namespace for vendor workloads

<!--HIGHLIGHT>
pod-security.kubernetes.io/enforce: privileged
pod-security.kubernetes.io/warn: baseline
-->

```powershell
kubectl apply -f namespaces/vendor-namespace.yaml

kubectl apply -f pods/vendor-backup-pod.yaml -n vendor-backup

kubectl get pod vendor-backup-agent -n vendor-backup
```

> The vendor pod runs - but the namespace is now Privileged, meaning PSA provides no protection there. We use warn on Baseline to flag other issues, but enforcement is effectively off.

### Verify existing workloads unaffected

Confirm that the WiredBrain app pods continue running:

```powershell
kubectl get pods -n wiredbrain
```

> Existing pods are not evicted - PSA only applies at admission time when pods are created or updated.
