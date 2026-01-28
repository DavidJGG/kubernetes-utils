# 3. Anatomía de un Request API

## 📖 Introducción

Cada comando de `kubectl` se traduce en una petición HTTP al API Server de Kubernetes. Entender cómo funcionan estos requests te ayudará a debuggear problemas, optimizar operaciones, y trabajar directamente con la API cuando sea necesario.

## 🎯 Objetivos de Aprendizaje

Al completar esta guía, serás capaz de:
- [ ] Entender cómo kubectl se comunica con el API Server
- [ ] Usar el flag `-v` para ver detalles de requests HTTP
- [ ] Trabajar con kubectl proxy para acceder a la API directamente
- [ ] Interpretar códigos de respuesta HTTP (200, 201, 404, 403)
- [ ] Debuggear problemas de autenticación y autorización
- [ ] Monitorear recursos con watch requests

## 📚 Conceptos Clave

### API Server

El **API Server** es el componente central de Kubernetes que:
- Expone la API REST de Kubernetes
- Valida y procesa requests
- Persiste el estado en etcd
- Maneja autenticación y autorización

### Verbos HTTP

Kubernetes usa verbos HTTP estándar:

| Verbo | Operación kubectl | Propósito |
|-------|-------------------|-----------|
| **GET** | `get`, `describe` | Leer recursos |
| **POST** | `create`, `apply` (nuevo) | Crear recursos |
| **PUT** | `replace` | Reemplazar recurso completo |
| **PATCH** | `apply` (existente), `edit` | Actualizar parcialmente |
| **DELETE** | `delete` | Eliminar recursos |

### Códigos de Respuesta HTTP

| Código | Significado | Ejemplo |
|--------|-------------|---------|
| **200 OK** | Operación exitosa | GET de un Pod existente |
| **201 Created** | Recurso creado | POST de un nuevo Deployment |
| **404 Not Found** | Recurso no existe | GET de un Pod inexistente |
| **403 Forbidden** | Sin permisos | Autenticación fallida |
| **409 Conflict** | Conflicto de recursos | Crear recurso que ya existe |

### Verbosity Levels

El flag `-v` controla el nivel de detalle:

| Nivel | Información Mostrada |
|-------|---------------------|
| `-v 0` | Solo output normal |
| `-v 6` | URL del request y código de respuesta |
| `-v 7` | Headers del request HTTP |
| `-v 8` | Headers de respuesta y body truncado |
| `-v 9` | Headers y body completo de respuesta |

### kubectl proxy

`kubectl proxy` crea un servidor proxy local que:
- Autentica automáticamente usando tu kubeconfig
- Permite acceder a la API con `curl` o navegador
- Útil para debugging y desarrollo

## 💻 Comandos Principales

### Comando 1: `kubectl -v <nivel>`

**Propósito**: Ver detalles de la comunicación HTTP con el API Server.

**Sintaxis**:
```bash
kubectl <comando> -v <nivel>
```

**Ejemplos**:

```bash
# Crear un Pod para los ejemplos
kubectl apply -f pod.yaml

# Nivel 6: Ver URL y código de respuesta
kubectl get pod hello-world -v 6

# Nivel 7: Agregar headers del request
kubectl get pod hello-world -v 7

# Nivel 8: Agregar headers de respuesta
kubectl get pod hello-world -v 8

# Nivel 9: Ver respuesta completa (JSON)
kubectl get pod hello-world -v 9
```

**Output Esperado (v6)**:
```
I0127 19:00:00.123456    1234 round_trippers.go:454] GET https://172.16.94.10:6443/api/v1/namespaces/default/pods/hello-world 200 OK in 15 milliseconds
```

**Explicación**:
- **GET**: Verbo HTTP usado
- **URL**: Ruta completa del recurso
- **200 OK**: Código de respuesta exitoso
- **15 milliseconds**: Tiempo de respuesta

---

### Comando 2: `kubectl proxy`

**Propósito**: Crear un proxy local para acceder a la API directamente.

**Sintaxis**:
```bash
kubectl proxy [--port=<puerto>]
```

**Ejemplos**:

```bash
# Iniciar proxy en puerto por defecto (8001)
kubectl proxy &

# Acceder a la API con curl
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world

# Ver solo las primeras líneas
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world | head -n 10

# Detener el proxy
fg
# Presionar Ctrl+C
```

