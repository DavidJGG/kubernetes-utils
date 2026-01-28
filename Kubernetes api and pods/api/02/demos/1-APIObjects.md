# 1. Objetos de API y Descubrimiento

## 📖 Introducción

El API Server de Kubernetes es el componente central que expone la API de Kubernetes. Todos los comandos de `kubectl` y las operaciones del cluster interactúan con el API Server. Comprender cómo descubrir y explorar los recursos disponibles es fundamental para trabajar efectivamente con Kubernetes.

## 🎯 Objetivos de Aprendizaje

Al completar esta guía, serás capaz de:
- [ ] Descubrir qué recursos API están disponibles en tu cluster
- [ ] Explorar la estructura de recursos usando `kubectl explain`
- [ ] Validar manifiestos YAML antes de aplicarlos
- [ ] Generar manifiestos YAML automáticamente
- [ ] Comparar cambios en recursos con `kubectl diff`

## 📚 Conceptos Clave

### API Resources
Los **API Resources** son los tipos de objetos que puedes crear y gestionar en Kubernetes (Pods, Deployments, Services, etc.). Cada recurso tiene un nombre, un API Group, y si es namespaced o cluster-scoped.

### kubectl explain
`kubectl explain` es una herramienta de documentación integrada que muestra la estructura y campos de cualquier recurso de Kubernetes, similar a una página de manual.

### Dry Run
**Dry run** permite validar un manifiesto sin crear realmente el recurso. Existen dos modos:
- **client**: Validación local, solo verifica sintaxis
- **server**: Envía al API Server para validación completa (incluyendo admission controllers)

### Manifiestos YAML
Los **manifiestos YAML** son archivos declarativos que definen el estado deseado de los recursos de Kubernetes. Contienen campos como `apiVersion`, `kind`, `metadata`, y `spec`.

## 💻 Comandos Principales

### Comando 1: `kubectl config get-contexts`

**Propósito**: Verificar el contexto actual del cluster y listar todos los contextos disponibles.

**Sintaxis**:
```bash
kubectl config get-contexts
```

**Ejemplo**:
```bash
# Ver todos los contextos configurados
kubectl config get-contexts

# Cambiar a un contexto específico
kubectl config use-context kubernetes-admin@kubernetes
```

**Explicación**: Esto asegura que estás trabajando con el cluster correcto antes de ejecutar comandos.

---

### Comando 2: `kubectl cluster-info`

**Propósito**: Obtener información sobre el API Server y servicios del cluster.

**Sintaxis**:
```bash
kubectl cluster-info
```

**Output Esperado**:
```
Kubernetes control plane is running at https://172.16.94.10:6443
CoreDNS is running at https://172.16.94.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**Explicación**: Muestra las URLs de los componentes principales del cluster.

---

### Comando 3: `kubectl api-resources`

**Propósito**: Listar todos los tipos de recursos disponibles en el cluster.

**Sintaxis**:
```bash
kubectl api-resources [opciones]
```

**Ejemplo**:
```bash
# Listar todos los recursos
kubectl api-resources | more

# Ver solo recursos de un API Group específico
kubectl api-resources --api-group=apps

# Ver solo recursos namespaced
kubectl api-resources --namespaced=true

# Ver solo recursos cluster-scoped
kubectl api-resources --namespaced=false
```

**Output Esperado**:
```
NAME                SHORTNAMES   APIVERSION   NAMESPACED   KIND
pods                po           v1           true         Pod
services            svc          v1           true         Service
deployments         deploy       apps/v1      true         Deployment
```

**Explicación**: 
- **NAME**: Nombre del recurso (plural)
- **SHORTNAMES**: Alias cortos (ej: `po` para pods)
- **APIVERSION**: Versión de la API
- **NAMESPACED**: Si el recurso pertenece a un namespace
- **KIND**: Tipo del objeto en manifiestos YAML

---

### Comando 4: `kubectl explain`

**Propósito**: Mostrar la documentación y estructura de campos de un recurso.

**Sintaxis**:
```bash
kubectl explain <recurso>[.<campo>.<subcampo>]
```

**Ejemplos**:
```bash
# Ver la estructura completa de un Pod
kubectl explain pods | more

# Ver los campos requeridos en pod.spec
kubectl explain pod.spec | more

# Ver los campos de containers (image y name son requeridos)
kubectl explain pod.spec.containers | more

# Ver campos específicos
kubectl explain deployment.spec.replicas
```

**Output Esperado**:
```
KIND:     Pod
VERSION:  v1

DESCRIPTION:
     Pod is a collection of containers that can run on a host...

