# 1. Namespaces

## 📖 Introducción

Los **namespaces** son una forma de dividir recursos de un cluster entre múltiples usuarios, equipos o aplicaciones. Proporcionan un scope para nombres de recursos y son fundamentales para organizar y aislar workloads.

## 🎯 Objetivos

Al completar esta guía, serás capaz de:
- [ ] Crear y gestionar namespaces
- [ ] Entender la diferencia entre recursos namespaced y cluster-scoped
- [ ] Trabajar con recursos en diferentes namespaces
- [ ] Implementar estrategias de organización multi-tenant

## 📚 Conceptos Clave

### ¿Qué es un Namespace?

Un **namespace** es una partición virtual dentro de un cluster de Kubernetes que permite:
- Aislar recursos entre equipos/proyectos
- Aplicar políticas de seguridad y quotas
- Organizar recursos lógicamente
- Evitar conflictos de nombres

### Namespaces del Sistema

Kubernetes crea namespaces por defecto:

| Namespace | Propósito |
|-----------|-----------|
| `default` | Namespace por defecto para recursos sin namespace especificado |
| `kube-system` | Recursos del sistema de Kubernetes |
| `kube-public` | Recursos públicos, legibles por todos |
| `kube-node-lease` | Objetos de lease para heartbeats de nodos |

### Recursos Namespaced vs Cluster-Scoped

**Namespaced** (pertenecen a un namespace):
- Pods, Services, Deployments
- ConfigMaps, Secrets
- ReplicaSets, StatefulSets

**Cluster-scoped** (globales al cluster):
- Nodes
- Namespaces
- PersistentVolumes
- ClusterRoles

### Estados de Namespace

- **Active**: Namespace funcional
- **Terminating**: Namespace en proceso de eliminación

## 💻 Comandos Principales

### Comando 1: `kubectl get namespaces`

**Propósito**: Listar todos los namespaces en el cluster.

**Sintaxis**:
```bash
kubectl get namespaces
# O forma corta
kubectl get ns
```

**Output Esperado**:
```
NAME              STATUS   AGE
default           Active   10d
kube-node-lease   Active   10d
kube-public       Active   10d
kube-system       Active   10d
```

---

### Comando 2: `kubectl create namespace`

**Propósito**: Crear un namespace imperativamente.

**Sintaxis**:
```bash
kubectl create namespace <nombre>
```

**Ejemplos**:
```bash
# Crear namespace
kubectl create namespace playground1

# Intentar crear con mayúsculas (error)
kubectl create namespace Playground1
# Error: debe ser lowercase y solo guiones
```

**Restricciones de nombres**:
- Solo minúsculas
- Solo guiones (no underscores)
- No espacios

---

### Comando 3: `kubectl apply -f namespace.yaml`

**Propósito**: Crear namespace declarativamente.

**Ejemplo de manifiesto** ([namespace.yaml](./namespace.yaml)):
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: playgroundinyaml
```

**Comando**:
```bash
kubectl apply -f namespace.yaml
```

---

### Comando 4: `kubectl get pods --namespace`

**Propósito**: Listar recursos en un namespace específico.

**Sintaxis**:
```bash
kubectl get <recurso> --namespace <nombre>
# O forma corta
kubectl get <recurso> -n <nombre>
```

**Ejemplos**:
```bash
# Pods en kube-system
kubectl get pods --namespace kube-system
kubectl get pods -n kube-system

# Todos los recursos en un namespace
kubectl get all -n kube-system

# Pods en todos los namespaces
kubectl get pods --all-namespaces
kubectl get pods -A
```

---

### Comando 5: `kubectl describe namespace`

**Propósito**: Ver detalles de un namespace.

**Sintaxis**:
```bash
kubectl describe namespace <nombre>
```

**Output Esperado**:
```
Name:         default
Labels:       kubernetes.io/metadata.name=default
Annotations:  <none>
Status:       Active