**Output Esperado**:
```json
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "hello-world",
    "namespace": "default",
    ...
  }
}
```

**Explicación**: El proxy maneja la autenticación, permitiéndote hacer requests HTTP simples.

---

### Comando 3: `kubectl get --watch`

**Propósito**: Monitorear cambios en recursos en tiempo real.

**Sintaxis**:
```bash
kubectl get <recurso> --watch [-v <nivel>]
```

**Ejemplos**:

```bash
# Watch en Pods con verbosity
kubectl get pods --watch -v 6 &

# En otra terminal, crear un Pod
kubectl apply -f pod.yaml

# Ver las actualizaciones en tiempo real
# Detener el watch
fg
# Presionar Ctrl+C
```

**Output Esperado**:
```
I0127 19:00:00.123456    1234 round_trippers.go:454] GET https://172.16.94.10:6443/api/v1/namespaces/default/pods?watch=true
NAME          READY   STATUS    RESTARTS   AGE
hello-world   0/1     Pending   0          0s
hello-world   0/1     ContainerCreating   0          1s
hello-world   1/1     Running             0          3s
```

**Explicación**: Watch mantiene una conexión TCP abierta y recibe actualizaciones en streaming.

---

### Comando 4: `kubectl logs -v`

**Propósito**: Ver logs de contenedores y el request HTTP subyacente.

**Sintaxis**:
```bash
kubectl logs <pod> [-v <nivel>]
```

**Ejemplos**:

```bash
# Ver logs normalmente
kubectl logs hello-world

# Ver el request HTTP usado
kubectl logs hello-world -v 6

# Acceder a logs vía proxy
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world/log
fg
# Presionar Ctrl+C
```

**Output Esperado (v6)**:
```
I0127 19:00:00.123456    1234 round_trippers.go:454] GET https://172.16.94.10:6443/api/v1/namespaces/default/pods/hello-world/log 200 OK in 20 milliseconds
```

**Explicación**: Los logs se obtienen mediante un GET request a `/log` del Pod.

---

### Comando 5: `kubectl exec -v`

**Propósito**: Ejecutar comandos en contenedores y ver la comunicación API.

**Sintaxis**:
```bash
kubectl exec <pod> [-v <nivel>] -- <comando>
```

**Ejemplos**:

```bash
# Ejecutar comando con verbosity
kubectl -v 6 exec -it hello-world -- /bin/sh

# Dentro del contenedor
ps
exit

# Ver los requests GET y POST
```

**Output Esperado**:
```
I0127 19:00:00.123456    1234 round_trippers.go:454] GET https://172.16.94.10:6443/api/v1/namespaces/default/pods/hello-world
I0127 19:00:01.123456    1234 round_trippers.go:454] POST https://172.16.94.10:6443/api/v1/namespaces/default/pods/hello-world/exec?command=%2Fbin%2Fsh...
```

**Explicación**: 
1. GET para verificar que el Pod existe
2. POST para establecer la sesión exec

---

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Analizar un GET Request

**Escenario**: Quieres entender cómo kubectl obtiene información de un Pod.

**Pasos**:

1. **Crear un Pod**
   ```bash
   kubectl apply -f pod.yaml
   ```

2. **GET con nivel de verbosity 6**
   ```bash
   kubectl get pod hello-world -v 6
   ```
   
   **Output**:
   ```
   GET https://172.16.94.10:6443/api/v1/namespaces/default/pods/hello-world 200 OK in 15 milliseconds
   ```

3. **GET con nivel 7 (ver headers del request)**
   ```bash
   kubectl get pod hello-world -v 7
   ```
   
   **Output adicional**:
   ```
   Request Headers:
     Accept: application/json
     User-Agent: kubectl/v1.28.0
   ```

4. **GET con nivel 9 (ver respuesta completa)**
   ```bash
   kubectl get pod hello-world -v 9 | grep -A 20 "Response Body"
   ```

**Resultado**: Entiendes la estructura completa del request HTTP.

---

### Ejemplo 2: Usar kubectl proxy

**Escenario**: Quieres acceder a la API directamente con curl.

**Pasos**:

