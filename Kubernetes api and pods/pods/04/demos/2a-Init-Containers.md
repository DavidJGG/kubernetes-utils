# 2a. Init Containers

## 📖 Introducción

Los **Init Containers** son contenedores especiales que se ejecutan antes de los contenedores de la aplicación, completándose exitosamente antes de que la app inicie.

## 🎯 Objetivos

- [ ] Entender el propósito de init containers
- [ ] Implementar setup y prerequisites
- [ ] Monitorear ejecución secuencial

## 📚 Conceptos Clave

### Características

- **Ejecución secuencial**: Se ejecutan uno tras otro, en orden
- **Deben completarse**: Cada uno debe terminar exitosamente antes del siguiente
- **Separación de concerns**: Setup separado de la lógica de la app

### Casos de Uso

1. **Esperar por dependencias**: Esperar que una base de datos esté lista
2. **Setup inicial**: Clonar repositorios, descargar configuraciones
3. **Seguridad**: Generar certificados, configurar permisos
4. **Migrations**: Ejecutar migraciones de base de datos

## 💻 Ejemplo Práctico

### Manifiesto ([init-containers.yaml](./init-containers.yaml))

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-containers
spec:
  initContainers:
  - name: init-service
    image: busybox
    command: ['sh', '-c', 'echo Waiting for service && sleep 5']
  - name: init-database
    image: busybox
    command: ['sh', '-c', 'echo Waiting for database && sleep 5']
  containers:
  - name: app
    image: nginx
```

### Pasos

1. **Watch en background**
   ```bash
   kubectl get pods --watch &
   ```

2. **Crear Pod**
   ```bash
   kubectl apply -f init-containers.yaml
   ```
   
   **Observa**:
   - `Init:0/2`: Ningún init container completado
   - `Init:1/2`: Primer init container completado
   - `Init:2/2`: Segundo init container completado
   - `Running`: App container iniciado

3. **Describir Pod**
   ```bash
   kubectl describe pods init-containers | more
   ```
   
   **Busca**:
   - Init Containers section
   - State: Terminated, Reason: Completed
   - Events: Cada init container iniciando secuencialmente

4. **Limpiar**
   ```bash
   kubectl delete -f init-containers.yaml
   fg
   # Ctrl+C
   ```

## ✅ Cuándo Usar

- ✅ **Esperar por servicios**: Antes de iniciar la app
- ✅ **Setup complejo**: Que no pertenece a la app
- ✅ **Seguridad**: Generar secrets, configurar permisos
- ✅ **Migrations**: Base de datos antes de la app

## ❌ Cuándo NO Usar

- ❌ **Lógica de la app**: Debe estar en el contenedor principal
- ❌ **Procesos continuos**: Init containers deben terminar

## 🔗 Recursos

- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- Siguiente: [3. Pod Lifecycle](./3-Pod-Lifecycle.md)
