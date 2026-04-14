# Demo: Configuring Audit Policies and Centralised Log Collection

This demo configures Kubernetes API server audit logging to capture security events and deploys Fluent Bit to aggregate logs. Without explicit audit policies, the red team's attack would have been invisible.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [k3d](https://k3d.io/) - k3s in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager

Run the [setup script](/m1/demo1/setup.ps1):

```powershell
./setup.ps1
```

> Creates a k3d cluster with a minimal "log nothing" audit policy and deploys the WiredBrain app.

## Demo

### Deploy a log reader pod

To read logs from the control plane node, deploy a pod with a host volume mount:

- [log-reader.yaml](/m1/demo1/log-reader.yaml) - Pod specification

<!--HIGHLIGHT>
node-role.kubernetes.io/control-plane: "true"
"sleep", "infinity"
path: /var/log/kubernetes/audit
-->

> The hostPath volume mounts the node's audit log directory into the pod.

```powershell
kubectl apply -f log-reader.yaml

kubectl wait --for=condition=Ready pod/log-reader -n kube-system --timeout=60s
```

### Show the audit logging gap

The cluster has a minimal audit policy that logs nothing. Check for audit logs:

```powershell
kubectl exec -n kube-system log-reader -- ls -la /var/log/kubernetes/audit/

kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/audit.log
```

> The file is empty - the "log nothing" policy means no events are captured. The red team's activity would be invisible.

### Examine the audit policy

Before enabling logging, examine the audit policy that targets security-relevant events:

- [audit-policy.yaml](/m1/demo1/audit-policy.yaml) - Targeted audit policy

<!--HIGHLIGHT>
level: RequestResponse
"clusterrolebindings", "rolebindings", "clusterroles"
level: Metadata
resources: ["secrets"]
resources: ["pods/exec", "pods/attach", "pods/portforward"]
-->

> RBAC changes and pod exec at RequestResponse level (full request/response); secrets at Metadata level (who accessed, not content).

### Enable audit logging

Replace the minimal policy with the security-focused policy and restart the API server:

```powershell
./enable-audit.ps1
```

> This copies the real audit policy into place and sends SIGHUP to k3d to reload. In production, you'd update the API server manifest and restart.

### Verify audit logs are being written

Check audit logs via the log reader pod:

```powershell
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/audit.log

kubectl exec -n kube-system log-reader -- tail -5 /var/log/kubernetes/audit/audit.log | jq -r '[.verb, .objectRef.resource] | @tsv'
```

> Audit logs are now flowing. Every API call matching our policy is captured.

### Deploy Fluent Bit for log aggregation

Examine the Fluent Bit pipeline configuration:

- [fluent-bit-config.yaml](/m1/demo1/fluent-bit-config.yaml) - Pipeline configuration

<!--HIGHLIGHT>
[INPUT]
/var/log/kubernetes/audit/*.log
[OUTPUT]
filtered.log
[FILTER]
Name lua
exclude_system_users
function exclude_system_users
-->

> Fluent Bit tails audit logs, uses a Lua filter to exclude system service account noise, and writes filtered events to a file. In production, add outputs for Elasticsearch, Loki, or cloud logging.

Deploy Fluent Bit from the local chart:

```powershell
helm install fluent-bit ./charts/fluent-bit-0.49.0.tgz `
  -f fluent-bit-config.yaml `
  -f fluent-bit-values.yaml `
  --namespace logging --create-namespace `
  --wait

kubectl get pods -n logging

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=fluent-bit -n logging --timeout=60s

./wait-log.ps1 audit.log
```

> Wait for Fluent Bit to confirm it's tailing the audit log before generating events.

### Simulate the red team attack

Generate the same activity the red team performed:

```powershell
kubectl create clusterrolebinding attacker-admin `
  --clusterrole=cluster-admin `
  --user=attacker@example.com

kubectl get secrets -n wiredbrain

kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /etc/passwd
```

> Privilege escalation, secrets enumeration, and container access - all captured.

### Verify events in Fluent Bit

Fluent Bit writes filtered events to a file on the node. Wait for the filtered log to be created:

```powershell
./wait-log.ps1 filtered.log
```

> The pipeline needs time to tail the audit logs, apply the Lua filter, and write to the output file.

View RBAC changes:

```powershell
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/filtered.log | `
  jq -r 'select(.objectRef.resource == "clusterrolebindings") | [.verb, .objectRef.resource, .objectRef.name, .user.username] | @tsv' | `
  Sort-Object -Unique | `
  ConvertFrom-Csv -Delimiter "`t" -Header VERB,RESOURCE,NAME,USER | `
  Format-Table -AutoSize
```

View secrets access:

```powershell
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/filtered.log | `
  jq -r 'select(.objectRef.resource == "secrets" and .objectRef.namespace == "wiredbrain") | [.verb, .objectRef.resource, .objectRef.namespace, .user.username] | @tsv' | `
  Sort-Object -Unique | `
  ConvertFrom-Csv -Delimiter "`t" -Header VERB,RESOURCE,NAMESPACE,USER | `
  Format-Table -AutoSize
```

View pod exec:

```powershell
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/filtered.log | `
  jq -r 'select(.objectRef.namespace == "wiredbrain" and .objectRef.subresource == "exec") | [.verb, .objectRef.subresource, .objectRef.name, .objectRef.namespace] | @tsv' | `
  Sort-Object -Unique | `
  ConvertFrom-Csv -Delimiter "`t" -Header VERB,SUBRESOURCE,POD,NAMESPACE | `
  Format-Table -AutoSize
```

> Every step of the attack is captured with full context: who, what, when.
