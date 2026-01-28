# 3. Ciclo de Vida de Pods

## 📖 Introducción

Entender el ciclo de vida de los Pods y sus políticas de reinicio es crucial para gestionar aplicaciones en Kubernetes.

## 🎯 Objetivos

- [ ] Entender las fases del ciclo de vida
- [ ] Configurar restart policies
- [ ] Manejar container restarts y backoff

## 📚 Conceptos Clave

### Fases del Pod

| Fase | Descripción |
|------|-------------|
| **Pending** | Pod aceptado pero contenedores no creados |
| **Running** | Pod asignado a nodo, al menos un contenedor corriendo |
| **Succeeded** | Todos los contenedores terminaron exitosamente |
| **Failed** | Todos los contenedores terminaron, al menos uno falló |
| **Unknown** | Estado del Pod no puede determinarse |

### Container States

- **Waiting**: Esperando para iniciar
- **Running**: Ejecutándose
- **Terminated**: Terminado (exitoso o fallido)

### Restart Policies

| Policy | Comportamiento |
|--------|----------------|
| **Always** | Siempre reinicia (default) |
| **OnFailure** | Solo reinicia si falla (exit code != 0) |
| **Never** | Nunca reinicia |

## 💻 Comandos Principales

### Ver Restart Count

```bash
kubectl get pods
# Columna RESTARTS muestra cuántas veces se reinició
```

### Describir Pod

```bash
kubectl describe pod <name>
```

**Busca**:
- **State**: Estado actual del contenedor
- **Last State**: Estado anterior
- **Restart Count**: Número de reinicios
- **Events**: Historial de eventos

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Restart Policy Always (Default)

**Pasos**:

1. **Watch eventos**
   ```bash
   kubectl get events --watch &
   ```

2. **Crear Pod**
   ```bash
   kubectl apply -f pod.yaml
   ```

3. **Matar el proceso**
   ```bash
   kubectl exec -it hello-world-pod -- /usr/bin/killall hello-app
   ```

4. **Ver restart count**
   ```bash
   kubectl get pods
   # RESTARTS aumentó en 1
   ```

5. **Describir Pod**
   ```bash
   kubectl describe pod hello-world-pod
   ```
   
   **Observa**:
   - State: Running
   - Last State: Terminated, Exit Code: 143 (SIGTERM)
   - Restart Count: 1

6. **Limpiar**
   ```bash
   kubectl delete pod hello-world-pod
   fg
   # Ctrl+C
   ```

---

### Ejemplo 2: Restart Policies Comparison

**Manifiesto** ([pod-restart-policy.yaml](./pod-restart-policy.yaml)):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-world-never-pod
spec:
  restartPolicy: Never
  containers:
  - name: hello-world
    image: psk8s.azurecr.io/hello-app:1.0
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-world-onfailure-pod
spec:
  restartPolicy: OnFailure
  containers:
  - name: hello-world
    image: psk8s.azurecr.io/hello-app:1.0
```

**Pasos**:

1. **Crear Pods**
   ```bash
   kubectl apply -f pod-restart-policy.yaml
   kubectl get pods
   ```

2. **Matar app en Pod con Never**
   ```bash
   kubectl exec -it hello-world-never-pod -- /usr/bin/killall hello-app
   kubectl get pods
   ```
   
   **Resultado**: Estado cambia a `Error`, no se reinicia

3. **Describir Pod**
   ```bash
   kubectl describe pod hello-world-never-pod
   ```
   
   **Observa**:
   - State: Terminated
   - Exit Code: 143
   - Ready: False
   - Restart Count: 0

4. **Matar app en Pod con OnFailure**
   ```bash
   kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
   kubectl get pods
   ```
   
   **Resultado**: RESTARTS aumenta, Pod se reinicia

5. **Matar de nuevo (backoff)**
   ```bash
   kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
   kubectl get pods
   ```
   
   **Resultado**: Estado `Error` temporalmente (backoff de 10s), luego `Running`

6. **Ver eventos de backoff**
   ```bash
   kubectl describe pod hello-world-onfailure-pod
   ```
   
   **Busca**: `Back-off restarting failed container`

7. **Limpiar**
   ```bash
   kubectl delete pod hello-world-never-pod
   kubectl delete pod hello-world-onfailure-pod
   ```

---

## 📝 Restart Policy por Tipo de Workload

| Workload | Restart Policy Recomendada |
|----------|----------------------------|
| **Deployment** | Always |
| **Job** | OnFailure o Never |
| **CronJob** | OnFailure o Never |
| **DaemonSet** | Always |

## ✅ Cuándo Usar Cada Policy

- ✅ **Always**: Servicios web, APIs, daemons
- ✅ **OnFailure**: Batch jobs, procesamiento de datos
- ✅ **Never**: Jobs de una sola ejecución, migrations

## ❌ Cuándo NO Usar

- ❌ **Never en Deployments**: Pods no se recuperarán de fallos
- ❌ **Always en Jobs**: Jobs nunca completarán

## 💡 Mejores Prácticas

1. **Usa Always para servicios**: Asegura disponibilidad
2. **Implementa graceful shutdown**: Maneja SIGTERM correctamente
3. **Monitorea restart count**: Reinicios frecuentes indican problemas
4. **Configura liveness probes**: Para detectar deadlocks
5. **Entiende backoff**: Exponencial, máximo 5 minutos

## 🔗 Recursos

- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Container Restart Policy](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy)
- Siguiente: [4. Probes](./4-Probes.md)

## ⚠️ Troubleshooting

### Problema: CrashLoopBackOff
**Causa**: Contenedor falla repetidamente

**Solución**:
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Logs del contenedor anterior
kubectl describe pod <pod-name>
```

### Problema: Pod en Error y no reinicia
**Causa**: Restart policy es Never

**Solución**: Cambiar a OnFailure o Always según el caso de uso
