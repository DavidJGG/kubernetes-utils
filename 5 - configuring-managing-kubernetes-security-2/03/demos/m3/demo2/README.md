# Demo: Secure Secrets with CSI Driver

This demo demonstrates how to replace insecure database credentials with Azure Key Vault integration using the Secrets Store CSI Driver in the WiredBrain Coffee application.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Kubernetes](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) - Package manager for Kubernetes

## Setup

Run the setup script to create the Azure resources:

```powershell
./setup.ps1
```

> Creates Resource Group, AKS cluster, Key Vault, stores database password, and configures CSI Driver with managed identity

## Demo

### Deploy application with Kubernetes Secrets

Deploy the WiredBrain app using Kubernetes Secrets for database credentials:

- [database.yaml](/m3/demo2/charts/wiredbrain/templates/database.yaml) - Database using secretKeyRef

<!--HIGHLIGHT>
secretKeyRef:
-->

- [secret.yaml](/m3/demo2/charts/wiredbrain/templates/secret.yaml) - Secret with plain-text stringData

<!--HIGHLIGHT>
stringData:
password:
-->

- [values.yaml](/m3/demo2/charts/wiredbrain/values.yaml) - Secret with plain-text stringData

<!--HIGHLIGHT>
password: "wired"
-->

> The first attack vector is source control - password stored in plain text.

Deploy the app:

```powershell
helm install wiredbrain ./charts/wiredbrain `
  --namespace wiredbrain --create-namespace `
  --wait
```

### Check if the password is secret

Check the Kubernetes Secret - it is just encoded text:

```powershell
kubectl get secret -n wiredbrain database-credentials -o yaml | yq .data

kubectl get secret -n wiredbrain database-credentials -o go-template='{{.data.password | base64decode}}'
```

> Second attack vector is Secrets access - they use base64 encoding, not encryption.

Check how the Pods use the secret:

```powershell
kubectl get pod -n wiredbrain -l component=database -o jsonpath='{.items[0].spec.containers[0].env}'

kubectl exec -n wiredbrain deploy/wiredbrain-database -- printenv POSTGRES_PASSWORD
```

> Third attack vector is Pod exec - password in plain text environment variable.

### Use secrets in Key Vault

The setup script created Key Vault with proper secrets:

```powershell
az keyvault secret list --vault-name psod-kv-m3d2 -o table

az keyvault secret show --vault-name psod-kv-m3d2 --name postgres-password --query value -o tsv

az keyvault secret show --vault-name psod-kv-m3d2 --name application-properties --query value -o tsv
```

> Securely stored in Azure Key Vault with access policies and audit logging.

### Upgrade to secure chart with CSI driver

Upgrade to the secure Helm chart that uses CSI driver for secrets:

- [secret-provider.yaml](/m3/demo2/charts/wiredbrain-secure/templates/secret-provider.yaml) - will surface Key Vault secrets as volumes

<!--HIGHLIGHT>
keyvaultName:
objectName: {{ .Values.secrets.postgresPassword }}
objectAlias: postgres-password
-->

- [serviceaccount.yaml](/m3/demo2/charts/wiredbrain-secure/templates/serviceaccount.yaml) - ServiceAccount with workload identity annotation

<!--HIGHLIGHT>
azure.workload.identity/client-id
-->

- [database.yaml](/m3/demo2/charts/wiredbrain-secure/templates/database.yaml) - Database with CSI volume

<!--HIGHLIGHT>
azure.workload.identity/use: "true"
- name: POSTGRES_PASSWORD_FILE
mountPath: "/mnt/secrets"
driver: secrets-store.csi.k8s.io
secretProviderClass: "database-credentials"
-->

Upgrade the release with the new secure chart:

```powershell
helm upgrade wiredbrain ./charts/wiredbrain-secure `
  -f ./charts/wiredbrain-secure/values.yaml `
  -f ./charts/wiredbrain-secure/values-csi.yaml `
  --namespace wiredbrain `
  --wait
```

> Helm upgrade switches to the secure chart, creating SecretProviderClass and updating deployments.

### Check the password files

No secrets or environment variables to read:

```powershell
kubectl get secret -n wiredbrain database-credentials 

kubectl exec -n wiredbrain deploy/wiredbrain-database -- printenv POSTGRES_PASSWORD
```

Password is loaded from file mounted directly from Key Vault - never stored in etcd:

```powershell
kubectl exec -n wiredbrain deploy/wiredbrain-database -- ls -la /mnt/secrets

kubectl exec -n wiredbrain deploy/wiredbrain-database -- cat /mnt/secrets/postgres-password
```

> Secrets are mounted as read-only files - applications read directly from the CSI volume.
