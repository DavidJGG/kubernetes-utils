# Pods

Guías de referencia sobre Pods, la unidad fundamental de deployment en Kubernetes.

---

## 📑 Contenido

### Guías

1. **[Fundamentos de Pods](./1-Pods.md)**
   - Creación y gestión de Pods
   - `kubectl exec` y `kubectl port-forward`
   - Static Pods
   - Monitoreo de eventos

2. **[Multi-Container Pods](./2-Multi-Container-Pods.md)**
   - Patrones: sidecar, ambassador, adapter
   - Shared volumes y networking
   - Producer-consumer pattern

3. **[Init Containers](./2a-Init-Containers.md)**
   - Ejecución secuencial de setup
   - Casos de uso: migrations, dependencies
   - Monitoreo de init containers

4. **[Ciclo de Vida de Pods](./3-Pod-Lifecycle.md)**
   - Fases del Pod (Pending, Running, Succeeded, Failed)
   - Container states
   - Restart policies: Always, OnFailure, Never
   - Backoff y troubleshooting

5. **[Probes y Health Checks](./4-Probes.md)**
   - Liveness probes (¿está vivo?)
   - Readiness probes (¿está listo?)
   - Startup probes (¿ha iniciado?)
   - Configuración y debugging

---

## 📂 Archivos

### Scripts Shell
- `1-Pods.sh` - Operaciones básicas con Pods
- `2-Multi-Container-Pods.sh` - Patrones multi-contenedor
- `2a-Init-Containers.sh` - Init containers
- `3-Pod-Lifecycle.sh` - Ciclo de vida y restart policies
- `4-Probes.sh` - Health checks

### Manifiestos YAML
- `pod.yaml` - Pod simple
- `deployment.yaml` - Deployment básico
- `multicontainer-pod.yaml` - Producer-consumer pattern
- `init-containers.yaml` - Init containers example
- `pod-restart-policy.yaml` - Restart policies
- `container-probes.yaml` - Liveness y readiness
- `container-probes-startup.yaml` - Startup probe

### Material Complementario
- `running-and-managing-pods-slides.pdf`

---

## 🔑 Comandos Principales

```bash
# Gestión básica
kubectl apply -f pod.yaml
kubectl get pods
kubectl describe pod <nombre>
kubectl delete pod <nombre>

# Debugging
kubectl logs <pod>
kubectl exec -it <pod> -- sh
kubectl port-forward <pod> 8080:80

# Monitoreo
kubectl get events --watch
kubectl get pods -o wide
```

---

## 🔗 Enlaces

- [Pod Overview](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

