# 1. Fundamentos de Pods

## 📖 Introducción

Los **Pods** son la unidad más pequeña y básica de deployment en Kubernetes. Un Pod representa un proceso corriendo en tu cluster y encapsula uno o más contenedores, almacenamiento compartido, y opciones de red.

## 🎯 Objetivos

- [ ] Entender qué es un Pod y su rol en Kubernetes
- [ ] Crear y gestionar Pods
- [ ] Usar kubectl exec y port-forward para debugging
- [ ] Entender Static Pods
- [ ] Monitorear eventos de Pods

## 📚 Conceptos Clave

### ¿Qué es un Pod?

- **Unidad atómica**: El objeto más pequeño que puedes crear en Kubernetes
- **Uno o más contenedores**: Generalmente uno, pero puede tener varios
- **Efímero**: Los Pods son temporales y reemplazables
- **IP compartida**: Todos los contenedores en un Pod comparten la misma IP
- **Almacenamiento compartido**: Pueden compartir volumes

### Pod vs Deployment

| Aspecto | Pod | Deployment |
|---------|-----|------------|
| **Uso** | Testing, debugging | Producción |
| **Réplicas** | Solo 1 | Múltiples |
| **Auto-healing** | No | Sí |
| **Rolling updates** | No | Sí |

### Static Pods

**Static Pods** son gestionados directamente por kubelet en un nodo específico, no por el API Server. Se definen en archivos en el nodo.

## 💻 Comandos Principales

### Comando 1: `kubectl apply -f pod.yaml`

**Propósito**: Crear un Pod desde un manifiesto.

**Ejemplo**:
```bash
kubectl apply -f pod.yaml
kubectl get pods
```

---

### Comando 2: `kubectl get events --watch`

**Propósito**: Monitorear eventos del cluster en tiempo real.

**Ejemplo**:
```bash
# Iniciar watch en background
kubectl get events --watch &

# Crear recursos y ver eventos
kubectl apply -f pod.yaml
kubectl apply -f deployment.yaml

# Detener watch
fg
# Ctrl+C
```

**Eventos típicos**:
- Scheduling
- Image pulling
- Container starting
- Pod deletion

---

### Comando 3: `kubectl scale deployment`

**Propósito**: Cambiar el número de réplicas.

**Ejemplo**:
```bash
# Escalar a 2 réplicas
kubectl scale deployment hello-world --replicas=2

# Escalar a 1
kubectl scale deployment hello-world --replicas=1

# Ver Pods
kubectl get pods
```

---

### Comando 4: `kubectl exec`

**Propósito**: Ejecutar comandos dentro de un contenedor.

**Sintaxis**:
```bash
kubectl exec -it <pod-name> -- <comando>
```

**Ejemplos**:
```bash
# Shell interactivo
kubectl exec -it hello-world-pod -- /bin/sh

# Dentro del contenedor
ps
exit

# Comando único
kubectl exec hello-world-pod -- ps aux

# Con verbosity para ver requests API
kubectl -v 6 exec -it hello-world-pod -- /bin/sh
```

---

### Comando 5: `kubectl port-forward`

**Propósito**: Reenviar puertos locales a un Pod para testing.

**Sintaxis**:
```bash
kubectl port-forward <pod-name> <local-port>:<pod-port>
```

**Ejemplos**:
```bash
# Puerto privilegiado (requiere sudo/admin)
kubectl port-forward hello-world-pod 80:8080

# Puerto no privilegiado
kubectl port-forward hello-world-pod 8080:8080 &

# Acceder con curl
curl http://localhost:8080

# Detener port-forward
fg
# Ctrl+C
```

---

### Comando 6: `kubectl get pods -o wide`

**Propósito**: Ver información extendida de Pods (IP, nodo).

**Ejemplo**:
```bash
kubectl get pods -o wide
```

**Output**:
```
NAME              READY   STATUS    IP           NODE
hello-world-pod   1/1     Running   10.244.1.5   c1-node1
```

---

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Ciclo de Vida Básico de un Pod

**Pasos**:

1. **Monitorear eventos**
   ```bash
   kubectl get events --watch &
   ```

2. **Crear Pod**
   ```bash
   kubectl apply -f pod.yaml
   ```
   
   **Eventos observados**:
   - Scheduled: Pod asignado a un nodo
   - Pulling: Descargando imagen
   - Pulled: Imagen descargada
   - Created: Contenedor creado
   - Started: Contenedor iniciado

3. **Verificar Pod**
   ```bash
   kubectl get pods
   ```

4. **Eliminar Pod**
   ```bash
   kubectl delete pod hello-world-pod
   ```

5. **Detener watch**
   ```bash
   fg
   # Ctrl+C
   ```

---

### Ejemplo 2: Deployment y Escalado

**Pasos**:

1. **Crear Deployment**
   ```bash
   kubectl apply -f deployment.yaml
   ```

2. **Ver eventos de creación**
   - Deployment created
   - ReplicaSet scaled
   - Pod started

3. **Escalar a 2 réplicas**
   ```bash
   kubectl scale deployment hello-world --replicas=2
   ```

