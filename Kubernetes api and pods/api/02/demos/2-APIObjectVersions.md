# 2. Versiones de Objetos API

## 📖 Introducción

Kubernetes utiliza un sistema de versionado de API para evolucionar sus recursos de manera controlada. Comprender cómo funcionan las versiones de API es crucial para mantener la compatibilidad y migrar recursos cuando las versiones antiguas se deprecan.

## 🎯 Objetivos

Al completar esta guía, serás capaz de:
- [ ] Entender el esquema de versionado de Kubernetes (v1, v1beta1, v2alpha1)
- [ ] Listar las versiones de API disponibles en tu cluster
- [ ] Filtrar recursos por API Group
- [ ] Usar versiones específicas de API con kubectl explain
- [ ] Prepararte para migraciones de API

## 📚 Conceptos Clave

### API Groups

Los **API Groups** organizan recursos relacionados. Ejemplos:
- **core** (v1): Pods, Services, ConfigMaps
- **apps**: Deployments, StatefulSets, DaemonSets
- **batch**: Jobs, CronJobs
- **networking.k8s.io**: Ingress, NetworkPolicy

### Niveles de Estabilidad

Kubernetes usa tres niveles de estabilidad para versiones de API:

| Nivel | Formato | Estabilidad | Uso Recomendado |
|-------|---------|-------------|-----------------|
| **Alpha** | `v1alpha1` | Experimental, puede cambiar o eliminarse | Solo desarrollo/testing |
| **Beta** | `v1beta1` | Más estable, pero puede cambiar | Pre-producción |
| **Stable** | `v1`, `v2` | Producción, retrocompatible | Producción |

### Formato de Versión

Las versiones se expresan como `<group>/<version>`:
- `v1` → Core API (sin grupo)
- `apps/v1` → Grupo apps, versión 1
- `batch/v1` → Grupo batch, versión 1
- `networking.k8s.io/v1` → Grupo networking, versión 1

### Deprecation Policy

Kubernetes sigue una política de deprecación:
- **GA (v1)**: Soportado por al menos 12 meses o 3 releases
- **Beta**: Soportado por al menos 9 meses o 3 releases
- **Alpha**: Puede eliminarse en cualquier momento

## 💻 Comandos Principales

### Comando 1: `kubectl api-resources`

**Propósito**: Ver todos los recursos y sus versiones de API.

**Sintaxis**:
```bash
kubectl api-resources [opciones]
```

**Ejemplo**:
```bash
# Listar todos los recursos con sus versiones
kubectl api-resources | more

# Filtrar por API Group específico
kubectl api-resources --api-group=apps

# Ver recursos del core API
kubectl api-resources --api-group=""

# Otros API Groups comunes
kubectl api-resources --api-group=batch
kubectl api-resources --api-group=networking.k8s.io
kubectl api-resources --api-group=storage.k8s.io
```

**Output Esperado** (para apps):
```
NAME                  SHORTNAMES   APIVERSION   NAMESPACED   KIND
controllerrevisions                apps/v1      true         ControllerRevision
daemonsets            ds           apps/v1      true         DaemonSet
deployments           deploy       apps/v1      true         Deployment
replicasets           rs           apps/v1      true         ReplicaSet
statefulsets          sts          apps/v1      true         StatefulSet
```

**Explicación**: Muestra que todos los recursos del grupo `apps` están en la versión estable `v1`.

---

### Comando 2: `kubectl api-versions`

**Propósito**: Listar todas las versiones de API soportadas por el cluster.

**Sintaxis**:
```bash
kubectl api-versions
```

**Ejemplo**:
```bash
# Listar todas las versiones disponibles
kubectl api-versions | sort | more
```

**Output Esperado**:
```
admissionregistration.k8s.io/v1
apiextensions.k8s.io/v1
apps/v1
authentication.k8s.io/v1
authorization.k8s.io/v1
autoscaling/v1
autoscaling/v2
batch/v1
certificates.k8s.io/v1
coordination.k8s.io/v1
discovery.k8s.io/v1
events.k8s.io/v1
networking.k8s.io/v1
node.k8s.io/v1
policy/v1
rbac.authorization.k8s.io/v1
scheduling.k8s.io/v1
storage.k8s.io/v1
v1
```

