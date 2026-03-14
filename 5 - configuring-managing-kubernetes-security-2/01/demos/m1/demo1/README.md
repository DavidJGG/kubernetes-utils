# Demo: Kubernetes RBAC with Service Accounts

This demo demonstrates the security risks of excessive permissions and how to properly implement role-based access control.

## Pre-reqs

- [Kubernetes](https://kubernetes.io/docs/tasks/tools/) - Docker Desktop or any other Kubernetes cluster

Create initial state in the cluster:

```
kubectl apply -f setup/
```

## Demo

### Explore the cluster

Let's explore what's already in the cluster:

```
kubectl get namespaces

kubectl get pods -n default

kubectl get serviceaccounts -n default
```

Shows we have:

- just the usual namespaces
- two debugging Pods in the default namespace (busybox containers)
- the default ServiceAccount

### Deploy kube-explorer

Deploy the kube-explorer application to browse Kubernetes resources:

- [deployment.yaml](/m1/demo1/kube-explorer/deployment.yaml) - simple Deployment spec
- [service.yaml](/m1/demo1/kube-explorer/service.yaml) - exposes the app via LoadBalancer on port 8019

```
kubectl apply -f ./kube-explorer/

kubectl get pod -l app=kube-explorer -o jsonpath='{.items[0].spec.serviceAccountName}'
```

- the Pod is using the default ServiceAccount
- every namespace has a default SA

> Browse to the app at http://localhost:8019

The app shows Pods in the default namespace - you can view and delete the debug Pods.

> This seems fine - the team intended for the app to manage Pods in the default namespace

### Unintended access to kube-system

Now try browsing to the kube-system namespace:

> http://localhost:8019/?ns=kube-system

- the app can view Pods in the kube-system namespace
- and delete them
- it has inherited the permissions of the default SA

Find what permissions the default ServiceAccount has:

```
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.subjects[]? | select(.name == \"default\")) | {name: .metadata.name, role: .roleRef.name}' | ConvertFrom-Json | Format-Table
```

> The default ServiceAccount has cluster-admin - complete control over the entire cluster

### Fix the problem with RBAC

Let's fix this by deploying a proper configuration with a dedicated ServiceAccount and restrictive permissions:

- [rbac.yaml](/m1/demo1/update-1/rbac.yaml) - creates a least-privilege Role, custom Service Account and a RoleBinding to link them 

- [deployment.yaml](/m1/demo1/update-1/deployment.yaml) - updates the Deployment to use the new ServiceAccount

```
kubectl apply -f ./update-1/

kubectl get pod -l app=kube-explorer -o jsonpath='{.items[0].spec.serviceAccountName}'

kubectl get rolebindings -A -o json | jq -r '[.items[] | select(.subjects[].name == \"kube-explorer\") | {namespace: .metadata.namespace, name: .metadata.name, role: .roleRef.name}]' | ConvertFrom-Json | Format-Table
```

Now: 

- the app is using a dedicated ServiceAccount
- the ServiceAccount has a specific role binding
- the Role has just the permissions the app needs

### Test the restricted permissions

> Browse to http://localhost:8019

The app still shows Pods in the default namespace. You can view and delete Pods here.

> Browse to ServiceAccounts - 403 error (no permission)

Now try browsing to kube-system:

> http://localhost:8019/?ns=kube-system - **403 Forbidden!**

The app is now properly restricted and cannot access kube-system at all.

Verify the limited permissions:

```
kubectl auth can-i get pods --namespace default --as system:serviceaccount:default:kube-explorer

kubectl auth can-i delete pods --namespace default --as system:serviceaccount:default:kube-explorer

kubectl auth can-i get pods --namespace kube-system --as system:serviceaccount:default:kube-explorer
```

> Can get/delete pods in default, but cannot access kube-system

### Add permissions for kube-system (read-only)

The team now has a new requirement - they want to view (but not delete) Pods in kube-system for monitoring:

- [rbac.yaml](/m1/demo1/update-2/rbac.yaml) - creates a Role and RoleBinding for the `kube-system` namespace, allowing get and list operations

```
kubectl apply -f ./update-2/

kubectl get rolebindings -A -o json | jq -r '[.items[] | select(.subjects[].name == \"kube-explorer\") | {namespace: .metadata.namespace, name: .metadata.name, role: .roleRef.name}]' | ConvertFrom-Json | Format-Table
```

> Now there are two Roles and RoleBindings - one for `default` (read/write), one for `kube-system` (read-only)

### Test the additive permissions

The app now displays Pods in the kube-system namespace:


> http://localhost:8019/?ns=kube-system

- permissions evaluated on demand
- no need to restart the app
- can now view but not delete Pods

### Authentication for Service Accounts

Tokens are created for the ServiceAccount and loaded into the Pod:

```
kubectl exec deploy/kube-explorer -- ls -l /var/run/secrets/kubernetes.io/serviceaccount

kubectl exec deploy/kube-explorer -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

> This is a JSON Web Token. Paste it into https://jwt.io to decode it
