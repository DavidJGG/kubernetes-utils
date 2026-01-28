# 2. Labels y Selectors

## 📖 Introducción

Los **labels** son pares clave-valor que se adjuntan a objetos de Kubernetes para identificarlos y organizarlos. Los **selectors** permiten filtrar y seleccionar objetos basándose en sus labels. Son fundamentales para cómo Deployments encuentran Pods, Services enrutan tráfico, y cómo organizas recursos.

## 🎯 Objetivos de Aprendizaje

Al completar esta guía, serás capaz de:
- [ ] Crear y gestionar labels en recursos
- [ ] Usar selectors para filtrar recursos
- [ ] Entender cómo Deployments y Services usan labels
- [ ] Implementar node selection con labels
- [ ] Organizar recursos con estrategias de labeling

## 📚 Conceptos Clave

### Labels

**Labels** son metadatos en forma de pares clave-valor:
```yaml
labels:
  app: nginx
  env: production
  tier: frontend
```

**Características**:
- Máximo 63 caracteres por clave/valor
- Pueden contener letras, números, guiones, puntos, underscores
- Usados para organización y selección

### Selectors

**Selectors** filtran objetos basándose en labels:

| Tipo | Sintaxis | Ejemplo |
|------|----------|---------|
| **Equality-based** | `key=value` | `app=nginx` |
| **Inequality** | `key!=value` | `env!=dev` |
| **Set-based** | `key in (v1,v2)` | `tier in (frontend,backend)` |
| **Not in** | `key notin (v1)` | `env notin (dev,test)` |

### Uso en Kubernetes

- **Deployments**: Usan selectors para encontrar sus Pods
- **Services**: Usan selectors para enrutar tráfico
- **ReplicaSets**: Usan selectors para gestionar réplicas
- **Node Selection**: Pods usan nodeSelector para elegir nodos

## 💻 Comandos Principales

### Comando 1: `kubectl get --show-labels`

**Propósito**: Ver labels de recursos.

**Sintaxis**:
```bash
kubectl get <recurso> --show-labels
```

**Ejemplos**:
```bash
# Ver labels de Pods
kubectl get pods --show-labels

# Ver labels de Nodes
kubectl get nodes --show-labels
```

---

### Comando 2: `kubectl get --selector`

**Propósito**: Filtrar recursos por labels.

**Sintaxis**:
```bash
kubectl get <recurso> --selector <label-query>
# O forma corta
kubectl get <recurso> -l <label-query>
```

**Ejemplos**:
```bash
# Pods con tier=prod
kubectl get pods --selector tier=prod
kubectl get pods -l tier=prod

# Múltiples labels (AND)
kubectl get pods -l 'tier=prod,app=MyWebApp'

# Inequality
kubectl get pods -l 'tier=prod,app!=MyWebApp'

# Set-based
kubectl get pods -l 'tier in (prod,qa)'
kubectl get pods -l 'tier notin (prod,qa)'
```

---

### Comando 3: `kubectl label`

**Propósito**: Agregar, modificar o eliminar labels.

**Sintaxis**:
```bash
# Agregar label
kubectl label <recurso> <nombre> <key>=<value>

# Modificar label existente
kubectl label <recurso> <nombre> <key>=<value> --overwrite

# Eliminar label
kubectl label <recurso> <nombre> <key>-
```

**Ejemplos**:
```bash
# Agregar label
kubectl label pod nginx-pod-1 another=Label

# Modificar label
kubectl label pod nginx-pod-1 tier=non-prod --overwrite

# Eliminar label
kubectl label pod nginx-pod-1 another-

# Aplicar a todos los pods
kubectl label pod --all tier=non-prod --overwrite
```

---

### Comando 4: `kubectl get -L`

**Propósito**: Mostrar labels específicos como columnas.

**Sintaxis**:
```bash
kubectl get <recurso> -L <label1>,<label2>
```

**Ejemplos**:
```bash
# Mostrar columna tier
kubectl get pods -L tier

# Múltiples columnas
kubectl get pods -L tier,app
```

**Output**:
```
NAME          READY   STATUS    TIER   APP
nginx-pod-1   1/1     Running   prod   MyWebApp
nginx-pod-2   1/1     Running   qa     MyWebApp
```

---

## 🔬 Ejemplos Prácticos

### Ejemplo 1: Crear Pods con Labels

**Pasos**:

1. **Aplicar manifiesto con labels** ([CreatePodsWithLabels.yaml](./CreatePodsWithLabels.yaml))
   ```bash
   kubectl apply -f CreatePodsWithLabels.yaml
   ```

2. **Ver todos los labels**
   ```bash
   kubectl get pods --show-labels
   ```

3. **Filtrar por tier**
   ```bash
   kubectl get pods -l tier=prod
   kubectl get pods -l tier=qa
   ```

4. **Filtrar por múltiples labels**
   ```bash
   kubectl get pods -l 'tier=prod,app=MyWebApp' --show-labels
   ```

---

### Ejemplo 2: Labels en Deployments y Services

**Escenario**: Entender cómo Deployments y Services usan labels.

**Pasos**:

1. **Crear Deployment**
   ```bash
   kubectl apply -f deployment-label.yaml
   ```

2. **Ver labels del Deployment**
   ```bash
   kubectl describe deployment hello-world
   ```
   
   **Observa**: `Selector: app=hello-world`

3. **Ver labels de ReplicaSet**
   ```bash
   kubectl describe replicaset hello-world
   ```
   
   **Observa**: Labels incluyen `app=hello-world` y `pod-template-hash`

4. **Ver labels de Pods**
   ```bash
   kubectl get pods --show-labels
   ```

5. **Crear Service**
   ```bash
   kubectl apply -f service.yaml
   ```

