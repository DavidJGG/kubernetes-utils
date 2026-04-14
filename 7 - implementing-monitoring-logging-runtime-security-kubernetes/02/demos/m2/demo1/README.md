# Demo: Deploying Falco and Detecting Container Threats

This demo deploys Falco with the eBPF driver to detect runtime threats inside containers. While audit logging captures API activity, Falco monitors system calls at the kernel level - detecting attacks that happen entirely within container boundaries.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [k3d](https://k3d.io/) - k3s in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager

Run the [setup script](/m2/demo1/setup.ps1):

```powershell
./setup.ps1
```

> Creates a k3d cluster with WiredBrain app, and Fluent Bit for log collection and Elasticsearch for storage.

## Demo

### The runtime visibility gap

Audit logs capture API activity but not what happens inside containers:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- whoami
```

> This exec will appear in audit logs, but any commands run inside the container are invisible to the API server.

### Examine Falco configuration

Falco uses eBPF to attach probes to the kernel, intercepting system calls made by all processes. This gives visibility into file access, process execution, and network connections - even inside containers where the Kubernetes API has no visibility.

- [falco-values.yaml](/m2/demo1/falco-values.yaml) - Helm configuration

<!--HIGHLIGHT>
modern_ebpf
json_output: true
kubernetes:
falco-rules:3
-->

> Modern eBPF driver requires no kernel headers and works with all recent Linux versions.

### Deploy Falco

Deploy Falco from the local chart:

```powershell
helm install falco ./charts/falco-7.2.0.tgz `
  -f falco-values.yaml `
  --namespace falco --create-namespace `
  --wait --timeout 5m

kubectl get pods -n falco
```

> Falco runs as a privileged DaemonSet to attach eBPF probes to the kernel on each node.

Wait for Falco to fully initialize before triggering test events:

```powershell
./wait-falco.ps1
```

> Falco needs time to attach BPF probes and start capturing syscalls. This script triggers a test event and waits for it to filter from Falco, through FluentBit to Elasticsearch.

### Explore the default ruleset

Falco ships with rules detecting common attack patterns. Key default rules include:

- Read sensitive file untrusted (e.g. /etc/shadow)
- Contact K8S API Server From Container (connection to API server)
- Search Private Keys or Passwords (find/grep for credentials)
- Clear Log Activities (truncating /var/log files)

View the "Read sensitive file untrusted" rule definition:

```powershell
kubectl exec -n falco daemonset/falco -c falco -- `
  cat /etc/falco/falco_rules.yaml | `
  Select-String -Pattern "^- rule: Read sensitive file untrusted" -Context 0,20
```

> The rule triggers on `open_read` of `sensitive_files` (/etc/shadow, /etc/sudoers, etc.) by untrusted processes. Exceptions whitelist system binaries like package managers.

### Trigger sensitive file access

Read the shadow file - this contains password hashes that attackers exfiltrate for offline cracking:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /etc/shadow
```

Wait for the alert to be indexed, then view it in Elasticsearch:

```powershell
./wait-alert.ps1 "sensitive"

curl "http://localhost:9200/falco-alerts/_search?q=rule.keyword:*sensitive*+AND+output_fields.k8smeta.ns.name:wiredbrain&pretty"
```

> Alert includes: rule name, process details, container ID, file accessed - everything needed for investigation.

### Trigger K8s API access from container

Attackers who compromise a container often attempt to access the Kubernetes API using the mounted service account token. Make an API call from inside the container:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- `
  sh -c 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); wget -qO- --header "Authorization: Bearer $TOKEN" --no-check-certificate https://kubernetes.default.svc/api/v1/namespaces'
```

> The 403 Forbidden response is expected - the service account lacks permissions. But Falco still detects the connection attempt.

Wait for the alert to be indexed, then view it:

```powershell
./wait-alert.ps1 "K8S API"

curl "http://localhost:9200/falco-alerts/_search?q=rule.keyword:*K8S*API*+AND+output_fields.k8smeta.ns.name:wiredbrain&pretty"
```

> Falco detects the network connection to the API server - a key indicator of container compromise.

### Trigger credential search

Attackers often search for SSH keys or credentials after gaining container access:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- find / -name "id_rsa" 2>$null

kubectl exec -n wiredbrain deploy/wiredbrain-web -- grep -r "BEGIN RSA PRIVATE KEY" /etc 2>$null
```

> This simulates an attacker hunting for private keys to pivot to other systems.

Wait for the alert to be indexed, then view it:

```powershell
./wait-alert.ps1 "Private Keys"

curl "http://localhost:9200/falco-alerts/_search?q=rule.keyword:*Private*Keys*+AND+output_fields.k8smeta.ns.name:wiredbrain&pretty"
```

> Falco detects common credential hunting patterns - find/grep for key files or password strings.

### Query alerts in Elasticsearch

Falco alerts are collected by Fluent Bit and stored in Elasticsearch. Query alerts directly via the exposed API:

```powershell
curl http://localhost:9200/falco-alerts/_search?pretty
```

Search for specific rule alerts:

```powershell
curl "http://localhost:9200/falco-alerts/_search?q=rule.keyword:*sensitive*+AND+output_fields.k8smeta.ns.name:wiredbrain&pretty"
```

> Elasticsearch provides flexible querying and can be integrated with Kibana for visualization and rich querying.