No resource quota.
No LimitRange resource.
```

---

### Comando 6: `kubectl delete namespace`

**Propósito**: Eliminar un namespace y TODOS sus recursos.

**Sintaxis**:
```bash
kubectl delete namespace <nombre>
```

**⚠️ ADVERTENCIA**: Esto elimina TODOS los recursos dentro del namespace.

**Ejemplo**:
```bash
# Eliminar namespace y todo su contenido
kubectl delete namespace playground1

# Verificar que se eliminó
kubectl get namespaces
```

---

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Crear y Explorar Namespaces

**Escenario**: Configurar namespaces para diferentes ambientes.

**Pasos**:

1. **Listar namespaces existentes**
   ```bash
   kubectl get namespaces
   ```

2. **Crear namespace imperativamente**
   ```bash
   kubectl create namespace playground1
   ```

3. **Crear namespace declarativamente**
   ```bash
   # Contenido de namespace.yaml
   cat > namespace.yaml <<EOF
   apiVersion: v1
   kind: Namespace
   metadata:
     name: playgroundinyaml
   EOF
   
   kubectl apply -f namespace.yaml
   ```

4. **Verificar creación**
   ```bash
   kubectl get namespaces
   ```

5. **Ver detalles**
   ```bash
   kubectl describe namespace playground1
   ```

---

### Ejemplo 2: Trabajar con Recursos en Namespaces

**Escenario**: Desplegar aplicaciones en diferentes namespaces.

**Pasos**:

1. **Crear un Deployment en un namespace**
   ```bash
   # Usando manifiesto con namespace especificado
   kubectl apply -f deployment.yaml
   ```
   
   **deployment.yaml**:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-world
     namespace: playground1  # Especificar namespace
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
   ```

2. **Crear Pod imperativamente en un namespace**
   ```bash
   kubectl run hello-world-pod \
       --image=psk8s.azurecr.io/hello-app:1.0 \
       --namespace playground1
   ```

3. **Listar Pods (no aparecen en default)**
   ```bash
   # En namespace default (vacío)
   kubectl get pods
   
   # En namespace playground1
   kubectl get pods -n playground1
   ```

4. **Ver todos los recursos en el namespace**
   ```bash
   kubectl get all --namespace=playground1
   ```

---

### Ejemplo 3: Gestión de Recursos en Namespaces

**Escenario**: Limpiar recursos de un namespace.

**Pasos**:

1. **Intentar eliminar todos los Pods**
   ```bash
   kubectl delete pods --all --namespace playground1
   ```
   
   **Resultado**: El Pod standalone se elimina, pero el Deployment recrea sus Pods.

2. **Verificar Pods recreados**
   ```bash
   kubectl get pods -n playground1
   ```

3. **Eliminar el namespace completo**
   ```bash
   kubectl delete namespaces playground1
   kubectl delete namespaces playgroundinyaml
   ```

4. **Verificar eliminación**
   ```bash
   kubectl get all --all-namespaces
   ```

---

### Ejemplo 4: Recursos en Todos los Namespaces

**Escenario**: Ver recursos del sistema y usuario.

**Pasos**:

1. **Ver Pods del sistema**
   ```bash
   kubectl get pods --namespace kube-system
   ```

2. **Ver todos los Pods en el cluster**
   ```bash
   kubectl get pods --all-namespaces
   # O forma corta
   kubectl get pods -A
   ```

3. **Ver todos los recursos en todos los namespaces**
   ```bash
   kubectl get all --all-namespaces
   ```

4. **Filtrar por tipo de recurso**
   ```bash
   # Solo Deployments en todos los namespaces
   kubectl get deployments -A
   
   # Solo Services en todos los namespaces
   kubectl get services -A
   ```

---

## 📝 Manifiestos Relacionados

### [namespace.yaml](./namespace.yaml)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: playgroundinyaml
```

### [deployment.yaml](./deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: playground1  # Especificar namespace
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
```

---

## ✅ Cuándo Usar

- ✅ **Multi-tenancy**: Separar recursos entre equipos o clientes
- ✅ **Ambientes**: dev, staging, producción en el mismo cluster
- ✅ **Organización**: Agrupar recursos por proyecto o aplicación
- ✅ **Políticas**: Aplicar RBAC, Network Policies, Resource Quotas por namespace
- ✅ **Aislamiento lógico**: Prevenir conflictos de nombres