FIELDS:
   apiVersion   <string>
   kind         <string>
   metadata     <Object>
   spec         <Object>
```

**Explicación**: Esto es invaluable para escribir manifiestos YAML sin consultar constantemente la documentación web.

---

### Comando 5: `kubectl apply --dry-run`

**Propósito**: Validar manifiestos sin crear recursos reales.

**Sintaxis**:
```bash
kubectl apply -f <archivo.yaml> --dry-run=<client|server>
```

**Ejemplos**:
```bash
# Validación server-side (completa, incluye admission controllers)
kubectl apply -f deployment.yaml --dry-run=server

# Validación client-side (solo sintaxis)
kubectl apply -f deployment.yaml --dry-run=client

# Detectar errores en manifiestos
kubectl apply -f deployment-error.yaml --dry-run=client
```

**Explicación**:
- `--dry-run=server`: Envía al API Server, valida todo pero no persiste en etcd
- `--dry-run=client`: Validación local, más rápida pero menos completa

---

### Comando 6: `kubectl create --dry-run -o yaml`

**Propósito**: Generar manifiestos YAML automáticamente.

**Sintaxis**:
```bash
kubectl create <tipo> <nombre> [opciones] --dry-run=client -o yaml
```

**Ejemplos**:
```bash
# Generar YAML para un deployment
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml

# Generar YAML para un pod
kubectl run nginx-pod --image=nginx --dry-run=client -o yaml

# Guardar el YAML generado en un archivo
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment-generated.yaml
```

**Output Esperado**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
```

**Explicación**: Esto es útil como punto de partida para crear manifiestos complejos.

---

### Comando 7: `kubectl diff`

**Propósito**: Comparar el estado actual de un recurso con cambios propuestos.

**Sintaxis**:
```bash
kubectl diff -f <archivo.yaml>
```

**Ejemplo**:
```bash
# Crear un deployment con 4 replicas
kubectl apply -f deployment.yaml

# Ver diferencias con un deployment de 5 replicas
kubectl diff -f deployment-new.yaml | more
```

**Output Esperado**:
```diff
  spec:
-   replicas: 4
+   replicas: 5
    template:
      spec:
        containers:
-       - image: psk8s.azurecr.io/hello-app:1.0
+       - image: psk8s.azurecr.io/hello-app:2.0
```

**Explicación**: Similar a `git diff`, muestra qué cambiará antes de aplicar cambios.

---

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Descubrimiento de API

**Escenario**: Quieres saber qué recursos puedes crear en tu cluster.

**Pasos**:

1. **Verificar contexto del cluster**
   ```bash
   kubectl config get-contexts
   ```

2. **Obtener información del API Server**
   ```bash
   kubectl cluster-info
   ```

3. **Listar todos los recursos disponibles**
   ```bash
   kubectl api-resources | more
   ```

4. **Explorar la estructura de un Pod**
   ```bash
   kubectl explain pods
   kubectl explain pod.spec
   kubectl explain pod.spec.containers
   ```

**Resultado**: Ahora conoces todos los recursos disponibles y cómo están estructurados.

---

### Ejemplo 2: Crear un Pod desde YAML

**Escenario**: Quieres desplegar un Pod simple usando un manifiesto YAML.

**Pasos**:

