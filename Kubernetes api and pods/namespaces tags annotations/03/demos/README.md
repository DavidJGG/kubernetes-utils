# Namespaces, Labels y Annotations

Guías de referencia sobre organización y gestión de recursos en Kubernetes.

---

## 📑 Contenido

### Guías

1. **[Namespaces](./1-namespaces.md)**
   - Creación y gestión de namespaces
   - Recursos namespaced vs cluster-scoped
   - Multi-tenancy y aislamiento
   - Comandos: `kubectl create namespace`, `kubectl get -n`, `kubectl -A`

2. **[Labels y Selectors](./2-labels.md)**
   - Creación y gestión de labels
   - Queries con selectors (equality y set-based)
   - Labels en Deployments y Services
   - Node selection con `nodeSelector`
   - Comandos: `kubectl label`, `kubectl get -l`, `kubectl get --show-labels`

---

## 📂 Archivos

### Scripts Shell
- `1-namespaces.sh` - Gestión de namespaces
- `2-labels.sh` - Labels, selectors y node selection

### Manifiestos YAML
- `namespace.yaml` - Namespace declarativo
- `deployment.yaml` - Deployment con namespace
- `CreatePodsWithLabels.yaml` - Pods con diferentes labels
- `PodsToNodes.yaml` - Pods con nodeSelector
- `service.yaml` - Service con selector
- `deployment-label.yaml` - Deployment para demos de labels

### Material Complementario
- `managing-objects-with-labels-annotations-and-namespaces-slides.pdf`

---

## 🔑 Comandos Principales

```bash
# Namespaces
kubectl create namespace <nombre>
kubectl get pods -n <namespace>
kubectl get pods --all-namespaces  # o -A
kubectl delete namespace <nombre>

# Labels
kubectl label <recurso> <nombre> key=value
kubectl get pods -l key=value
kubectl get pods --show-labels
kubectl get pods -L tier,app
```

---

## 🔗 Enlaces

- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