1. **Iniciar el proxy**
   ```bash
   kubectl proxy &
   ```
   
   **Output**:
   ```
   Starting to serve on 127.0.0.1:8001
   ```

2. **Hacer un GET request con curl**
   ```bash
   curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world | head -n 10
   ```
   
   **Output**:
   ```json
   {
     "kind": "Pod",
     "apiVersion": "v1",
     "metadata": {
       "name": "hello-world",
       "namespace": "default",
       "uid": "abc-123-def",
       ...
     }
   }
   ```

3. **Listar todos los Pods**
   ```bash
   curl http://localhost:8001/api/v1/namespaces/default/pods
   ```

4. **Detener el proxy**
   ```bash
   fg
   # Presionar Ctrl+C
   ```

**Resultado**: Accediste a la API sin usar kubectl.

---

### Ejemplo 3: Monitorear Eventos con Watch

**Escenario**: Quieres ver eventos en tiempo real mientras creas y escalas recursos.

**Pasos**:

1. **Iniciar watch en Pods**
   ```bash
   kubectl get pods --watch -v 6 &
   ```

2. **Ver la conexión TCP abierta** (Linux/Mac)
   ```bash
   netstat -plant | grep kubectl
   ```
   
   **Output**:
   ```
   tcp   0   0   127.0.0.1:54321   172.16.94.10:6443   ESTABLISHED   1234/kubectl
   ```

3. **Crear un Deployment**
   ```bash
   kubectl apply -f deployment.yaml
   ```
   
   **Output del watch**:
   ```
   NAME                          READY   STATUS    RESTARTS   AGE
   hello-world-abc123-xyz        0/1     Pending   0          0s
   hello-world-abc123-xyz        0/1     ContainerCreating   0          1s
   hello-world-abc123-xyz        1/1     Running             0          3s
   ```

4. **Escalar el Deployment**
   ```bash
   kubectl scale deployment hello-world --replicas=2
   ```
   
   **Output del watch**:
   ```
   hello-world-abc123-def        0/1     Pending   0          0s
   hello-world-abc123-def        1/1     Running   0          2s
   ```

5. **Detener el watch**
   ```bash
   fg
   # Presionar Ctrl+C
   ```

**Resultado**: Viste actualizaciones en tiempo real mediante streaming HTTP.

---

### Ejemplo 4: Debuggear Autenticación

**Escenario**: Simular un error de autenticación para entender cómo se manifiesta.

**Pasos**:

1. **Hacer backup del kubeconfig**
   ```bash
   cp ~/.kube/config ~/.kube/config.ORIG
   ```

2. **Editar el kubeconfig con credenciales incorrectas**
   ```bash
   # Cambiar 'user: kubernetes-admin' por 'user: kubernetes-admin1'
   vi ~/.kube/config
   ```

3. **Intentar acceder al cluster**
   ```bash
   kubectl get pods -v 6
   ```
   
   **Output**:
   ```
   GET https://172.16.94.10:6443/api?timeout=32s 403 Forbidden in 5 milliseconds
   Error from server (Forbidden): pods is forbidden: User "kubernetes-admin1" cannot list resource "pods"
   ```

4. **Restaurar el kubeconfig**
   ```bash
   cp ~/.kube/config.ORIG ~/.kube/config
   ```

5. **Verificar acceso**
   ```bash
   kubectl get pods
   ```

**Resultado**: Entiendes cómo se ven los errores 403 de autenticación.

---

### Ejemplo 5: Analizar Creación y Eliminación

**Escenario**: Ver los requests HTTP involucrados en crear y eliminar un Deployment.

**Pasos**:

1. **Crear un Deployment con verbosity**
   ```bash
   kubectl apply -f deployment.yaml -v 6
   ```
   
   **Output**:
   ```
   GET https://172.16.94.10:6443/apis/apps/v1/namespaces/default/deployments/hello-world 404 Not Found in 10 milliseconds
   POST https://172.16.94.10:6443/apis/apps/v1/namespaces/default/deployments 201 Created in 25 milliseconds
   ```
   
   **Explicación**:
   - **GET 404**: Verifica si existe (no existe)
   - **POST 201**: Lo crea exitosamente

2. **Verificar el Deployment**
   ```bash
   kubectl get deployment
   ```