1. **Revisar el manifiesto** ([pod.yaml](./pod.yaml))
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: hello-world
   spec:
     containers:
     - name: hello-world
       image: psk8s.azurecr.io/hello-app:1.0
   ```

2. **Aplicar el manifiesto**
   ```bash
   kubectl apply -f pod.yaml
   ```

3. **Verificar que el Pod está corriendo**
   ```bash
   kubectl get pods
   ```

4. **Eliminar el Pod**
   ```bash
   kubectl delete pod hello-world
   ```

**Resultado**: Pod creado y eliminado exitosamente.

---

### Ejemplo 3: Validación con Dry Run

**Escenario**: Quieres validar un Deployment antes de crearlo.

**Pasos**:

1. **Validación server-side**
   ```bash
   kubectl apply -f deployment.yaml --dry-run=server
   ```
   
   **Output**: `deployment.apps/hello-world created (server dry run)`

2. **Verificar que NO se creó**
   ```bash
   kubectl get deployments
   ```
   
   **Output**: `No resources found in default namespace.`

3. **Probar con un manifiesto con error**
   ```bash
   kubectl apply -f deployment-error.yaml --dry-run=client
   ```
   
   **Output**: `error: error validating "deployment-error.yaml": error validating data...`

**Resultado**: Detectaste errores sin afectar el cluster.

---

### Ejemplo 4: Generar YAML Automáticamente

**Escenario**: Necesitas crear un Deployment pero no recuerdas la sintaxis exacta.

**Pasos**:

1. **Generar YAML en pantalla**
   ```bash
   kubectl create deployment nginx --image=nginx --dry-run=client -o yaml | more
   ```

2. **Guardar en un archivo**
   ```bash
   kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment-generated.yaml
   ```

3. **Revisar el archivo generado**
   ```bash
   cat deployment-generated.yaml
   ```

4. **Desplegar desde el archivo generado**
   ```bash
   kubectl apply -f deployment-generated.yaml
   ```

5. **Limpiar**
   ```bash
   kubectl delete -f deployment-generated.yaml
   ```

**Resultado**: Creaste un manifiesto válido sin escribirlo manualmente.

---

### Ejemplo 5: Comparar Cambios con Diff

**Escenario**: Quieres ver qué cambiará antes de actualizar un Deployment.

**Pasos**:

1. **Crear un Deployment con 4 replicas**
   ```bash
   kubectl apply -f deployment.yaml
   ```

2. **Ver diferencias con un nuevo manifiesto (5 replicas, nueva imagen)**
   ```bash
   kubectl diff -f deployment-new.yaml | more
   ```

3. **Revisar los cambios mostrados**
   - Cambio en `replicas`: 4 → 5
   - Cambio en `image`: versión 1.0 → 2.0

4. **Aplicar los cambios si estás conforme**
   ```bash
   kubectl apply -f deployment-new.yaml
   ```

5. **Limpiar**
   ```bash
   kubectl delete -f deployment-new.yaml
   ```

**Resultado**: Viste exactamente qué cambiaría antes de aplicar.

---

## 📝 Manifiestos Relacionados

### [pod.yaml](./pod.yaml)

```yaml
apiVersion: v1          # Versión de la API (v1 para Pods)
kind: Pod               # Tipo de recurso
metadata:
  name: hello-world     # Nombre único del Pod
spec:
  containers:           # Lista de contenedores
  - name: hello-world   # Nombre del contenedor (requerido)
    image: psk8s.azurecr.io/hello-app:1.0  # Imagen del contenedor (requerido)
```

**Campos Clave**:
- `apiVersion`: Versión de la API de Kubernetes para este recurso
- `kind`: Tipo de objeto (Pod, Deployment, Service, etc.)
- `metadata.name`: Identificador único del recurso
- `spec.containers`: Definición de contenedores (mínimo 1 requerido)

---

### [deployment.yaml](./deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1           # Número de Pods deseados
  selector:
    matchLabels:
      app: hello-world  # Selector para identificar Pods
  template:             # Plantilla del Pod
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

**Campos Clave**:
- `spec.replicas`: Cuántas copias del Pod mantener
- `spec.selector`: Cómo el Deployment encuentra sus Pods
- `spec.template`: Especificación del Pod a crear

---

## ✅ Cuándo Usar

- ✅ **kubectl api-resources**: Cuando necesitas descubrir qué recursos están disponibles
- ✅ **kubectl explain**: Antes de escribir manifiestos YAML para entender la estructura
- ✅ **--dry-run=server**: Para validar manifiestos complejos antes de aplicarlos
- ✅ **--dry-run=client -o yaml**: Para generar plantillas de manifiestos rápidamente
- ✅ **kubectl diff**: Antes de actualizar recursos en producción para ver cambios

## ❌ Cuándo NO Usar

- ❌ **--dry-run=client**: No detecta todos los errores (usa server para validación completa)
- ❌ **kubectl create con -o yaml**: No uses esto en producción, solo para generar plantillas
- ❌ **kubectl explain**: No es un reemplazo de la documentación oficial para casos complejos
- ❌ **Generar YAML sin revisarlo**: Siempre revisa y ajusta el YAML generado antes de usarlo

## 💡 Mejores Prácticas

1. **Siempre usa dry-run antes de aplicar en producción**: Evita errores costosos
2. **Combina kubectl explain con la documentación web**: Para entendimiento completo
3. **Usa kubectl diff para cambios importantes**: Especialmente en recursos críticos
4. **Guarda los manifiestos generados en control de versiones**: Para trazabilidad
5. **Valida con --dry-run=server, no solo client**: Para validación completa
6. **Usa shortnames para comandos rápidos**: `po` en lugar de `pods`, `deploy` en lugar de `deployments`

## 🧪 Ejercicios

### Ejercicio 1: Explorar un Recurso Desconocido
**Objetivo**: Familiarizarte con el comando `kubectl explain`

**Tarea**: Usa `kubectl explain` para descubrir qué campos son requeridos para crear un Service.

<details>
<summary>💡 Pista</summary>
Comienza con `kubectl explain service` y luego explora `service.spec`
</details>

<details>
<summary>✅ Solución</summary>

```bash
# Ver estructura general
kubectl explain service

