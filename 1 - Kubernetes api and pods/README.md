# API, Namespaces, Labels y Pods

Comandos relacionados con la API de Kubernetes, namespaces, labels, pods y sus configuraciones.

## Indice

- [API y Cluster](#api-y-cluster)
- [dry-run](#dry-run)
- [diff](#diff)
- [proxy y verbosity](#proxy-y-verbosity)
- [Namespaces](#namespaces)
- [Labels y Selectors](#labels-y-selectors)
- [Pods](#pods)
- [Static Pods](#static-pods)
- [Multi-container Pods](#multi-container-pods)
- [Init Containers](#init-containers)
- [Pod Lifecycle](#pod-lifecycle)
- [Probes](#probes)

---

## API y Cluster

Informacion del cluster, contextos y descubrimiento de la API.

Conceptos clave:
- El **API Server** es la unica forma de interactuar con el cluster. Es una arquitectura cliente/servidor RESTful sobre HTTP/HTTPS usando JSON
- El API Server es **stateless**: los cambios se persisten en **etcd**, no en el API Server
- Los objetos de la API se organizan por **Kind** (Pod, Deployment, Service), **API Group** (core, apps, storage) y **API Version** (v1, v1beta1)
- Un request pasa por: Connection -> Authentication -> Authorization -> Admission Control -> Persist to etcd

```bash
# Ver contextos configurados
kubectl config get-contexts

# Cambiar de contexto
kubectl config use-context kubernetes-admin@kubernetes

# Informacion del cluster
kubectl cluster-info

# Listar recursos disponibles en la API
kubectl api-resources | more

# Recursos con namespace vs sin namespace
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false

# Recursos de un API Group especifico
kubectl api-resources --api-group=apps

# Versiones de API disponibles
kubectl api-versions | sort | more

# Explorar estructura de un recurso
kubectl explain pods | more
kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more
kubectl explain deployment --api-version apps/v1 | more
```

### dry-run

Conceptos clave:
- **server-side**: el request se procesa completo pero no se persiste en etcd. Detecta errores de validacion y conflictos
- **client-side**: valida solo la sintaxis del manifiesto sin enviarlo al API Server. Util para generar YAML

Validar manifiestos sin aplicarlos.

```bash
# Validacion server-side (pasa por todo el proceso pero no se guarda en etcd)
kubectl apply -f deployment.yaml --dry-run=server

# Validacion client-side
kubectl apply -f deployment.yaml --dry-run=client

# Generar YAML de un objeto sin crearlo
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml

# Generar YAML de un pod
kubectl run pod nginx-pod --image=nginx --dry-run=client -o yaml

# Guardar YAML generado a un archivo
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
```

### diff

Compara el estado actual de un recurso en el cluster contra lo definido en un manifiesto local.

```bash
# Comparar manifiesto local contra lo que esta en el cluster
kubectl diff -f deployment-new.yaml
```

### proxy y verbosity

Conceptos clave:
- `kubectl proxy` crea una conexion autenticada al API Server en localhost, permitiendo usar `curl` u otros clientes HTTP
- Los niveles de verbosity (-v 6 a -v 9) muestran progresivamente mas detalle de la comunicacion HTTP con el API Server

```bash
# Iniciar proxy al API Server
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world

# Verbosity levels (6-9)
kubectl get pod hello-world -v 6   # URL y response code
kubectl get pod hello-world -v 7   # + request headers
kubectl get pod hello-world -v 8   # + response headers
kubectl get pod hello-world -v 9   # + response body completo
```

Ejemplo YAML: [pod.yaml](./api/02/demos/pod.yaml), [deployment.yaml](./api/02/demos/deployment.yaml)

---

## Namespaces

Conceptos clave:
- Un namespace es una **subdivision logica** del cluster que provee aislamiento de recursos, seguridad (RBAC) y naming
- Un recurso solo puede estar en **un namespace** a la vez
- Los namespaces por defecto son: `default`, `kube-system` (pods del sistema), `kube-public` (recursos compartidos)
- Recursos como Pods, Deployments y Services **son namespaced**. Recursos como Nodes y PersistentVolumes **no lo son**
- Eliminar un namespace **elimina todos sus recursos**

```bash
# Listar namespaces
kubectl get namespaces

# Describir todos los namespaces
kubectl describe namespaces

# Describir un namespace especifico
kubectl describe namespaces kube-system

# Pods en todos los namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Todos los recursos en todos los namespaces
kubectl get all --all-namespaces

# Recursos en un namespace especifico
kubectl get pods --namespace kube-system
kubectl get pods -n kube-system
kubectl get all --namespace=playground1

# Crear namespace imperativamente
kubectl create namespace playground1

# Crear namespace declarativamente
kubectl apply -f namespace.yaml

# Crear pod en un namespace especifico
kubectl run hello-world-pod --image=hello-app:1.0 --namespace playground1

# Eliminar todos los pods en un namespace
kubectl delete pods --all --namespace playground1

# Eliminar un namespace (y todos sus recursos)
kubectl delete namespaces playground1
```

Ejemplo YAML: [namespace.yaml](./namespaces%20tags%20annotations/03/demos/namespace.yaml), [deployment.yaml](./namespaces%20tags%20annotations/03/demos/deployment.yaml)

---

## Labels y Selectors

Conceptos clave:
- Un label es un **par key/value** no jerarquico asociado a cualquier recurso (keys <= 63 chars, values <= 253 chars)
- Un recurso puede tener **multiples labels**
- Los **selectors** permiten filtrar y operar sobre colecciones de recursos
- Kubernetes usa labels internamente para: asociar Pods a ReplicaSets, registrar endpoints en Services, y programar Pods en Nodes
- Cambiar el label de un Pod lo **desasocia** de su ReplicaSet/Service (util para debugging en produccion)

```bash
# Ver labels de todos los pods
kubectl get pods --show-labels

# Ver labels de un pod especifico
kubectl describe pod nginx-pod-1 | head

# Filtrar por selector
kubectl get pods --selector tier=prod
kubectl get pods -l tier=prod
kubectl get pods -l tier=prod --show-labels

# Multiples selectores
kubectl get pods -l 'tier=prod,app=MyWebApp' --show-labels
kubectl get pods -l 'tier=prod,app!=MyWebApp' --show-labels
kubectl get pods -l 'tier in (prod,qa)'
kubectl get pods -l 'tier notin (prod,qa)'

# Mostrar label como columna
kubectl get pods -L tier
kubectl get pods -L tier,app

# Editar label existente
kubectl label pod nginx-pod-1 tier=non-prod --overwrite

# Agregar label
kubectl label pod nginx-pod-1 another=Label

# Eliminar label
kubectl label pod nginx-pod-1 another-

# Aplicar label a todos los pods
kubectl label pod --all tier=non-prod --overwrite

# Eliminar pods por label
kubectl delete pod -l tier=non-prod

# Labels en nodos (para scheduling)
kubectl get nodes --show-labels
kubectl label node c1-node2 disk=local_ssd
kubectl get node -L disk,hardware
kubectl label node c1-node2 disk-   # eliminar label
```

### Labels en Deployments y Services

```bash
# Ver selector del deployment
kubectl describe deployment hello-world

# Ver labels y selector del replicaset
kubectl describe replicaset hello-world

# Aislar un pod del replicaset (cambiando su label)
kubectl label pod <POD_NAME> pod-template-hash=DEBUG --overwrite

# Ver endpoints del servicio (pods balanceados)
kubectl describe endpoints hello-world
kubectl get pod -o wide

# Remover pod del balanceo (cambiar label del selector del servicio)
kubectl label pod <POD_NAME> app=DEBUG --overwrite
```

Ejemplo YAML: [CreatePodsWithLabels.yaml](./namespaces%20tags%20annotations/03/demos/CreatePodsWithLabels.yaml), [PodsToNodes.yaml](./namespaces%20tags%20annotations/03/demos/PodsToNodes.yaml), [deployment-label.yaml](./namespaces%20tags%20annotations/03/demos/deployment-label.yaml), [service.yaml](./namespaces%20tags%20annotations/03/demos/service.yaml)

---

## Pods

Conceptos clave:
- El Pod es la **unidad minima de scheduling y deployment** en Kubernetes
- Un Pod encapsula: contenedor(es), almacenamiento, red y configuracion
- Generalmente se ejecuta **un proceso por contenedor, un contenedor por Pod**
- No se recomienda ejecutar Pods "desnudos" (sin controller). Si el nodo falla, el Pod no se recrea
- `kubectl port-forward` permite acceso directo al Pod sin necesidad de un Service

```bash
# Crear pod desde YAML
kubectl apply -f pod.yaml

# Listar pods
kubectl get pods
kubectl get pods -o wide

# Describir pod
kubectl describe pod hello-world-pod

# Ejecutar comando dentro de un contenedor
kubectl exec -it hello-world-pod -- /bin/sh

# Logs de un pod
kubectl logs hello-world

# Watch de eventos
kubectl get events --watch &

# Watch de pods
kubectl get pods --watch

# Port-forward (acceso directo al pod sin service)
kubectl port-forward hello-world-pod 8080:8080 &
curl http://localhost:8080

# Eliminar pod
kubectl delete pod hello-world
kubectl delete -f pod.yaml

# Eliminar con el manifiesto (todos los recursos del archivo)
kubectl delete -f deployment.yaml
```

### Static Pods

Conceptos clave:
- Los Static Pods son gestionados directamente por el **kubelet** de un nodo, no por el API Server
- Se definen colocando manifiestos YAML en el `staticPodPath` del nodo (tipicamente `/etc/kubernetes/manifests/`)
- No se pueden eliminar con `kubectl delete`; hay que remover el manifiesto del nodo
- Los componentes del control plane (etcd, kube-apiserver, etc.) se ejecutan como Static Pods

```bash
# Generar manifiesto para static pod
kubectl run hello-world --image=hello-app:2.0 --dry-run=client -o yaml --port=8080

# Ver staticPodPath en el nodo
sudo cat /var/lib/kubelet/config.yaml

# Crear static pod (copiar manifiesto al directorio de manifiestos)
sudo vi /etc/kubernetes/manifests/mypod.yaml

# Eliminar static pod (remover manifiesto del nodo)
sudo rm /etc/kubernetes/manifests/mypod.yaml
```

Ejemplo YAML: [pod.yaml](./pods/04/demos/pod.yaml), [deployment.yaml](./pods/04/demos/deployment.yaml)

---

## Multi-container Pods

Conceptos clave:
- Multiples contenedores en un Pod comparten la **misma red (localhost)** y pueden compartir **volumenes**
- Patron comun: **producer/consumer** donde un contenedor escribe datos y otro los consume
- Si no se especifica `--container`, `kubectl exec` accede al **primer contenedor** del Pod

```bash
# Crear multi-container pod
kubectl apply -f multicontainer-pod.yaml

# Acceder al primer contenedor (default)
kubectl exec -it multicontainer-pod -- /bin/sh

# Acceder a un contenedor especifico
kubectl exec -it multicontainer-pod --container consumer -- /bin/sh

# Port-forward a multi-container pod
kubectl port-forward multicontainer-pod 8080:80 &
```

Ejemplo YAML: [multicontainer-pod.yaml](./pods/04/demos/multicontainer-pod.yaml)

---

## Init Containers

Conceptos clave:
- Se ejecutan **en serie** y deben completarse exitosamente antes de que inicie el contenedor principal
- Utiles para: descargar dependencias, esperar a que un servicio este disponible, configurar permisos
- Si un init container falla, Kubernetes reinicia el Pod segun la restart policy

```bash
# Crear pod con init containers
kubectl apply -f init-containers.yaml

# Ver estado de init containers
kubectl describe pods init-containers | more

# Watch de pods para ver el progreso
kubectl get pods --watch &
```

Ejemplo YAML: [init-containers.yaml](./pods/04/demos/init-containers.yaml)

---

## Pod Lifecycle

Conceptos clave:
- `Always` (default): reinicia el contenedor siempre. Usado en aplicaciones de larga duracion (web servers)
- `OnFailure`: reinicia solo si el contenedor termina con exit code != 0. Usado en Jobs
- `Never`: no reinicia. Util para tareas que solo deben ejecutarse una vez
- Al reiniciar, Kubernetes aplica **exponential backoff** (10s, 20s, 40s... hasta 5min)
- El campo `Restart Count` en `kubectl get pods` muestra cuantas veces se ha reiniciado el contenedor

```bash
# Ver restart policy de un pod
kubectl explain pods.spec.restartPolicy

# Crear pods con restart policy
kubectl apply -f pod-restart-policy.yaml

# Matar proceso dentro del contenedor
kubectl exec -it hello-world-pod -- /usr/bin/killall hello-app

# Ver restart count
kubectl get pods

# Ver estado del contenedor (State, Last State, Reason, Exit Code)
kubectl describe pod hello-world-pod
```

Ejemplo YAML: [pod-restart-policy.yaml](./pods/04/demos/pod-restart-policy.yaml)

---

## Probes

Conceptos clave:
- **livenessProbe**: verifica si el contenedor esta vivo. Si falla, Kubernetes **reinicia** el contenedor
- **readinessProbe**: verifica si el contenedor esta listo para recibir trafico. Si falla, se **remueve de los endpoints** del Service
- **startupProbe**: se ejecuta **antes** que liveness y readiness. Util para aplicaciones con inicio lento
- Parametros importantes: `initialDelaySeconds`, `periodSeconds`, `failureThreshold`
- Si el startup probe falla, liveness y readiness **no se ejecutan**

```bash
# Crear deployment con probes
kubectl apply -f container-probes.yaml

# Verificar configuracion de probes
kubectl describe pods

# Ver eventos de fallo de probes
kubectl get events --watch &

# Crear deployment con startup probe
kubectl apply -f container-probes-startup.yaml
```

Ejemplo YAML: [container-probes.yaml](./pods/04/demos/container-probes.yaml), [container-probes-startup.yaml](./pods/04/demos/container-probes-startup.yaml)