3. **Eliminar con verbosity**
   ```bash
   kubectl delete deployment hello-world -v 6
   ```
   
   **Output**:
   ```
   DELETE https://172.16.94.10:6443/apis/apps/v1/namespaces/default/deployments/hello-world 200 OK in 15 milliseconds
   GET https://172.16.94.10:6443/apis/apps/v1/namespaces/default/deployments/hello-world 200 OK in 5 milliseconds
   ```
   
   **Explicación**:
   - **DELETE 200**: Inicia la eliminación
   - **GET 200**: Verifica el estado de eliminación

**Resultado**: Entiendes el flujo completo de requests para crear y eliminar recursos.

---

## 📝 Estructura de URL de la API

### Formato General

```
https://<api-server>:<puerto>/<api-path>
```

### Ejemplos de Rutas

| Recurso | Ruta API |
|---------|----------|
| Pod | `/api/v1/namespaces/<namespace>/pods/<nombre>` |
| Deployment | `/apis/apps/v1/namespaces/<namespace>/deployments/<nombre>` |
| Service | `/api/v1/namespaces/<namespace>/services/<nombre>` |
| Node | `/api/v1/nodes/<nombre>` |
| Logs de Pod | `/api/v1/namespaces/<namespace>/pods/<nombre>/log` |
| Exec en Pod | `/api/v1/namespaces/<namespace>/pods/<nombre>/exec` |

### Core API vs API Groups

```
# Core API (v1) - sin grupo
/api/v1/namespaces/default/pods/my-pod

# API Groups (apps/v1) - con grupo
/apis/apps/v1/namespaces/default/deployments/my-deployment
```

---

## ✅ Cuándo Usar

- ✅ **-v 6**: Para debugging básico de problemas de conectividad
- ✅ **-v 9**: Para entender la estructura completa de respuestas
- ✅ **kubectl proxy**: Para desarrollo de herramientas que usan la API
- ✅ **--watch**: Para monitorear cambios en tiempo real
- ✅ **Análisis de requests**: Para optimizar performance o debuggear timeouts

## ❌ Cuándo NO Usar

- ❌ **-v 9 en producción**: Genera logs excesivos y puede exponer información sensible
- ❌ **kubectl proxy en producción**: Solo para desarrollo local
- ❌ **Watch sin límites**: Puede consumir recursos, usa con filtros
- ❌ **Acceso directo a la API sin autenticación**: Siempre usa kubectl proxy o tokens válidos

## 💡 Mejores Prácticas

1. **Usa -v 6 para debugging inicial**: Balance entre información y ruido
2. **Incrementa verbosity gradualmente**: 6 → 7 → 8 → 9 según necesites más detalle
3. **Usa kubectl proxy para experimentación**: Más fácil que manejar autenticación manualmente
4. **Monitorea conexiones watch**: Pueden quedarse abiertas indefinidamente
5. **Entiende los códigos de respuesta**: 200/201 = éxito, 404 = no existe, 403 = sin permisos
6. **Filtra logs de verbosity**: Usa `grep` para encontrar información relevante

## 🧪 Ejercicios

### Ejercicio 1: Identificar Verbos HTTP
**Objetivo**: Entender qué verbo HTTP usa cada operación de kubectl

**Tarea**: Ejecuta los siguientes comandos con `-v 6` e identifica el verbo HTTP usado:
1. `kubectl get pods`
2. `kubectl apply -f pod.yaml` (Pod nuevo)
3. `kubectl delete pod hello-world`

<details>
<summary>💡 Pista</summary>
Busca en el output líneas que contengan "GET", "POST", "DELETE", etc.
</details>

<details>
<summary>✅ Solución</summary>

```bash
# 1. GET pods
kubectl get pods -v 6
# Verbo: GET

# 2. Apply (crear nuevo)
kubectl apply -f pod.yaml -v 6
# Verbos: GET (verificar si existe) → POST (crear)

# 3. Delete
kubectl delete pod hello-world -v 6
# Verbos: DELETE → GET (verificar eliminación)
```

**Resumen**:
- **get**: GET
- **apply** (nuevo): GET + POST
- **delete**: DELETE + GET

</details>

---

### Ejercicio 2: Explorar con kubectl proxy
**Objetivo**: Usar la API directamente con curl

**Tarea**: 
1. Inicia kubectl proxy
2. Lista todos los namespaces usando curl
3. Obtén detalles del namespace `default`

