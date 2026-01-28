# Módulo 04: Pods

## 📖 Descripción

Este módulo cubre todo sobre Pods, la unidad fundamental de deployment en Kubernetes, desde conceptos básicos hasta patrones avanzados como multi-container, init containers, y health checks.

## 🎯 Objetivos del Módulo

- Dominar la creación y gestión de Pods
- Implementar patrones multi-container
- Configurar init containers para setup
- Entender el ciclo de vida y restart policies
- Implementar health checks con probes

## 📚 Prerequisitos

- Módulos 02 y 03 completados
- Cluster de Kubernetes funcional
- Conocimientos de contenedores

## 📑 Contenido del Módulo

### Guías de Aprendizaje

1. **[Fundamentos de Pods](./1-Pods.md)**
   - Creación y gestión de Pods
   - kubectl exec y port-forward
   - Static Pods
   - Monitoreo de eventos

2. **[Multi-Container Pods](./2-Multi-Container-Pods.md)**
   - Patrones sidecar, ambassador, adapter
   - Shared volumes y networking
   - Acceso a contenedores específicos

3. **[Init Containers](./2a-Init-Containers.md)**
   - Ejecución secuencial de setup
   - Casos de uso (migrations, dependencies)
   - Monitoreo de init containers

4. **[Ciclo de Vida de Pods](./3-Pod-Lifecycle.md)**
   - Fases del Pod (Pending, Running, Succeeded, Failed)
   - Container states
   - Restart policies (Always, OnFailure, Never)
   - Backoff y troubleshooting

5. **[Probes y Health Checks](./4-Probes.md)**
   - Liveness probes (¿está vivo?)
   - Readiness probes (¿está listo?)
   - Startup probes (¿ha iniciado?)
   - Configuración y debugging

### Archivos de Demostración

#### Scripts Shell
- `1-Pods.sh` - Operaciones básicas con Pods
- `2-Multi-Container-Pods.sh` - Patrones multi-contenedor
- `2a-Init-Containers.sh` - Init containers
- `3-Pod-Lifecycle.sh` - Ciclo de vida y restart policies
- `4-Probes.sh` - Health checks

#### Manifiestos YAML
- `pod.yaml` - Pod simple
- `deployment.yaml` - Deployment básico
- `multicontainer-pod.yaml` - Producer-consumer pattern
- `init-containers.yaml` - Init containers example
- `pod-restart-policy.yaml` - Restart policies
- `container-probes.yaml` - Liveness y readiness
- `container-probes-startup.yaml` - Startup probe

## 🚀 Orden de Estudio Recomendado

1. **Guía 1**: Fundamentos - Base esencial
2. **Guía 2**: Multi-Container - Patrones avanzados
3. **Guía 3**: Init Containers - Setup y prerequisites
4. **Guía 4**: Lifecycle - Gestión de estados
5. **Guía 5**: Probes - Health checks en producción

## 💡 Conceptos Clave

- **Pod**: Unidad básica de deployment
- **Multi-Container**: Múltiples contenedores en un Pod
- **Init Container**: Contenedor de setup pre-app
- **Restart Policy**: Comportamiento ante fallos
- **Liveness Probe**: Detecta contenedores muertos
- **Readiness Probe**: Controla tráfico del Service
- **Startup Probe**: Protege apps con inicio lento

## 📊 Comandos Clave

| Comando | Propósito |
|---------|-----------|
| `kubectl apply -f pod.yaml` | Crear Pod |
| `kubectl get pods` | Listar Pods |
| `kubectl describe pod <name>` | Ver detalles |
| `kubectl logs <pod>` | Ver logs |
| `kubectl exec -it <pod> -- sh` | Shell en contenedor |
| `kubectl port-forward <pod> 8080:80` | Port forwarding |
| `kubectl delete pod <name>` | Eliminar Pod |

## ✅ Checklist de Dominio

- [ ] Puedo crear y gestionar Pods
- [ ] Entiendo cuándo usar Pods vs Deployments
- [ ] Puedo implementar patrones multi-container
- [ ] Sé configurar init containers
- [ ] Entiendo restart policies y cuándo usar cada una
- [ ] Puedo configurar liveness y readiness probes
- [ ] Sé debuggear Pods con problemas

## 🔗 Recursos Adicionales

- [Pod Overview](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- **Slides**: `running-and-managing-pods-slides.pdf`

## ➡️ Próximos Pasos

Después de dominar Pods, explora:
- **Services**: Networking y load balancing
- **ConfigMaps y Secrets**: Configuración y datos sensibles
- **Volumes**: Almacenamiento persistente
- **StatefulSets**: Aplicaciones stateful

---

**¡Feliz aprendizaje! 🚀**