**Explicación**: 
- `v1` es el core API
- Otros tienen formato `<group>/<version>`
- La mayoría están en versión estable (v1 o v2)

---

### Comando 3: `kubectl explain --api-version`

**Propósito**: Ver la documentación de un recurso en una versión específica de API.

**Sintaxis**:
```bash
kubectl explain <recurso> --api-version <group/version>
```

**Ejemplos**:
```bash
# Ver Deployment en apps/v1 (versión actual)
kubectl explain deployment --api-version apps/v1 | more

# Ver campos específicos
kubectl explain deployment.spec --api-version apps/v1

# Comparar con versiones anteriores (si están disponibles)
kubectl explain deployment --api-version apps/v1beta1 | more
```

**Output Esperado**:
```
KIND:     Deployment
VERSION:  apps/v1

GROUP:    apps
DESCRIPTION:
     Deployment enables declarative updates for Pods and ReplicaSets.

FIELDS:
   apiVersion   <string>
     APIVersion defines the versioned schema of this representation...
     
   kind <string>
     Kind is a string value representing the REST resource...
```

**Explicación**: 
- **KIND**: Tipo de recurso
- **VERSION**: Versión específica de la API
- **GROUP**: API Group al que pertenece

---

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Explorar API Groups

**Escenario**: Quieres ver qué recursos están disponibles en diferentes API Groups.

**Pasos**:

1. **Ver todos los recursos disponibles**
   ```bash
   kubectl api-resources | more
   ```

2. **Filtrar recursos del grupo 'apps'**
   ```bash
   kubectl api-resources --api-group=apps
   ```
   
   **Output**:
   ```
   NAME                  SHORTNAMES   APIVERSION   NAMESPACED   KIND
   daemonsets            ds           apps/v1      true         DaemonSet
   deployments           deploy       apps/v1      true         Deployment
   replicasets           rs           apps/v1      true         ReplicaSet
   statefulsets          sts          apps/v1      true         StatefulSet
   ```

3. **Filtrar recursos del grupo 'batch'**
   ```bash
   kubectl api-resources --api-group=batch
   ```
   
   **Output**:
   ```
   NAME       SHORTNAMES   APIVERSION   NAMESPACED   KIND
   cronjobs   cj           batch/v1     true         CronJob
   jobs                    batch/v1     true         Job
   ```

4. **Ver recursos del core API (sin grupo)**
   ```bash
   kubectl api-resources --api-group="" | head -20
   ```

**Resultado**: Entiendes cómo están organizados los recursos en grupos lógicos.

---

### Ejemplo 2: Verificar Versiones de API Disponibles

**Escenario**: Quieres saber qué versiones de API soporta tu cluster.

**Pasos**:

1. **Listar todas las versiones**
   ```bash
   kubectl api-versions | sort
   ```

2. **Buscar versiones específicas**
   ```bash
   # Ver si hay versiones beta
   kubectl api-versions | grep beta
   
   # Ver versiones de autoscaling
   kubectl api-versions | grep autoscaling
   ```
   
   **Output**:
   ```
   autoscaling/v1
   autoscaling/v2
   ```

3. **Verificar versión de un recurso específico**
   ```bash
   kubectl api-resources | grep deployments
   ```
   
   **Output**:
   ```
   deployments   deploy   apps/v1   true   Deployment
   ```

**Resultado**: Sabes qué versiones usar en tus manifiestos YAML.

---

### Ejemplo 3: Migración de Versiones de API

**Escenario**: Deployments migraron de `apps/v1beta1` a `apps/v1`. Quieres entender las diferencias.

**Pasos**:

1. **Ver la versión actual (apps/v1)**
   ```bash
   kubectl explain deployment --api-version apps/v1 | more
   ```

2. **Verificar qué versiones están disponibles**
   ```bash
   kubectl api-versions | grep apps
   ```
   
   **Output**:
   ```
   apps/v1
   ```

3. **Ver un Deployment existente y su versión**
   ```bash
   kubectl get deployment hello-world -o yaml | grep apiVersion
   ```
   
   **Output**:
   ```
   apiVersion: apps/v1
   ```

