# Demo: MFA and RBAC for End-User Access

Securing human access to AKS clusters with Azure AD authentication, multi-factor authentication, and role-based permissions.

## Prerequisites

Resources already created in Azure:

- Resource Group
- AKS Cluster (default authentication)
- Entra ID (Azure AD) group for permissions
- Entra ID account with minimal permissions

Run the [setup script](/m1/demo2/setup.ps1):

```powershell
./setup.ps1
```

## Demo

### Connect to Cluster and Verify Access

Get cluster credentials and connect:

```pwsh
az aks get-credentials --resource-group rg-k8s-security-m1 --name aks-k8s-security-m1 --overwrite-existing

kubectl get nodes
```

> Kubernetes API access is working

Print the kubeconfig to show the authentication method:

```pwsh
kubectl config view --minify
```

> The `user` section uses a token and certificate - no Azure AD integration yet.

### Enable Azure AD Integration

Get the ID of the Entra ID group to be cluster admins:

```pwsh
az ad group list -o table

$adminGroupId = az ad group show --group "cluster-admins" --query id -o tsv
```

Now enable Azure AD integration and block local accounts:

```pwsh
az aks update `
    --resource-group rg-k8s-security-m1 `
    --name aks-k8s-security-m1 `
    --enable-aad `
    --aad-admin-group-object-ids $adminGroupId `
    --disable-local-accounts
```

> Updating the cluster takes a few minutes. Browse to the AKS cluster in the [Azure Portal](https://portal.azure.com) to confirm the security configuration changes

### Set Up Authentication with Azure

Get cluster credentials and list nodes again:

```pwsh
az aks get-credentials --resource-group rg-k8s-security-m1 --name aks-k8s-security-m1 --overwrite-existing

kubectl get nodes
```

> Login fails. The output tells you to install [kubelogin](https://github.com/Azure/kubelogin)

Download and install kubelogin:

```pwsh
curl -sSL -o kubelogin.zip https://github.com/Azure/kubelogin/releases/download/v0.2.12/kubelogin-darwin-arm64.zip

sudo unzip -j kubelogin.zip -d /usr/local/bin

chmod +x /usr/local/bin/kubelogin
```

Check kubeconfig now:

```pwsh
kubectl config view --minify
```

> Now there is an `exec` command in the user section. This is how kubectl integrates with external authentication tools.

### Cluster Admin with MFA

Now try to access the cluster again:

```pwsh
kubectl get nodes
```

> Prints a device code and link for browser authentication. The subscription is configured for MFA.

Check your permissions:

```pwsh
kubectl auth can-i get pods --all-namespaces

kubectl auth can-i create clusterroles

kubectl auth can-i --list
```

> Full cluster access.

### Least-Privilege User (still MFA)

Create least-privilege RBAC inside the cluster:

- [least-privilege.yaml](/m1/demo2/rbac/least-privilege.yaml) - gives view-only access to a named Entra ID user

```
kubectl apply -f rbac/least-privilege.yaml

az account clear
```

> Demonstrate user switch by signing out from the [Azure Portal](https://portal.azure.com/#home)

```
az aks get-credentials --resource-group rg-k8s-security-m1 --name aks-k8s-security-m1 --file least-privilege.kubeconfig
```

> MFA sign-in with least-privilege user

```
kubectl --kubeconfig least-privilege.kubeconfig get nodes
```

> Access to Nodes is blocked

Only has access to read Pods in the default namespace:

```
kubectl --kubeconfig least-privilege.kubeconfig get pods -n wiredbrain

kubectl --kubeconfig least-privilege.kubeconfig auth can-i --list
```
