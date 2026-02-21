# 4. Probes y Health Checks

## 📖 Introducción

Las **probes** son health checks que Kubernetes usa para determinar si un contenedor está vivo, listo para recibir tráfico, o ha iniciado correctamente.

## 🎯 Objetivos

- [ ] Implementar liveness, readiness y startup probes
- [ ] Configurar timeouts y thresholds
- [ ] Debuggear problemas de probes

## 📚 Conceptos Clave

### Tipos de Probes

| Probe | Pregunta | Acción en Fallo |
|-------|----------|-----------------|
| **Liveness** | ¿Está vivo? | Reinicia el contenedor |
| **Readiness** | ¿Está listo? | Saca del Service (no recibe tráfico) |
| **Startup** | ¿Ha iniciado? | Espera antes de ejecutar otras probes |

### Métodos de Probe

1. **HTTP GET**: Request HTTP a un endpoint
2. **TCP Socket**: Intenta conectar a un puerto
3. **Exec**: Ejecuta un comando en el contenedor

### Configuración

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10    # Espera antes de la primera probe
  periodSeconds: 5           # Frecuencia de probes
  timeoutSeconds: 1          # Timeout por probe
  successThreshold: 1        # Éxitos consecutivos para "healthy"
  failureThreshold: 3        # Fallos consecutivos para "unhealthy"
```

## 💻 Ejemplo Práctico

### Ejemplo 1: Liveness y Readiness Probes

**Manifiesto con error** ([container-probes.yaml](./container-probes.yaml)):

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
        livenessProbe:
          httpGet:
            path: /
            port: 8081  # ERROR: debería ser 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8081  # ERROR: debería ser 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```

**Pasos**:

1. **Watch eventos**
   ```bash
   kubectl get events --watch &
   ```

2. **Desplegar con probes incorrectas**
   ```bash
   kubectl apply -f container-probes.yaml
   ```

3. **Ver estado del Pod**
   ```bash
   kubectl get pods
   ```
   
   **Observa**:
   - READY: 0/1 (no está ready)
   - RESTARTS: Aumentando (liveness probe falla)

4. **Describir Pod**
   ```bash
   kubectl describe pods
   ```
   
   **Busca**:
   - Events: `Liveness probe failed`, `Readiness probe failed`
   - Liveness/Readiness config: Ambos apuntan a puerto 8081
   - Container Port: 8080 (el correcto)
   - Ready: False

5. **Corregir las probes**
   ```bash
   # Editar container-probes.yaml
   # Cambiar port: 8081 a port: 8080 en ambas probes
   
   kubectl apply -f container-probes.yaml
   ```

6. **Verificar corrección**
   ```bash
   kubectl describe pods
   ```
   
   **Observa**:
   - Liveness/Readiness: Ahora apuntan a 8080
   - Ready: True (después de initialDelaySeconds)

7. **Ver Pods**
   ```bash
   kubectl get pods
   ```
   
   **Resultado**:
   - Nuevo Pod creado (Deployment actualizó)
   - READY: 1/1 después de 10 segundos
   - Pod antiguo terminado por liveness probe

8. **Limpiar**
   ```bash
   kubectl delete deployment hello-world
   fg
   # Ctrl+C
   ```

---

### Ejemplo 2: Startup Probe

**Manifiesto** ([container-probes-startup.yaml](./container-probes-startup.yaml)):

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
        startupProbe:
          httpGet:
            path: /
            port: 8081  # ERROR intencional
          failureThreshold: 1
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          periodSeconds: 5
```

**Pasos**:

1. **Watch eventos**
   ```bash
   kubectl get events --watch &
   ```

2. **Desplegar con startup probe incorrecta**
   ```bash
   kubectl apply -f container-probes-startup.yaml
   ```
   
   **Observa**:
   - Startup probe falla
   - Liveness y readiness NO se ejecutan (esperan a startup)
   - Contenedor se reinicia después de failureThreshold

3. **Ver restarts**
   ```bash
   kubectl get pods
   # RESTARTS: 1 o más
   ```

4. **Corregir startup probe**
   ```bash
   # Editar: cambiar port: 8081 a port: 8080
   kubectl apply -f container-probes-startup.yaml
   ```

5. **Verificar éxito**
   ```bash
   kubectl get pods
   # READY: 1/1
   ```

6. **Limpiar**
   ```bash
   kubectl delete -f container-probes-startup.yaml
   fg
   # Ctrl+C
   ```

---

## 📝 Configuración Recomendada

### Web Application

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
```

### Database

```yaml
livenessProbe:
  tcpSocket:
    port: 5432
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## ✅ Cuándo Usar Cada Probe

### Liveness Probe
- ✅ Detectar deadlocks
- ✅ Aplicaciones que pueden quedar en estado irrecuperable
- ✅ Reiniciar contenedores "zombies"

### Readiness Probe
- ✅ Aplicaciones con warmup largo
- ✅ Dependencias externas (DB, cache)
- ✅ Evitar enviar tráfico a Pods no listos

### Startup Probe
- ✅ Aplicaciones con inicio muy lento
- ✅ Evitar que liveness mate el contenedor durante startup
- ✅ Legacy apps con tiempos de inicio impredecibles

## ❌ Cuándo NO Usar

- ❌ **Liveness sin readiness**: Puede causar cascading failures
- ❌ **Probes muy agresivas**: failureThreshold muy bajo
- ❌ **Probes muy lentas**: initialDelay muy alto
- ❌ **Probes que dependen de externos**: Pueden causar reinicios innecesarios

## 💡 Mejores Prácticas

1. **Siempre usa readiness probe**: Evita tráfico a Pods no listos
2. **Usa liveness con cuidado**: Solo para casos irrecuperables
3. **Endpoints dedicados**: `/healthz` y `/ready` separados
4. **Configura timeouts apropiados**: Basados en tu aplicación
5. **Startup probe para apps lentas**: Protege de liveness durante inicio
6. **Monitorea probe failures**: Alertas en fallos frecuentes

## 🧪 Ejercicios

### Ejercicio 1: Implementar Health Checks
**Tarea**: Crea un Deployment con liveness y readiness probes correctamente configuradas.

<details>
<summary>✅ Solución</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-healthy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

</details>

---

## 🔗 Recursos

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)
- Guía anterior: [3. Pod Lifecycle](./3-Pod-Lifecycle.md)

## 📚 Glosario

- **Liveness Probe**: Verifica si el contenedor está vivo
- **Readiness Probe**: Verifica si el contenedor está listo para tráfico
- **Startup Probe**: Verifica si la aplicación ha iniciado
- **failureThreshold**: Fallos consecutivos antes de marcar como unhealthy
- **initialDelaySeconds**: Espera antes de la primera probe

## ⚠️ Troubleshooting

### Problema: Pods reiniciando constantemente
**Causa**: Liveness probe falla

**Solución**:
```bash
kubectl describe pod <name>
# Revisar Events y Liveness config
# Ajustar initialDelaySeconds o failureThreshold
```

### Problema: Service no enruta tráfico
**Causa**: Readiness probe falla

**Solución**:
```bash
kubectl describe pod <name>
# Revisar Readiness probe y Conditions
kubectl logs <pod-name>
```

### Problema: Pod tarda mucho en estar Ready
**Causa**: initialDelaySeconds muy alto o app lenta

**Solución**: Usa startup probe para apps lentas, ajusta readiness probe