4. **Actualizar manifiestos antiguos**
   ```yaml
   # Versión antigua (deprecada)
   apiVersion: apps/v1beta1
   kind: Deployment
   
   # Versión actual (usar esta)
   apiVersion: apps/v1
   kind: Deployment
   ```

**Resultado**: Tus manifiestos usan la versión estable y soportada.

---

### Ejemplo 4: Explorar Diferentes Versiones de Autoscaling

**Escenario**: Quieres usar HorizontalPodAutoscaler y necesitas saber qué versión usar.

**Pasos**:

1. **Ver versiones disponibles de autoscaling**
   ```bash
   kubectl api-versions | grep autoscaling
   ```
   
   **Output**:
   ```
   autoscaling/v1
   autoscaling/v2
   ```

2. **Ver recursos en cada versión**
   ```bash
   kubectl api-resources --api-group=autoscaling
   ```
   
   **Output**:
   ```
   NAME                       SHORTNAMES   APIVERSION        NAMESPACED   KIND
   horizontalpodautoscalers   hpa          autoscaling/v2    true         HorizontalPodAutoscaler
   ```

3. **Comparar capacidades entre versiones**
   ```bash
   # v1 - Solo soporta CPU
   kubectl explain hpa.spec --api-version autoscaling/v1
   
   # v2 - Soporta CPU, memoria y métricas custom
   kubectl explain hpa.spec --api-version autoscaling/v2
   ```

**Resultado**: Usas `autoscaling/v2` para capacidades avanzadas.

---

## 📝 Ejemplo de Manifiesto con Versión

### Deployment con apps/v1

```yaml
apiVersion: apps/v1    # Versión estable del API Group 'apps'
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 3
  selector:              # Requerido en apps/v1 (no en v1beta1)
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: nginx:1.21
```

**Cambios importantes de v1beta1 a v1**:
- `spec.selector` ahora es **requerido** (antes era opcional)
- Mejor validación de labels
- Más estable y con garantías de compatibilidad

---

## ✅ Cuándo Usar

- ✅ **Versiones estables (v1, v2)**: Siempre en producción
- ✅ **kubectl api-versions**: Para verificar compatibilidad antes de desplegar
- ✅ **kubectl api-resources --api-group**: Para descubrir recursos en un grupo específico
- ✅ **kubectl explain --api-version**: Para ver documentación de versiones específicas
- ✅ **Versiones beta**: Solo en ambientes de prueba para features nuevos

## ❌ Cuándo NO Usar

- ❌ **Versiones alpha en producción**: Son experimentales y pueden cambiar
- ❌ **Versiones deprecadas**: Migra a versiones estables antes de que se eliminen
- ❌ **Mezclar versiones**: Usa la misma versión consistentemente en todos los manifiestos
- ❌ **Ignorar warnings de deprecación**: Actualiza proactivamente

## 💡 Mejores Prácticas

1. **Usa siempre versiones estables en producción**: `v1`, `v2`, nunca `alpha` o `beta`
2. **Mantén tus manifiestos actualizados**: Migra de versiones deprecadas proactivamente
3. **Documenta la versión de Kubernetes requerida**: En tu README o comentarios
4. **Prueba migraciones en ambientes de desarrollo primero**: Antes de actualizar producción
5. **Suscríbete a release notes de Kubernetes**: Para estar al tanto de deprecaciones
6. **Usa herramientas de validación**: Como `kubeval` o `kube-score` para detectar versiones obsoletas

## 🧪 Ejercicios

### Ejercicio 1: Identificar Versiones de API
**Objetivo**: Familiarizarte con las versiones de API en tu cluster

**Tarea**: 
1. Lista todas las versiones de API disponibles
2. Identifica cuántas versiones tiene el grupo `autoscaling`
3. Encuentra qué versión usa el recurso `Ingress`

<details>
<summary>💡 Pista</summary>
Usa `kubectl api-versions` y `kubectl api-resources`
</details>

<details>
<summary>✅ Solución</summary>

```bash
# 1. Listar todas las versiones
kubectl api-versions | sort

# 2. Versiones de autoscaling
kubectl api-versions | grep autoscaling
# Output: autoscaling/v1, autoscaling/v2

# 3. Versión de Ingress
kubectl api-resources | grep ingress
# Output: ingresses   ing   networking.k8s.io/v1   true   Ingress
```

