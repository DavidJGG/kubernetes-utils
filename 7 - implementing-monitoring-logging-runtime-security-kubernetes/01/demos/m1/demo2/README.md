# Demo: Building Security Alerting Rules with Prometheus

This demo extends the audit logging from Demo 1 by turning logs into metrics and creating alerting rules that detect attack patterns. Centralised logs are valuable, but automated detection catches attacks in minutes rather than days.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [k3d](https://k3d.io/) - k3s in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager

Run the [setup script](/m1/demo2/setup.ps1):

```powershell
./setup.ps1
```

> Creates a k3d cluster with audit logging and deploys the WiredBrain app.

## Demo

### Configure Fluent Bit to expose metrics

Fluent Bit parses audit logs and exposes them as Prometheus metrics:

- [fluent-bit-config.yaml](/m1/demo2/fluent-bit-config.yaml) - Pipeline configuration

<!--HIGHLIGHT>
log_to_metrics
counter
kubernetes_audit_event_count
verb
resource
prometheus_exporter
-->

> The log_to_metrics filter creates counters from audit events. The prometheus_exporter exposes them on port 2021.

- [fluent-bit-lua.yaml](/m1/demo2/fluent-bit-lua.yaml) - Lua script for label extraction

<!--HIGHLIGHT>
new_record["verb"]
new_record["resource"]
new_record["subresource"]
new_record["user"]
-->

> The Lua filter extracts verb, resource, and subresource from nested audit event JSON into flat labels.

### Deploy Fluent Bit

```powershell
helm upgrade --install fluent-bit ./charts/fluent-bit-0.49.0.tgz `
    -f fluent-bit-values.yaml `
    -f fluent-bit-config.yaml `
    -f fluent-bit-lua.yaml `
    --namespace logging --create-namespace `
    --wait

kubectl get pods -n logging
```

> Fluent Bit runs as a DaemonSet on control plane nodes where audit logs are written.

### Configure Prometheus to scrape Fluent Bit

- [prometheus-scrape.yaml](/m1/demo2/prometheus-scrape.yaml) - Scrape configuration

<!--HIGHLIGHT>
job_name: fluent-bit
kubernetes_sd_configs:
regex: fluent-bit
-->

> Prometheus discovers Fluent Bit pods via Kubernetes service discovery and scrapes metrics from port 2021.

### Examine the Prometheus alerting rules

- [prometheus-alerts.yaml](/m1/demo2/prometheus-alerts.yaml) - Security alerting rules

<!--HIGHLIGHT>
alert: ClusterAdminBindingCreated
increase(kubernetes_audit_event_count
{verb="create",resource="clusterrolebindings"}[5m]) > 0
alert: BulkSecretsAccess
{verb="list",resource="secrets"}[5m]) > 3
alert: PodExecDetected
{verb="get",resource="pods",subresource="exec"}[5m]) > 0
-->

> Three rules matching the red team's attack pattern: privilege escalation, secrets enumeration, container access.

### Deploy Prometheus

```powershell
helm upgrade --install prometheus ./charts/prometheus-27.0.0.tgz `
    -f prometheus-values.yaml `
    -f prometheus-scrape.yaml `
    -f prometheus-alerts.yaml `
    --namespace monitoring --create-namespace `
    --wait

kubectl get pods -n monitoring
```

> Prometheus scrapes Fluent Bit metrics and evaluates alerting rules.

### Access the Prometheus UI

The Prometheus UI provides improved navigation and alert visualization:

- [open `kubernetes_audit_event_count` metric](http://localhost:9090/query?g0.expr=kubernetes_audit_event_count&g0.show_tree=0&g0.tab=table&g0.range_input=1h&g0.res_type=auto&g0.res_density=medium&g0.display_mode=lines&g0.show_exemplars=0)
- [navigate to **Alerts** to see the configured rules](http://localhost:9090/alerts)

> There is an alert for each attach type; all currently inactive

### Simulate the red team attack

Generate the attack sequence to trigger alerts:

```powershell
kubectl create clusterrolebinding attacker-admin `
  --clusterrole=cluster-admin `
  --user=attacker@example.com

kubectl get secrets -A

kubectl get secrets -n wiredbrain
kubectl get secrets -n kube-system
kubectl get secrets -n default

kubectl exec -n wiredbrain deploy/wiredbrain-web -- whoami
```

> Privilege escalation, bulk secrets enumeration, and container exec - all should trigger alerts.

### Watch alerts fire

Check Prometheus for firing alerts:

```powershell
./wait-alerts.ps1

curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state}'
```

> Alerts fire within seconds of the attack. The security team would be notified immediately.

### Query attack details in Prometheus

Get details on the privilege escalation - RBAC creation:

```promql
kubernetes_audit_event_count{verb="create",resource="clusterrolebindings"}
```

- [count of ClusterRoleBinding creation](http://localhost:9090/query?g0.expr=kubernetes_audit_event_count%7Bverb%3D%22create%22%2Cresource%3D%22clusterrolebindings%22%7D&g0.show_tree=0&g0.tab=table&g0.range_input=1h&g0.res_type=auto&g0.res_density=medium&g0.display_mode=lines&g0.show_exemplars=0)

Secrets access:

```promql
rate(kubernetes_audit_event_count{verb="list",resource="secrets"}[5m])
```

- [rate of Secret list commands](http://localhost:9090/query?g0.expr=rate%28kubernetes_audit_event_count%7Bverb%3D%22list%22%2Cresource%3D%22secrets%22%7D%5B5m%5D%29&g0.show_tree=0&g0.tab=table&g0.range_input=1h&g0.res_type=auto&g0.res_density=medium&g0.display_mode=lines&g0.show_exemplars=0)

> PromQL enables flexible querying for investigation and tuning alert thresholds.