4. **Escalar a 1 réplica**
   ```bash
   kubectl scale deployment hello-world --replicas=1
   ```
   
   **Eventos observados**:
   - ReplicaSet scaled down
   - Pod deletion
   - Container killed

---

### Ejemplo 3: Debugging con exec

**Pasos**:

1. **Obtener shell en el Pod**
   ```bash
   kubectl exec -it hello-world-pod -- /bin/sh
   ```

2. **Explorar el contenedor**
   ```bash
   # Ver procesos
   ps

   # Ver filesystem
   ls -la

   # Salir
   exit
   ```

3. **Ver requests API (con verbosity)**
   ```bash
   kubectl -v 6 exec -it hello-world-pod -- /bin/sh
   ```
   
   **Observa**: GET y POST requests al API Server

---

### Ejemplo 4: Port Forwarding

**Pasos**:

1. **Iniciar port-forward en background**
   ```bash
   kubectl port-forward hello-world-pod 8080:8080 &
   ```

2. **Acceder a la aplicación**
   ```bash
   curl http://localhost:8080
   ```

3. **Detener port-forward**
   ```bash
   fg
   # Ctrl+C
   ```

---

### Ejemplo 5: Static Pods

**Pasos**:

1. **Generar manifiesto**
   ```bash
   kubectl run hello-world --image=psk8s.azurecr.io/hello-app:2.0 \
     --dry-run=client -o yaml --port=8080
   ```

2. **SSH al nodo**
   ```bash
   ssh aen@c1-node1
   ```

3. **Encontrar staticPodPath**
   ```bash
   sudo cat /var/lib/kubelet/config.yaml | grep staticPodPath
   ```
   
   **Output**: `staticPodPath: /etc/kubernetes/manifests`

4. **Crear manifiesto en staticPodPath**
   ```bash
   sudo vi /etc/kubernetes/manifests/mypod.yaml
   # Pegar el YAML generado
   ```

5. **Salir del nodo**
   ```bash
   exit
   ```

6. **Ver el Pod (nombre incluye el nodo)**
   ```bash
   kubectl get pods -o wide
   ```
   
   **Output**: `hello-world-c1-node1`

7. **Intentar eliminar (se recrea automáticamente)**
   ```bash
   kubectl delete pod hello-world-c1-node1
   kubectl get pods
   ```

8. **Eliminar el manifiesto del nodo**
   ```bash
   ssh aen@c1-node1
   sudo rm /etc/kubernetes/manifests/mypod.yaml
   exit
   ```

9. **Verificar eliminación**
   ```bash
   kubectl get pods
   ```

---

## 📝 Manifiestos Relacionados

### [pod.yaml](./pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-world-pod
spec:
  containers:
  - name: hello-world
    image: psk8s.azurecr.io/hello-app:1.0
    ports:
    - containerPort: 80
```

### [deployment.yaml](./deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: psk8s.azurecr.io/hello-app:1.0
        ports:
        - containerPort: 8080
```

---

## ✅ Cuándo Usar

- ✅ **Pods directos**: Testing, debugging, jobs únicos
- ✅ **Deployments**: Aplicaciones stateless en producción
- ✅ **StatefulSets**: Aplicaciones stateful
- ✅ **Static Pods**: Componentes del sistema (kube-apiserver, etcd)

## ❌ Cuándo NO Usar

- ❌ **Pods en producción**: Usa Deployments para auto-healing
- ❌ **Sin resource limits**: Siempre define requests/limits
- ❌ **Datos persistentes en Pods**: Usa PersistentVolumes

## 💡 Mejores Prácticas

1. **Usa Deployments, no Pods directos** en producción
2. **Define resource requests y limits** siempre
3. **Usa liveness y readiness probes** para health checks
4. **Un proceso principal por contenedor** (principio de responsabilidad única)
5. **Usa labels** para organización
6. **Monitorea eventos** durante troubleshooting

## 🧪 Ejercicios

### Ejercicio 1: Crear y Debuggear un Pod
**Tarea**: Crea un Pod nginx, accede a su shell, y verifica que nginx está corriendo.

<details>
<summary>✅ Solución</summary>

```bash
# Crear Pod
kubectl run nginx --image=nginx

# Verificar
kubectl get pods

# Acceder al shell
kubectl exec -it nginx -- /bin/bash

# Verificar nginx
ps aux | grep nginx
curl localhost

# Salir
exit

# Limpiar
kubectl delete pod nginx
```

</details>

---

## 🔗 Recursos Adicionales

- [Pod Overview](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- Siguiente guía: [2. Multi-Container Pods](./2-Multi-Container-Pods.md)

## 📚 Glosario

- **Pod**: Unidad básica de deployment en Kubernetes
- **Ephemeral**: Temporal, no persistente
- **Static Pod**: Pod gestionado por kubelet, no por API Server
- **Port Forwarding**: Reenvío de puertos para acceso local

## ⚠️ Troubleshooting

### Problema: Pod en estado Pending
**Causa**: No hay recursos suficientes o problemas de scheduling

**Solución**:
```bash
kubectl describe pod <name>
# Revisar Events
```

### Problema: Pod en CrashLoopBackOff
**Causa**: Contenedor falla al iniciar

**Solución**:
```bash
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```
