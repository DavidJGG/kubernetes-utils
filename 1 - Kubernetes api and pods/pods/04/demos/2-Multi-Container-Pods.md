# 2. Multi-Container Pods

## 📖 Introducción

Los **Multi-Container Pods** permiten ejecutar múltiples contenedores que trabajan juntos en el mismo Pod, compartiendo recursos como red y almacenamiento.

## 🎯 Objetivos

- [ ] Entender patrones multi-contenedor
- [ ] Compartir volumes entre contenedores
- [ ] Acceder a contenedores específicos

## 📚 Conceptos Clave

### Patrones Multi-Contenedor

1. **Sidecar**: Contenedor auxiliar que extiende funcionalidad (logging, monitoring)
2. **Ambassador**: Proxy que simplifica conectividad
3. **Adapter**: Normaliza output de la aplicación principal

### Shared Resources

- **Network**: Todos los contenedores comparten la misma IP y localhost
- **Volumes**: Pueden compartir almacenamiento con `emptyDir` o `PersistentVolume`
- **IPC**: Pueden comunicarse vía Inter-Process Communication

## 💻 Comandos Principales

### Acceder a Contenedor Específico

```bash
# Primer contenedor (por defecto)
kubectl exec -it multicontainer-pod -- /bin/sh

# Contenedor específico
kubectl exec -it multicontainer-pod --container consumer -- /bin/sh
```

## 🔬 Ejemplo Práctico

### Producer-Consumer Pattern

**Manifiesto** ([multicontainer-pod.yaml](./multicontainer-pod.yaml)):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multicontainer-pod
spec:
  containers:
  - name: producer
    image: ubuntu
    command: ["/bin/bash"]
    args: ["-c", "while true; do echo $(hostname) $(date) >> /var/log/index.html; sleep 10; done"]
    volumeMounts:
    - name: webcontent
      mountPath: /var/log
  - name: consumer
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: webcontent
      mountPath: /usr/share/nginx/html
  volumes:
  - name: webcontent
    emptyDir: {}
```

**Pasos**:

1. **Crear Pod**
   ```bash
   kubectl apply -f multicontainer-pod.yaml
   ```

2. **Acceder al producer**
   ```bash
   kubectl exec -it multicontainer-pod -- /bin/sh
   ls -la /var/log
   tail /var/log/index.html
   exit
   ```

3. **Acceder al consumer**
   ```bash
   kubectl exec -it multicontainer-pod --container consumer -- /bin/sh
   ls -la /usr/share/nginx/html
   tail /usr/share/nginx/html/index.html
   exit
   ```

4. **Acceder vía port-forward**
   ```bash
   kubectl port-forward multicontainer-pod 8080:80 &
   curl http://localhost:8080
   fg
   # Ctrl+C
   ```

5. **Limpiar**
   ```bash
   kubectl delete pod multicontainer-pod
   ```

## ✅ Cuándo Usar

- ✅ **Logging sidecar**: Recolectar logs de la app principal
- ✅ **Service mesh**: Envoy/Istio proxy
- ✅ **Data synchronization**: Sincronizar datos entre contenedores

## ❌ Cuándo NO Usar

- ❌ **Servicios independientes**: Usa Pods separados
- ❌ **Escalado diferente**: Si necesitan escalar independientemente

## 🔗 Recursos

- [Multi-Container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)
- Siguiente: [2a. Init Containers](./2a-Init-Containers.md)