6. **Ver selector del Service**
   ```bash
   kubectl describe service hello-world
   ```
   
   **Observa**: `Selector: app=hello-world`

7. **Ver endpoints**
   ```bash
   kubectl describe endpoints hello-world
   ```

---

### Ejemplo 3: Manipular Labels en Pods

**Escenario**: Cambiar labels para sacar Pods del ReplicaSet.

**Pasos**:

1. **Cambiar pod-template-hash de un Pod**
   ```bash
   # Obtener nombre del Pod
   kubectl get pods
   
   # Cambiar label
   kubectl label pod <POD_NAME> pod-template-hash=DEBUG --overwrite
   ```

2. **Ver Pods**
   ```bash
   kubectl get pods --show-labels
   ```
   
   **Resultado**: ReplicaSet crea un nuevo Pod para mantener el count

3. **Cambiar label app para sacarlo del Service**
   ```bash
   kubectl label pod <POD_NAME> app=DEBUG --overwrite
   ```

4. **Ver endpoints**
   ```bash
   kubectl describe endpoints hello-world
   ```
   
   **Resultado**: El Pod ya no recibe tráfico

---

### Ejemplo 4: Node Selection con Labels

**Escenario**: Programar Pods en nodos específicos usando labels.

**Pasos**:

1. **Ver labels de nodos**
   ```bash
   kubectl get nodes --show-labels
   ```

2. **Agregar labels a nodos**
   ```bash
   kubectl label node c1-node2 disk=local_ssd
   kubectl label node c1-node3 hardware=local_gpu
   ```

3. **Verificar labels**
   ```bash
   kubectl get node -L disk,hardware
   ```

4. **Crear Pods con nodeSelector** ([PodsToNodes.yaml](./PodsToNodes.yaml))
   ```bash
   kubectl apply -f PodsToNodes.yaml
   ```

5. **Ver dónde se programaron**
   ```bash
   kubectl get pods -o wide
   ```
   
   **Resultado**: Pods se programan en nodos con labels coincidentes

6. **Limpiar**
   ```bash
   kubectl label node c1-node2 disk-
   kubectl label node c1-node3 hardware-
   kubectl delete -f PodsToNodes.yaml
   ```

---

## 📝 Manifiestos Relacionados

### Pod con Labels

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-1
  labels:
    app: MyWebApp
    deployment: v1
    tier: prod
spec:
  containers:
  - name: nginx
    image: nginx
```

### Pod con nodeSelector

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-ssd
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    disk: local_ssd  # Solo en nodos con este label
```

---

## ✅ Cuándo Usar

- ✅ **Organización**: Agrupar recursos por app, tier, env
- ✅ **Selección**: Deployments, Services, ReplicaSets
- ✅ **Filtrado**: Queries complejas con kubectl
- ✅ **Node selection**: Programar Pods en hardware específico
- ✅ **Bulk operations**: Aplicar cambios a grupos de recursos

## ❌ Cuándo NO Usar

- ❌ **Datos no identificadores**: Usa annotations en su lugar
- ❌ **Información sensible**: Labels son visibles para todos
- ❌ **Datos grandes**: Límite de 63 caracteres
- ❌ **Datos que cambian frecuentemente**: Causa churn en controllers

## 💡 Mejores Prácticas

1. **Usa convenciones consistentes**: `app`, `env`, `tier`, `version`
2. **Labels recomendados**:
   - `app.kubernetes.io/name`: Nombre de la aplicación
   - `app.kubernetes.io/instance`: Instancia única
   - `app.kubernetes.io/version`: Versión de la aplicación
   - `app.kubernetes.io/component`: Componente (database, cache)
   - `app.kubernetes.io/part-of`: Aplicación de nivel superior
3. **No uses labels para datos**: Usa annotations
4. **Documenta tu estrategia de labels**: En README o wiki
5. **Automatiza labeling**: En CI/CD pipelines

## 🧪 Ejercicios

### Ejercicio 1: Filtrado Avanzado
**Tarea**: Encuentra todos los Pods en producción que NO sean de MyWebApp.

<details>
<summary>✅ Solución</summary>

```bash
kubectl get pods -l 'tier=prod,app!=MyWebApp' --show-labels
```

</details>

### Ejercicio 2: Sacar Pod del Load Balancer
**Tarea**: Cambia el label de un Pod para que el Service deje de enviarle tráfico.

<details>
<summary>✅ Solución</summary>

```bash
# Ver selector del Service
kubectl describe service hello-world
# Selector: app=hello-world

# Cambiar label del Pod
kubectl label pod <POD_NAME> app=debug --overwrite

# Verificar endpoints
kubectl describe endpoints hello-world
# El Pod ya no aparece
```

</details>

---

## 🔗 Recursos Adicionales

- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
- Guía anterior: [1. Namespaces](./1-namespaces.md)
- Siguiente módulo: [Pods](../../pods/04/demos/README.md)

## 📚 Glosario

- **Label**: Par clave-valor para identificar objetos
- **Selector**: Query para filtrar objetos por labels
- **Equality-based selector**: `key=value` o `key!=value`
- **Set-based selector**: `key in (values)` o `key notin (values)`
- **nodeSelector**: Campo en Pod spec para seleccionar nodos
- **pod-template-hash**: Label automático agregado por Deployments

## ⚠️ Troubleshooting

### Problema: Service no enruta tráfico a Pods
**Solución**: Verifica que los labels del Pod coincidan con el selector del Service.

```bash
kubectl describe service <name>  # Ver Selector
kubectl get pods --show-labels   # Ver labels de Pods
```

### Problema: Deployment no gestiona Pods
**Solución**: Verifica que los labels en `template.metadata.labels` coincidan con `selector.matchLabels`.