## ❌ Cuándo NO Usar

- ❌ **Aislamiento de seguridad fuerte**: Namespaces NO son un boundary de seguridad completo
- ❌ **Un namespace por microservicio**: Demasiada granularidad, difícil de gestionar
- ❌ **Separar versiones de la misma app**: Usa labels en su lugar
- ❌ **Clusters pequeños con un solo equipo**: Puede ser overhead innecesario

## 💡 Mejores Prácticas

1. **Usa convenciones de nombres**: `<equipo>-<ambiente>` (ej: `frontend-prod`)
2. **No uses el namespace default en producción**: Crea namespaces específicos
3. **Aplica Resource Quotas**: Previene que un namespace consuma todos los recursos
4. **Implementa Network Policies**: Para aislamiento de red entre namespaces
5. **Usa RBAC por namespace**: Controla quién puede acceder a qué
6. **Documenta el propósito**: Usa labels y annotations en el namespace

## 🧪 Ejercicios

### Ejercicio 1: Crear Estructura de Namespaces
**Objetivo**: Organizar un cluster para múltiples ambientes

**Tarea**: Crea namespaces para `development`, `staging`, y `production`.

<details>
<summary>✅ Solución</summary>

```bash
# Crear namespaces
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Verificar
kubectl get namespaces

# Agregar labels para organización
kubectl label namespace development env=dev
kubectl label namespace staging env=staging
kubectl label namespace production env=prod

# Ver labels
kubectl get namespaces --show-labels
```

</details>

---

### Ejercicio 2: Desplegar en Namespace Específico
**Objetivo**: Practicar deployment en namespaces

**Tarea**: Despliega un Pod nginx en el namespace `development`.

<details>
<summary>✅ Solución</summary>

```bash
# Método 1: Imperativo
kubectl run nginx --image=nginx --namespace development

# Método 2: Declarativo
cat > nginx-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: development
spec:
  containers:
  - name: nginx
    image: nginx
EOF

kubectl apply -f nginx-pod.yaml

# Verificar
kubectl get pods -n development
```

</details>

---

### Ejercicio 3: Investigar Recursos Namespaced
**Objetivo**: Identificar qué recursos son namespaced

**Tarea**: Lista todos los recursos namespaced y cluster-scoped.

<details>
<summary>✅ Solución</summary>

```bash
# Recursos namespaced
kubectl api-resources --namespaced=true

# Recursos cluster-scoped
kubectl api-resources --namespaced=false

# Verificar un recurso específico
kubectl api-resources | grep pods
# Output: pods  po  v1  true  Pod  (true = namespaced)
```

</details>

---

## 🔗 Recursos Adicionales

- [Namespaces Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- Siguiente guía: [2. Labels y Selectors](./2-labels.md)

## 📚 Glosario

- **Namespace**: Partición virtual de un cluster
- **Namespaced Resource**: Recurso que pertenece a un namespace
- **Cluster-scoped Resource**: Recurso global al cluster
- **Multi-tenancy**: Múltiples usuarios/equipos compartiendo un cluster
- **Resource Quota**: Límite de recursos por namespace
- **LimitRange**: Límites por defecto para contenedores en un namespace

---

## ⚠️ Troubleshooting

### Problema 1: "Error from server (AlreadyExists): namespaces 'X' already exists"
**Solución**: El namespace ya existe, usa `kubectl get ns` para verificar.

### Problema 2: No veo mis Pods con `kubectl get pods`
**Solución**: Probablemente están en otro namespace. Usa `-A` para ver todos.

### Problema 3: No puedo eliminar un namespace (queda en Terminating)
**Causa**: Recursos con finalizers o webhooks bloqueando

**Solución**:
```bash
# Ver recursos restantes
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>

# Forzar eliminación (último recurso)
kubectl delete namespace <nombre> --grace-period=0 --force
```