<details>
<summary>💡 Pista</summary>
La ruta para namespaces es `/api/v1/namespaces`
</details>

<details>
<summary>✅ Solución</summary>

```bash
# 1. Iniciar proxy
kubectl proxy &

# 2. Listar namespaces
curl http://localhost:8001/api/v1/namespaces

# 3. Detalles del namespace default
curl http://localhost:8001/api/v1/namespaces/default

# Detener proxy
fg
# Ctrl+C
```

</details>

---

### Ejercicio 3: Interpretar Códigos de Respuesta
**Objetivo**: Entender qué significan diferentes códigos HTTP

**Tarea**: Predice qué código de respuesta obtendrás en cada escenario:
1. GET de un Pod que existe
2. GET de un Pod que no existe
3. POST para crear un Deployment nuevo
4. POST para crear un Deployment que ya existe

<details>
<summary>✅ Solución</summary>

1. **GET de Pod existente**: `200 OK`
2. **GET de Pod inexistente**: `404 Not Found`
3. **POST de Deployment nuevo**: `201 Created`
4. **POST de Deployment existente**: `409 Conflict` (o kubectl hace PATCH en su lugar)

**Verifica**:
```bash
# 1. Pod existente
kubectl apply -f pod.yaml
kubectl get pod hello-world -v 6
# Output: 200 OK

# 2. Pod inexistente
kubectl get pod nonexistent-pod -v 6
# Output: 404 Not Found

# 3. Deployment nuevo
kubectl create deployment test --image=nginx -v 6
# Output: 201 Created

# 4. Deployment existente (kubectl usa apply/patch)
kubectl apply -f deployment.yaml -v 6
# Primera vez: 201 Created
# Segunda vez: 200 OK (PATCH)
```

</details>

---

## 🔗 Recursos Adicionales

- [Kubernetes API Concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/)
- [API Server Overview](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [kubectl Proxy Documentation](https://kubernetes.io/docs/tasks/extend-kubernetes/http-proxy-access-api/)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- Guía anterior: [2. Versiones de Objetos API](./2-APIObjectVersions.md)
- Siguiente módulo: [Namespaces, Labels y Annotations](../../namespaces%20tags%20annotations/03/demos/README.md)

## 📚 Glosario

- **API Server**: Componente que expone la API REST de Kubernetes
- **Verbo HTTP**: Método de request (GET, POST, PUT, DELETE, PATCH)
- **Request Header**: Metadatos enviados con el request (autenticación, content-type)
- **Response Code**: Código numérico que indica el resultado (200, 404, 403)
- **kubectl proxy**: Proxy local que autentica requests a la API
- **Watch**: Conexión persistente que recibe actualizaciones en streaming
- **Verbosity**: Nivel de detalle en logs de kubectl (-v flag)

---

## ⚠️ Troubleshooting

### Problema 1: "connection refused" al acceder al API Server
**Causa**: El API Server no está accesible o el cluster está apagado

**Solución**:
```bash
# Verificar conectividad
kubectl cluster-info

# Verificar que el contexto es correcto
kubectl config current-context

# Verificar que el cluster está corriendo
kubectl get nodes
```

---

### Problema 2: "403 Forbidden" en todos los requests
**Causa**: Problema de autenticación o autorización

**Solución**:
```bash
# Verificar credenciales en kubeconfig
kubectl config view

# Verificar permisos del usuario
kubectl auth can-i get pods

# Verificar que el certificado no expiró
kubectl config view --raw
```

---

### Problema 3: kubectl proxy no responde
**Causa**: Puerto ya en uso o proxy no inició correctamente

**Solución**:
```bash
# Verificar si el proxy está corriendo
ps aux | grep "kubectl proxy"

# Usar un puerto diferente
kubectl proxy --port=8002 &

# Verificar que el puerto está escuchando
netstat -an | grep 8002
```

---

### Problema 4: Watch se desconecta constantemente
**Causa**: Timeout de red o problemas de conectividad

**Solución**:
```bash
# Usar timeout más largo
kubectl get pods --watch --request-timeout=5m

# Verificar conectividad de red
ping <api-server-ip>

# Revisar logs del API Server para errores
kubectl logs -n kube-system <api-server-pod>
```