**Respuesta**: Ingress usa `networking.k8s.io/v1`

</details>

---

### Ejercicio 2: Explorar API Groups
**Objetivo**: Entender la organización de recursos en grupos

**Tarea**: Lista todos los recursos en el API Group `batch` y determina qué versión usan.

<details>
<summary>💡 Pista</summary>
Usa `kubectl api-resources` con el flag `--api-group`
</details>

<details>
<summary>✅ Solución</summary>

```bash
# Listar recursos del grupo batch
kubectl api-resources --api-group=batch

# Output:
# NAME       SHORTNAMES   APIVERSION   NAMESPACED   KIND
# cronjobs   cj           batch/v1     true         CronJob
# jobs                    batch/v1     true         Job
```

**Respuesta**: El grupo `batch` tiene 2 recursos (Jobs y CronJobs), ambos en versión `v1` (estable).

</details>

---

### Ejercicio 3: Comparar Versiones
**Objetivo**: Entender diferencias entre versiones de API

**Tarea**: Compara los campos disponibles en `autoscaling/v1` vs `autoscaling/v2` para HorizontalPodAutoscaler.

<details>
<summary>💡 Pista</summary>
Usa `kubectl explain hpa.spec` con diferentes `--api-version`
</details>

<details>
<summary>✅ Solución</summary>

```bash
# Ver campos en v1
kubectl explain hpa.spec --api-version autoscaling/v1

# Ver campos en v2
kubectl explain hpa.spec --api-version autoscaling/v2
```

**Diferencias clave**:
- **v1**: Solo soporta `targetCPUUtilizationPercentage`
- **v2**: Soporta múltiples métricas (`metrics`), incluyendo CPU, memoria, y custom metrics

**Conclusión**: Usa `autoscaling/v2` para mayor flexibilidad.

</details>

---

## 🔗 Recursos Adicionales

- [Kubernetes API Versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning)
- [Deprecation Policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/)
- [API Groups](https://kubernetes.io/docs/reference/using-api/#api-groups)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- Guía anterior: [1. Objetos de API y Descubrimiento](./1-APIObjects.md)
- Siguiente guía: [3. Anatomía de Requests API](./3-AnatomyApiRequest.md)

## 📚 Glosario

- **API Group**: Colección de recursos relacionados (apps, batch, networking)
- **API Version**: Nivel de estabilidad de un recurso (alpha, beta, stable)
- **Alpha**: Versión experimental, puede cambiar o eliminarse
- **Beta**: Versión pre-release, más estable que alpha
- **GA (General Availability)**: Versión estable para producción
- **Deprecation**: Proceso de marcar una versión como obsoleta antes de eliminarla
- **Core API**: API Group sin nombre explícito, usa solo `v1`

---

## ⚠️ Troubleshooting

### Problema 1: "no matches for kind 'Deployment' in version 'apps/v1beta1'"
**Causa**: La versión de API está deprecada y eliminada de tu cluster

**Solución**:
```bash
# Actualizar el manifiesto a la versión actual
# Cambiar:
apiVersion: apps/v1beta1

# Por:
apiVersion: apps/v1

# Verificar que apps/v1 está disponible
kubectl api-versions | grep apps
```

---

### Problema 2: No puedo encontrar un recurso específico
**Causa**: El recurso puede estar en un API Group diferente o no instalado

**Solución**:
```bash
# Buscar el recurso en todos los grupos
kubectl api-resources | grep -i <nombre-recurso>

# Verificar si el CRD está instalado (para recursos custom)
kubectl get crds
```

---

### Problema 3: ¿Qué versión debo usar en mi manifiesto?
**Causa**: Confusión sobre qué versión elegir

**Solución**:
```bash
# Ver la versión recomendada (la que aparece en APIVERSION)
kubectl api-resources | grep <tipo-recurso>

# Ejemplo para Deployment:
kubectl api-resources | grep deployments
# Output: deployments   deploy   apps/v1   true   Deployment

# Usar apps/v1 en tu manifiesto
```

**Regla general**: Usa la versión estable (v1, v2) que aparece en `kubectl api-resources`.