# Ver campos de spec
kubectl explain service.spec

# Ver tipos de Service
kubectl explain service.spec.type

# Ver campos de ports (requerido)
kubectl explain service.spec.ports
```

**Campos requeridos para un Service**:
- `spec.ports`: Lista de puertos a exponer
- `spec.selector`: Labels para seleccionar Pods

</details>

---

### Ejercicio 2: Generar y Validar un Deployment
**Objetivo**: Practicar generación y validación de manifiestos

**Tarea**: 
1. Genera un Deployment llamado `nginx-test` con la imagen `nginx:1.21`
2. Modifica el YAML para tener 3 replicas
3. Valida el manifiesto con dry-run server
4. Aplícalo al cluster

<details>
<summary>💡 Pista</summary>
Usa `kubectl create deployment` con `--dry-run=client -o yaml` y redirige a un archivo
</details>

<details>
<summary>✅ Solución</summary>

```bash
# 1. Generar el YAML
kubectl create deployment nginx-test --image=nginx:1.21 --dry-run=client -o yaml > nginx-deployment.yaml

# 2. Editar el archivo y cambiar replicas a 3
# Busca la línea "replicas: 1" y cámbiala a "replicas: 3"
vi nginx-deployment.yaml

# 3. Validar con dry-run server
kubectl apply -f nginx-deployment.yaml --dry-run=server

# 4. Aplicar al cluster
kubectl apply -f nginx-deployment.yaml

# Verificar
kubectl get deployments nginx-test
kubectl get pods -l app=nginx-test

# Limpiar
kubectl delete -f nginx-deployment.yaml
```

</details>

---

### Ejercicio 3: Detectar Errores con Dry Run
**Objetivo**: Usar dry-run para encontrar errores

**Tarea**: El archivo `deployment-error.yaml` tiene un error. Usa dry-run para encontrarlo sin aplicar el manifiesto.

<details>
<summary>💡 Pista</summary>
Usa `--dry-run=client` primero para validación rápida
</details>

<details>
<summary>✅ Solución</summary>

```bash
# Validar con dry-run client
kubectl apply -f deployment-error.yaml --dry-run=client

# Output esperado:
# error: error validating "deployment-error.yaml": error validating data: 
# ValidationError(Deployment.spec): unknown field "replica" in io.k8s.api.apps.v1.DeploymentSpec

# El error es que dice "replica" en lugar de "replicas"
```

**Corrección**: Cambiar `replica:` por `replicas:` en el manifiesto.

</details>

---

## 🔗 Recursos Adicionales

- [Documentación oficial de Kubernetes API](https://kubernetes.io/docs/reference/kubernetes-api/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [API Conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- Siguiente guía: [2. Versiones de Objetos API](./2-APIObjectVersions.md)

## 📚 Glosario

- **API Server**: Componente que expone la API de Kubernetes
- **API Resource**: Tipo de objeto que se puede crear en Kubernetes
- **API Group**: Agrupación lógica de recursos relacionados (apps, batch, etc.)
- **Dry Run**: Simulación de una operación sin ejecutarla realmente
- **Manifiesto**: Archivo YAML/JSON que describe el estado deseado de un recurso
- **etcd**: Base de datos distribuida donde Kubernetes almacena su estado

---

## ⚠️ Troubleshooting

### Problema 1: "error: You must be logged in to the server (Unauthorized)"
**Causa**: Tu kubeconfig no está configurado o las credenciales expiraron

**Solución**: 
```bash
# Verificar contexto actual
kubectl config current-context

# Ver configuración
kubectl config view

# Cambiar a un contexto válido
kubectl config use-context <nombre-contexto>
```

---

### Problema 2: "error: the server doesn't have a resource type 'X'"
**Causa**: El recurso no existe en tu versión de Kubernetes o escribiste mal el nombre

**Solución**:
```bash
# Listar todos los recursos disponibles
kubectl api-resources | grep <nombre-recurso>

# Verificar versión de Kubernetes
kubectl version --short
```

---

### Problema 3: Dry run dice "created" pero el recurso no existe
**Causa**: Esto es comportamiento esperado con `--dry-run=server`

**Solución**: Dry run simula la creación pero no persiste en etcd. Para crear realmente, quita el flag `--dry-run`.

```bash
# Esto NO crea el recurso
kubectl apply -f deployment.yaml --dry-run=server

# Esto SÍ crea el recurso
kubectl apply -f deployment.yaml
```
