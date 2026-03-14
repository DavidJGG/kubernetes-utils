# Demo: Implementing Network Policies

This demo demonstrates building defense-in-depth network segmentation for the Wired Brain Coffee application using Kubernetes Network Policies.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [k3d](https://k3d.io/) - `brew install k3d` (macOS) or `choco install k3d` (Windows)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

> This demo uses k3d to run Kubernetes in Docker. We need a cluster with NetworkPolicy support.

## Demo

### Deploy the application without network policies

Deploy the Wired Brain Coffee application with unrestricted pod-to-pod communication:

- [app.yaml](/m3/demo1/initial-deploy/app.yaml) - complete application; Deployments for (database, products-api, stock-api, and web frontend

<!--HIGHLIGHT>
name: wiredbrain-database
name: wiredbrain-products-api
name: wiredbrain-stock-api
name: wiredbrain-web
-->

```powershell
kubectl apply -f ./initial-deploy/

kubectl get pods -n wiredbrain
```

> All pods can communicate with each other without restrictions - any pod can reach the database.

### Test unrestricted access

Verify that the web app can access the database directly (bypassing the APIs):

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- nc -zv products-db 5432
```

> The web frontend can reach the database directly - a nice attack vector if the site got hacked.

### Apply default-deny network policies

Create a zero-trust baseline by denying all ingress and egress traffic:

- [default-deny.yaml](/m3/demo1/default-deny/default-deny.yaml) - denies all ingress and egress

<!--HIGHLIGHT>
podSelector: {}
- Egress
-->

```powershell
kubectl apply -f ./default-deny/

kubectl describe networkpolicy -n wiredbrain
```

> Default-deny policies apply to all pods in the namespace via empty `podSelector: {}`

### Test that all traffic is blocked

Try to access services:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- nc -zv products-db 5432

kubectl exec -n wiredbrain deploy/wiredbrain-web -- wget -qO- --timeout=2 products-api
```

> **Blocked!** All traffic is denied. Even DNS resolution fails because egress is blocked.

### Allow DNS traffic

Restore DNS functionality by allowing egress to kube-dns:

- [allow-dns.yaml](/m3/demo1/allow-policies/allow-dns.yaml) - allows DNS queries to [kube-system](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#networkpolicy-v1-networking-k8s-io)

<!--HIGHLIGHT>
podSelector: {}
egress:
kubernetes.io/metadata.name: kube-system
port: 53
-->

```powershell
kubectl apply -f ./allow-policies/allow-dns.yaml

kubectl exec -n wiredbrain deploy/wiredbrain-web -- wget -qO- --timeout=2 products-api
```

> DNS lookups are allowed, but the traffic is still blocked.

### Allow traffic between application tiers

Apply network policies to enable proper three-tier communication (web -> APIs -> database):

- [allow-api-to-db.yaml](/m3/demo1/allow-policies/app/allow-api-to-db.yaml) - allows database ingress from API pods

<!--HIGHLIGHT>
component: database
ingress:
component: products-api
-->

- [allow-api-egress.yaml](/m3/demo1/allow-policies/app/allow-api-egress.yaml) - allows API egress to database

<!--HIGHLIGHT>
component: products-api
egress:
component: database
-->

- `allow-web-to-api.yaml` - allows API ingress from web pods
- `allow-web-egress.yaml` - allows web egress to APIs

```powershell
kubectl apply -f ./allow-policies/app/
```

### Test the complete traffic flow

Web to database is still blocked, but web can reach APIs - which can reach the database:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- nc -zv products-db 5432

kubectl exec -n wiredbrain deploy/wiredbrain-web -- wget -qO- --timeout=2 products-api/products
```

And the default deny-all egress rule restricts external access:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-web -- wget -qO- --timeout=2 blog.sixeyed.com
```

> **Blocked!** No potential for exfiltration or downloading malicious tools
