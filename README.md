# Kubernetes Commands Reference

Referencia de comandos `kubectl` organizados por categoria, extraidos de demos y transcripciones del curso.

Cada seccion tiene su propio README con mas detalle:

- [Seccion 1 - API, Namespaces, Labels y Pods](./1%20-%20Kubernetes%20api%20and%20pods/README.md)
- [Seccion 2 - Controllers y Deployments](./2%20-%20managing-kubernetes-controllers-deployments/README.md)
- [Seccion 3 - Networking, Services e Ingress](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/README.md)
- [Seccion 4 - Storage y Scheduling](./4%20-%20config-managing-kubernetes-storage-and-scheduling/README.md)
- [Seccion 5 - Seguridad en Kubernetes (Defense in Depth)](./5%20-%20configuring-managing-kubernetes-security-2/README.md)

## Indice

| Categoria | Seccion |
|-----------|---------|
| [API y Cluster](#api-y-cluster) | 1 |
| [Namespaces](#namespaces) | 1 |
| [Labels y Selectors](#labels-y-selectors) | 1 |
| [Pods](#pods) | 1 |
| [Multi-container Pods](#multi-container-pods) | 1 |
| [Init Containers](#init-containers) | 1 |
| [Pod Lifecycle](#pod-lifecycle) | 1 |
| [Probes](#probes) | 1 |
| [Deployments](#deployments) | 2 |
| [ReplicaSets](#replicasets) | 2 |
| [Rollouts y Rollbacks](#rollouts-y-rollbacks) | 2 |
| [Scaling](#scaling) | 2 |
| [DaemonSets](#daemonsets) | 2 |
| [Jobs y CronJobs](#jobs-y-cronjobs) | 2 |
| [Networking](#networking) | 3 |
| [DNS](#dns) | 3 |
| [Services](#services) | 3 |
| [Service Discovery](#service-discovery) | 3 |
| [Ingress](#ingress) | 3 |
| [PersistentVolumes y PersistentVolumeClaims](#persistentvolumes-y-persistentvolumeclaims) | 4 |
| [StorageClasses y Dynamic Provisioning](#storageclasses-y-dynamic-provisioning) | 4 |
| [Taints y Tolerations](#taints-y-tolerations) | 4 |
| [Node/Pod Affinity y Resource Limits](#nodepod-affinity-y-resource-limits) | 4 |
| [Pod Disruption Budgets](#pod-disruption-budgets) | 4 |
| [Topology Spread Constraints](#topology-spread-constraints) | 4 |
| [RBAC para Service Accounts](#rbac-para-service-accounts) | 5 |
| [Autenticacion de Usuarios y MFA](#autenticacion-de-usuarios-y-mfa) | 5 |
| [Escaneo de Imagenes con Trivy Operator](#escaneo-de-imagenes-con-trivy-operator) | 5 |
| [Politicas de Admision con Kyverno](#politicas-de-admision-con-kyverno) | 5 |
| [Network Policies como Firewall](#network-policies-como-firewall) | 5 |
| [Secretos Seguros con CSI Driver](#secretos-seguros-con-csi-driver) | 5 |

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

Ejemplo YAML: [namespace.yaml](./1%20-%20Kubernetes%20api%20and%20pods/namespaces%20tags%20annotations/03/demos/namespace.yaml)

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

Ejemplo YAML: [CreatePodsWithLabels.yaml](./1%20-%20Kubernetes%20api%20and%20pods/namespaces%20tags%20annotations/03/demos/CreatePodsWithLabels.yaml), [PodsToNodes.yaml](./1%20-%20Kubernetes%20api%20and%20pods/namespaces%20tags%20annotations/03/demos/PodsToNodes.yaml)

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

Ejemplo YAML: [pod.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/pod.yaml)

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

Ejemplo YAML: [multicontainer-pod.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/multicontainer-pod.yaml)

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

Ejemplo YAML: [init-containers.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/init-containers.yaml)

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

Ejemplo YAML: [pod-restart-policy.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/pod-restart-policy.yaml)

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

Ejemplo YAML: [container-probes.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/container-probes.yaml), [container-probes-startup.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/container-probes-startup.yaml)

---

## Deployments

Conceptos clave:
- Un Deployment gestiona **ReplicaSets**, que a su vez gestionan **Pods**
- **Imperativo**: rapido para pruebas (`kubectl create deployment`)
- **Declarativo**: recomendado para produccion (`kubectl apply -f`). El estado deseado vive en codigo (YAML)
- El Deployment mantiene el **estado deseado**: si un Pod muere, el ReplicaSet lo recrea

```bash
# Crear deployment imperativamente
kubectl create deployment hello-world --image=hello-app:1.0

# Crear deployment declarativamente
kubectl apply -f deployment.yaml

# Ver estado del deployment
kubectl get deployments hello-world

# Describir deployment (replicas, conditions, events)
kubectl describe deployment hello-world

# Eliminar deployment
kubectl delete deployment hello-world
kubectl delete -f deployment.yaml

# Ver pods del sistema
kubectl get --namespace kube-system all
kubectl get --namespace kube-system deployments coredns
```

Ejemplo YAML: [deployment.yaml](./2%20-%20managing-kubernetes-controllers-deployments/02/demos/deployment.yaml)

---

## ReplicaSets

Conceptos clave:
- El ReplicaSet garantiza que el **numero deseado de Pods** este siempre corriendo
- Usa **label selectors** para identificar que Pods le pertenecen
- Cada ReplicaSet tiene un `pod-template-hash` unico que asocia los Pods a esa revision
- **Self-healing**: si se elimina un Pod, el ReplicaSet crea uno nuevo automaticamente
- Aislar un Pod (cambiar su label) es util para **debugging en produccion** sin afectar el servicio

```bash
# Ver replicasets
kubectl get replicasets

# Describir replicaset (selector, labels, pod template)
kubectl describe replicaset hello-world

# Ver pods controlados por un replicaset
kubectl get pods --show-labels
kubectl describe pods | head -n 20

# Aislar un pod del replicaset (cambiar label)
kubectl label pod <POD_NAME> app=DEBUG --overwrite

# El replicaset crea un nuevo pod para mantener el numero deseado
kubectl get pods --show-labels
```

Ejemplo YAML: [ReplicaSet.yaml](./2%20-%20managing-kubernetes-controllers-deployments/02/demos/ReplicaSet.yaml)

---

## Rollouts y Rollbacks

Conceptos clave:
- Un rollout crea un **nuevo ReplicaSet** y migra Pods del antiguo al nuevo gradualmente
- Ambos ReplicaSets se conservan (el antiguo con 0 replicas) para permitir rollback
- `kubectl rollout status` retorna exit code 0 si completo, 1 si fallo
- `--record` anota el comando en el historial de revisiones (deprecado en versiones recientes)

```bash
# Aplicar nueva version
kubectl apply -f deployment.v2.yaml

# Ver estado del rollout
kubectl rollout status deployment hello-world

# Historial de rollout
kubectl rollout history deployment hello-world

# Ver detalle de una revision especifica
kubectl rollout history deployment hello-world --revision=2

# Rollback a una revision especifica
kubectl rollout undo deployment hello-world --to-revision=2

# Reiniciar deployment (crea nuevo replicaset)
kubectl rollout restart deployment hello-world

# Aplicar deployment con --record para anotar change-cause
kubectl apply -f deployment.yaml --record
```

Conceptos clave:
- `maxUnavailable`: porcentaje o numero de pods que pueden estar offline durante el update
- `maxSurge`: pods adicionales permitidos sobre el numero deseado
- `progressDeadlineSeconds`: tiempo antes de marcar el deployment como fallido

---

## Scaling

Conceptos clave:
- Escalar modifica el numero de replicas en el ReplicaSet del Deployment
- **Imperativo**: `kubectl scale` para cambios rapidos
- **Declarativo**: modificar `spec.replicas` en el YAML y aplicar con `kubectl apply`

```bash
# Escalar imperativamente
kubectl scale deployment hello-world --replicas=10

# Escalar declarativamente (modificar replicas en YAML)
kubectl apply -f deployment.20replicas.yaml
```

---

## DaemonSets

Conceptos clave:
- Ejecutan **exactamente un Pod por nodo** (excepto control plane por defecto)
- Al agregar un nodo al cluster, el DaemonSet **automaticamente** despliega un Pod en el
- Usos comunes: monitoreo, logging, networking (kube-proxy, CNI plugins)
- Se pueden restringir a nodos especificos con `nodeSelector`
- Los updates usan `rollingUpdate` con `maxUnavailable` (default 1), mas lento que Deployments

```bash
# Ver daemonsets del sistema
kubectl get daemonsets --namespace kube-system

# Crear daemonset
kubectl apply -f DaemonSet.yaml

# Ver estado del daemonset
kubectl get daemonsets
kubectl get daemonsets -o wide
kubectl describe daemonsets hello-world-ds

# DaemonSet con nodeSelector (solo en nodos con label especifico)
kubectl apply -f DaemonSetWithNodeSelector.yaml

# Actualizar daemonset
kubectl apply -f DaemonSet-v2.yaml
kubectl rollout status daemonsets hello-world-ds

# Ver update strategy
kubectl get DaemonSet hello-world-ds -o yaml | more

# Eliminar daemonset
kubectl delete daemonsets hello-world-ds
```

Ejemplo YAML: [DaemonSet.yaml](./2%20-%20managing-kubernetes-controllers-deployments/04/demos/DaemonSet.yaml), [DaemonSetWithNodeSelector.yaml](./2%20-%20managing-kubernetes-controllers-deployments/04/demos/DaemonSetWithNodeSelector.yaml)

---

## Jobs y CronJobs

### Jobs

Conceptos clave:
- Un Job ejecuta un Pod hasta **completarse exitosamente** (exit code 0)
- Requiere `restartPolicy: OnFailure` o `Never` (no soporta `Always`)
- `backoffLimit` define el numero maximo de reintentos antes de marcar el Job como fallido
- Con `Never`, los Pods fallidos **se conservan** para inspeccion. Con `OnFailure`, el contenedor se reinicia en el mismo Pod
- Jobs en paralelo: `parallelism` define cuantos Pods corren simultaneamente, `completions` el total

```bash
# Crear job
kubectl apply -f job.yaml

# Ver estado del job
kubectl get job --watch

# Ver pods del job
kubectl get pods -l job-name=hello-world-job

# Logs del pod del job
kubectl logs <POD_NAME>

# Job en paralelo
kubectl apply -f ParallelJob.yaml

# Eliminar job (y sus pods)
kubectl delete job hello-world-job
```

### CronJobs

Conceptos clave:
- Ejecutan Jobs en un **schedule** tipo cron (ej: `*/1 * * * *` = cada minuto)
- `concurrencyPolicy`: `Allow` (default), `Forbid` (no ejecutar si el anterior no termino), `Replace`
- `successfulJobsHistoryLimit` (default 3): cuantos Jobs completados se conservan
- `startingDeadlineSeconds`: tiempo maximo para iniciar el Job despues de su hora programada

```bash
# Crear cronjob
kubectl apply -f CronJob.yaml

# Ver cronjobs
kubectl get cronjobs

# Ver detalles (schedule, concurrency, history)
kubectl describe cronjobs

# Ver configuracion completa
kubectl get cronjobs -o yaml

# Eliminar cronjob
kubectl delete cronjob hello-world-cron
```

Ejemplo YAML: [job.yaml](./2%20-%20managing-kubernetes-controllers-deployments/04/demos/job.yaml), [CronJob.yaml](./2%20-%20managing-kubernetes-controllers-deployments/04/demos/CronJob.yaml), [ParallelJob.yaml](./2%20-%20managing-kubernetes-controllers-deployments/04/demos/ParallelJob.yaml)

---

## Networking

Conceptos clave:
- Cada Pod recibe su **propia IP** en la Pod Network (ej: 192.168.0.0/16)
- Los Pods se comunican entre si **directamente por IP**, sin NAT
- El **CNI plugin** (Calico, kubenet, etc.) implementa la red entre nodos
- **Calico** usa tuneles (tunl0/IPIP) para comunicacion entre nodos
- **kubenet** (AKS) usa bridges (cbr0) y route tables del cloud provider
- Cada nodo tiene un **PodCIDR** que define el rango de IPs para sus Pods

```bash
# Ver IPs de los nodos
kubectl get nodes -o wide

# Ver IPs de los pods
kubectl get pods -o wide

# Inspeccionar red dentro de un pod
PODNAME=$(kubectl get pods --selector=app=hello-world -o jsonpath='{ .items[0].metadata.name }')
kubectl exec -it $PODNAME -- ip addr
kubectl exec -it $PODNAME -- route

# Describir nodo (ver PodCIDR, IPs, annotations de red)
kubectl describe node c1-cp1 | more
kubectl describe nodes | more

# Debug de un nodo (AKS)
kubectl debug node/$NODENAME -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11
```

---

## DNS

Conceptos clave:
- **CoreDNS** es el servidor DNS del cluster, desplegado como Deployment en `kube-system`
- Cada Service recibe un **registro A**: `<service>.<namespace>.svc.cluster.local`
- Cada Pod recibe un **registro A**: `<ip-con-dashes>.<namespace>.pod.cluster.local`
- La configuracion de CoreDNS se almacena en un **ConfigMap** en `kube-system`
- El forwarder por defecto es `/etc/resolv.conf` del nodo (se puede customizar)
- Los cambios al ConfigMap se recargan automaticamente (puede tardar 1-2 minutos)

```bash
# Ver servicio DNS del cluster
kubectl get service --namespace kube-system

# Ver deployment de CoreDNS
kubectl describe deployment coredns --namespace kube-system

# Ver configmap de CoreDNS
kubectl get configmaps --namespace kube-system coredns -o yaml

# Aplicar configuracion DNS custom
kubectl apply -f CoreDNSConfigCustom.yaml --namespace kube-system

# Ver logs de CoreDNS
kubectl logs --namespace kube-system --selector 'k8s-app=kube-dns' --follow

# Consultar DNS del cluster
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{ .spec.clusterIP }')
nslookup www.example.com $SERVICEIP

# Registro A de un pod (reemplazar dots por dashes en la IP)
nslookup 192-168-206-68.default.pod.cluster.local $SERVICEIP

# Registro A de un servicio
nslookup hello-world.default.svc.cluster.local $SERVICEIP

# DNS custom en un pod
kubectl apply -f DeploymentCustomDns.yaml
kubectl exec -it $PODNAME -- cat /etc/resolv.conf
```

Ejemplo YAML: [CoreDNSConfigCustom.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/02/demos/CoreDNSConfigCustom.yaml), [DeploymentCustomDns.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/02/demos/DeploymentCustomDns.yaml)

---

## Services

Conceptos clave:
- Un Service provee un **punto de acceso estable** (IP fija + DNS) para un conjunto de Pods
- Los Pods backend se determinan por **label selectors**
- El trafico fluye: **LoadBalancer -> NodePort -> ClusterIP -> Pod**
- Los **endpoints** son las IPs de los Pods que matchean el selector del Service
- Al escalar un Deployment, los nuevos Pods se registran automaticamente como endpoints

### ClusterIP

Accesible **solo dentro del cluster**. Es el tipo por defecto.

```bash
# Crear servicio ClusterIP imperativamente
kubectl expose deployment hello-world --port=80 --target-port=8080 --type ClusterIP

# Ver servicios
kubectl get service

# Obtener ClusterIP
SERVICEIP=$(kubectl get service hello-world -o jsonpath='{ .spec.clusterIP }')

# Acceder al servicio dentro del cluster
curl http://$SERVICEIP

# Ver endpoints del servicio
kubectl get endpoints hello-world

# Describir servicio (selector, endpoints)
kubectl describe service hello-world
```

### NodePort

Expone el servicio en un **puerto estatico en cada nodo** (rango 30000-32767). Accesible desde fuera del cluster.

```bash
# Crear servicio NodePort
kubectl expose deployment hello-world --port=80 --target-port=8080 --type NodePort

# Obtener NodePort asignado
NODEPORT=$(kubectl get service hello-world -o jsonpath='{ .spec.ports[].nodePort }')

# Acceder desde cualquier nodo del cluster
curl http://c1-node1:$NODEPORT
```

### LoadBalancer

Provisiona un **balanceador de carga externo** del cloud provider con IP publica. Solo disponible en cloud (AKS, GKE, EKS).

```bash
# Crear servicio LoadBalancer (solo en cloud)
kubectl expose deployment hello-world --port=80 --target-port=8080 --type LoadBalancer

# Obtener IP publica
LOADBALANCERIP=$(kubectl get service hello-world -o jsonpath='{ .status.loadBalancer.ingress[].ip }')
curl http://$LOADBALANCERIP
```

Ejemplo YAML: [service-hello-world-clusterip.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/03/demos/service-hello-world-clusterip.yaml), [service-hello-world-nodeport.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/03/demos/service-hello-world-nodeport.yaml), [service-hello-world-loadbalancer.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/03/demos/service-hello-world-loadbalancer.yaml)

---

## Service Discovery

Conceptos clave:
- Formato DNS: `<service>.<namespace>.svc.cluster.local`
- **DNS** es el metodo recomendado. Las **variables de entorno** solo estan disponibles si el Service existia antes de crear el Pod
- **ExternalName**: crea un CNAME que apunta a un dominio externo (no tiene ClusterIP ni endpoints)

```bash
# Formato del registro DNS de un servicio
# <servicename>.<namespace>.svc.<clusterdomain>
nslookup hello-world.default.svc.cluster.local 10.96.0.10

# Mismo nombre de servicio en diferente namespace
nslookup hello-world.ns1.svc.cluster.local 10.96.0.10

# Variables de entorno del servicio (disponibles al crear el pod)
kubectl exec -it $PODNAME -- env | sort

# ExternalName service (CNAME a un dominio externo)
kubectl apply -f service-externalname.yaml
nslookup hello-world-api.default.svc.cluster.local 10.96.0.10
```

Ejemplo YAML: [service-externalname.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/03/demos/service-externalname.yaml)

---

## Ingress

Conceptos clave:
- Ingress **no funciona sin un Ingress Controller** instalado (nginx, traefik, HAProxy, etc.)
- El Ingress Controller es un Pod que implementa las reglas de Ingress y rutea trafico HTTP/HTTPS
- El trafico va **directo del Ingress Controller al Pod**, sin pasar por kube-proxy
- Se pueden definir reglas por **path**, por **hostname** (virtual hosts), o ambos
- Soporta **TLS termination** usando Secrets de tipo TLS

### Ingress Controller

```bash
# Desplegar ingress controller nginx
kubectl apply -f ./cloud/deploy.yaml        # cloud
kubectl apply -f ./baremetal/deploy.yaml     # bare metal

# Verificar pods del ingress controller
kubectl get pods --namespace ingress-nginx

# Verificar servicio del ingress controller
kubectl get services --namespace ingress-nginx

# Ver ingress class
kubectl describe ingressclasses nginx
```

### Ingress Rules

```bash
# Ingress simple (un solo backend)
kubectl apply -f ingress-single.yaml

# Ingress con rutas por path
kubectl apply -f ingress-path.yaml

# Ingress con virtual hosts (name-based)
kubectl apply -f ingress-namebased.yaml

# Ver estado del ingress
kubectl get ingress --watch

# Describir ingress (backends, rules)
kubectl describe ingress ingress-path

# Obtener IP del ingress
INGRESSIP=$(kubectl get ingress -o jsonpath='{ .items[].status.loadBalancer.ingress[].ip }')

# Acceder con host header
curl http://$INGRESSIP/red --header 'Host: path.example.com'
curl http://$INGRESSIP/ --header 'Host: red.example.com'
```

### Ingress TLS

```bash
# Generar certificado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout tls.key -out tls.crt -subj "/C=US/ST=ILLINOIS/L=CHICAGO/O=IT/OU=IT/CN=tls.example.com"

# Crear secret TLS
kubectl create secret tls tls-secret --key tls.key --cert tls.crt

# Crear ingress con TLS
kubectl apply -f ingress-tls.yaml

# Probar HTTPS
curl https://tls.example.com:443 --resolve tls.example.com:443:$INGRESSIP --insecure
```

Ejemplo YAML: [ingress-single.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/04/demos/ingress-single.yaml), [ingress-path.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/04/demos/ingress-path.yaml), [ingress-tls.yaml](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/04/demos/ingress-tls.yaml)

---

## PersistentVolumes y PersistentVolumeClaims

Conceptos clave:
- Los contenedores son **efimeros por defecto**: cualquier dato en el sistema de archivos del contenedor desaparece al reiniciar o reemplazar el Pod
- Un **PersistentVolume (PV)** representa una pieza de almacenamiento en el cluster, provisionada por un admin o dinamicamente por una StorageClass
- Un **PersistentVolumeClaim (PVC)** es la solicitud de almacenamiento por parte de un workload — Kubernetes actua como "matchmaker" entre PVC y PV
- `accessModes`: `ReadWriteOnce` (un solo nodo), `ReadOnlyMany`, `ReadWriteMany`
- Una vez que el PVC queda en estado `Bound`, el pod puede montar ese almacenamiento y los datos persisten aunque el pod sea eliminado y recreado

```bash
# Crear PersistentVolume
kubectl apply -f pv-demo.yaml

# Crear PersistentVolumeClaim
kubectl apply -f pvc-demo.yaml

# Verificar estado del PVC (debe estar en Bound)
kubectl get pvc

# Crear el pod que consume el PVC
kubectl apply -f pod-demo.yaml

# Verificar persistencia: eliminar pod, recrear y comprobar datos
kubectl delete pod pod-demo
kubectl apply -f pod-demo.yaml
kubectl exec -it pod-demo -- cat /data/test.txt
```

---

## StorageClasses y Dynamic Provisioning

Conceptos clave:
- Una **StorageClass** actua como una "receta" para el almacenamiento: define el provisioner, parametros y politica de ciclo de vida
- `provisioner`: quien crea el almacenamiento (ej: `ebs.csi.aws.com`). Para local sin backend: `kubernetes.io/no-provisioner`
- `reclaimPolicy: Delete` elimina el PV al borrar el PVC (dev/test). `Retain` lo conserva (produccion)
- `volumeBindingMode: Immediate` enlaza el volumen en cuanto se crea el PVC
- El **provisionamiento dinamico** elimina la necesidad de crear PVs manualmente

```bash
# Crear la StorageClass
kubectl apply -f storageclass.yaml

# Ver StorageClasses disponibles
kubectl get sc

# Crear PVC que referencia la StorageClass
kubectl apply -f pvc.yaml

# Verificar que el PVC quedo Bound
kubectl get pvc

# Desplegar pod que usa el PVC
kubectl apply -f pod.yaml
kubectl get pods
```

---

## Taints y Tolerations

Conceptos clave:
- Un **taint** marca un nodo para que pods ordinarios no sean programados en el: `key=value:Effect`
- Efectos: `NoSchedule` (no programar), `PreferNoSchedule` (evitar), `NoExecute` (tampoco los ya corriendo)
- Una **toleration** en el Pod es la "llave" que le permite ignorar el taint del nodo
- Toleration solo **permite** el scheduling en el nodo taintado — no lo fuerza. Combinar con `nodeSelector` para forzarlo

```bash
# Ver nodos del cluster
kubectl get nodes

# Aplicar taint a un nodo
kubectl taint nodes desktop-worker dedicated=analytics:NoSchedule

# Verificar el taint
kubectl describe node desktop-worker | grep Taints

# Etiquetar nodo para el nodeSelector
kubectl label node desktop-worker dedicated=analytics

# Desplegar pod con toleration + nodeSelector
kubectl apply -f analytics-pod.yaml
kubectl get pods -o wide

# Eliminar el taint (agregar - al final)
kubectl taint nodes desktop-worker dedicated=analytics:NoSchedule-
```

---

## Node/Pod Affinity y Resource Limits

Conceptos clave:
- **Node affinity** guia al scheduler hacia nodos con labels especificos. `requiredDuringSchedulingIgnoredDuringExecution` es obligatoria
- **Pod affinity** coloca pods cerca de otros pods con ciertos labels (util para sidecars y caches locales)
- **Pod anti-affinity** mantiene replicas en nodos distintos para mejorar tolerancia a fallos
- **Resource requests**: minimo de CPU/memoria que necesita el pod para ser programado
- **Resource limits**: maximo que puede consumir — CPU throttled si supera, pod OOMKilled si supera memoria

```bash
# Etiquetar nodos para affinity rules
kubectl label node desktop-worker role=analytics
kubectl label node desktop-worker2 role=web

# Desplegar pod con node affinity y resource limits
kubectl apply -f analytics-affinity-pod.yaml
kubectl get pods -o wide

# Desplegar sidecar con pod affinity
kubectl apply -f frontend-sidecar.yaml
kubectl get pods -o wide
```

---

## Pod Disruption Budgets

Conceptos clave:
- Un **Pod Disruption Budget (PDB)** define cuantos pods pueden ser interrumpidos durante disrupciones voluntarias (drains, upgrades)
- `minAvailable: N` garantiza que al menos N pods permanezcan corriendo
- `maxUnavailable: N` equivalente — cuantos pueden estar caidos
- Solo aplica a **disrupciones voluntarias**. Fallos de nodo no son controlados por el PDB
- Si un drain violaria el PDB, Kubernetes lo bloquea hasta que haya suficientes pods disponibles

```bash
# Desplegar app con multiples replicas
kubectl apply -f webapp-deployment.yaml
kubectl get pods -l app=webapp

# Crear el PDB
kubectl apply -f webapp-pdb.yaml

# Ver disrupciones permitidas
kubectl get pdb
kubectl describe pdb webapp-pdb

# Simular drain (respeta el PDB)
kubectl drain desktop-worker --ignore-daemonsets --delete-emptydir-data

# Restaurar el nodo
kubectl uncordon desktop-worker

# Intentar drain que viola el PDB (sera bloqueado)
kubectl drain desktop-worker2 --ignore-daemonsets --delete-emptydir-data
```

---

## Topology Spread Constraints

Conceptos clave:
- Distribuyen pods uniformemente entre zonas, nodos u otros dominios de fallo para aumentar tolerancia a fallos
- `maxSkew: N` — diferencia maxima en numero de pods entre nodos
- `topologyKey`: `kubernetes.io/hostname` (por nodo) o `topology.kubernetes.io/zone` (por zona)
- `whenUnsatisfiable: DoNotSchedule` bloquea scheduling si no puede cumplir la restriccion
- Combinando topology spread + PDB se garantiza **alta disponibilidad y distribucion balanceada** simultaneamente

```bash
# Desplegar con topology spread constraints
kubectl apply -f topology-demo.yaml

# Verificar distribucion de pods entre nodos
kubectl get pods -o wide -l app=topology-demo

# Combinar topology spread + PDB
kubectl apply -f topology-pdb-demo.yaml
kubectl apply -f topology-pdb-demo-pdb.yaml
kubectl get pods -o wide

# Simular disruption (bloqueada si viola el PDB)
kubectl drain desktop-worker --ignore-daemonsets --delete-emptydir-data
kubectl uncordon desktop-worker
```

---

## RBAC para Service Accounts

Conceptos clave:
- **RBAC** controla quien puede acceder a la API de Kubernetes y que puede hacer — la base de Defense in Depth
- **Role** define permisos (verbos: get, list, create, delete) sobre recursos dentro de un namespace
- **ClusterRole** equal que Role pero a nivel de cluster o como plantilla reutilizable
- **RoleBinding** conecta un Role a un ServiceAccount o User en un namespace especifico
- **ClusterRoleBinding** conecta un ClusterRole a un sujeto con permisos en todo el cluster
- Anti-patron critico: SA `default` con `cluster-admin` — todos los pods sin SA explicito lo heredan
- `automountServiceAccountToken: false` deshabilita el token en pods que no necesitan acceso a la API
- Los permisos RBAC se evaluan en runtime sin necesidad de reiniciar pods

```bash
# Detectar SA default con permisos peligrosos
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.subjects[]? | select(.name == "default")) | {name: .metadata.name, role: .roleRef.name}'

# Ver todos los ServiceAccounts
kubectl get serviceaccounts -n default

# Verificar permisos de un SA especifico
kubectl auth can-i get pods --namespace default --as system:serviceaccount:default:kube-explorer
kubectl auth can-i delete pods --namespace kube-system --as system:serviceaccount:default:kube-explorer

# Listar todos los RoleBindings de un SA en todos los namespaces
kubectl get rolebindings -A -o json | jq -r '[.items[] | select(.subjects[].name == "kube-explorer") | {namespace: .metadata.namespace, name: .metadata.name, role: .roleRef.name}]'

# Aplicar RBAC con minimo privilegio (Role + SA + RoleBinding)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo1/update-1/rbac.yaml

# Ampliar permisos a otro namespace (solo lectura)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo1/update-2/rbac.yaml

# Listar todos mis permisos actuales
kubectl auth can-i --list
kubectl auth can-i --list --namespace wiredbrain

# Inspeccionar el JWT del ServiceAccount dentro del pod
kubectl exec deploy/kube-explorer -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

Ejemplo YAML: [rbac-insecure.yaml](./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo1/setup/rbac-insecure.yaml), [update-1/rbac.yaml](./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo1/update-1/rbac.yaml), [update-2/rbac.yaml](./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo1/update-2/rbac.yaml)

---

## Autenticacion de Usuarios y MFA

Conceptos clave:
- Kubernetes **no gestiona usuarios internamente** — delega a sistemas externos (certificados, tokens, OIDC)
- Credenciales estaticas en kubeconfig son un riesgo: si el archivo se compromete, el atacante tiene acceso indefinido
- **Azure Entra ID + kubelogin** integran AKS con MFA y tokens de corta duracion (~1 hora)
- `--disable-local-accounts` en AKS elimina el backdoor de credenciales estaticas
- ClusterRoles predefinidos: `view` (lectura), `edit` (lectura/escritura), `admin` (full namespace), `cluster-admin` (root)
- El mismo modelo aplica para EKS (AWS IAM), GKE (Google Identity), on-prem (Keycloak + OIDC)

```bash
# Obtener credenciales del cluster (sin AD)
az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing

# Ver metodo de autenticacion actual
kubectl config view --minify

# Habilitar Azure Entra ID y deshabilitar cuentas locales
$adminGroupId = az ad group show --group "cluster-admins" --query id -o tsv
az aks update --resource-group <rg> --name <cluster> --enable-aad --aad-admin-group-object-ids $adminGroupId --disable-local-accounts

# Obtener credenciales (ahora usa kubelogin con exec)
az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing

# Primera autenticacion con MFA (device code en el navegador)
kubectl get nodes

# Verificar permisos del admin
kubectl auth can-i --list

# Crear usuario con minimo privilegio (view en un namespace)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo2/rbac/least-privilege.yaml

# Credenciales separadas para usuario restringido
az aks get-credentials --resource-group <rg> --name <cluster> --file least-privilege.kubeconfig
kubectl --kubeconfig least-privilege.kubeconfig get pods -n wiredbrain
kubectl --kubeconfig least-privilege.kubeconfig auth can-i --list
```

Ejemplo YAML: [least-privilege.yaml](./5%20-%20configuring-managing-kubernetes-security-2/01/demos/m1/demo2/rbac/least-privilege.yaml)

---

## Escaneo de Imagenes con Trivy Operator

Conceptos clave:
- **Supply chain complexity**: cada imagen contiene cientos de paquetes con release schedules independientes
- **Trivy Operator** escanea continuamente todas las imagenes de todos los pods del cluster
- Produce **VulnerabilityReport** como custom resource — consultable con kubectl como cualquier objeto
- El escaneo es continuo: detecta nuevas CVEs en imagenes ya desplegadas
- Los reportes persisten aunque el pod se escale a 0 (se limpian solo si se elimina el Deployment)

```bash
# Instalar Trivy Operator
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update
helm install trivy-operator aqua/trivy-operator --namespace trivy-system --create-namespace --set="trivy.resources.limits.memory=4Gi" --version 0.31.0 --wait

# Ver pods del operador
kubectl get pods -n trivy-system

# Ver reportes generados (esperar unos minutos despues de instalar)
kubectl get vulnerabilityreport -A
kubectl get vulnerabilityreport -w -n wiredbrain

# Ver resumen de severidades
kubectl get vulnerabilityreport <nombre> -n wiredbrain -o jsonpath='{.report.summary}' | jq .

# Listar imagenes con CVEs criticos en todo el cluster
kubectl get vulnerabilityreport -A -o json | jq -r '.items[] | select(.report.summary.criticalCount > 0) | {image: .report.artifact.repository, tag: .report.artifact.tag, critical: .report.summary.criticalCount}'

# Escalar a 0 para remover pod vulnerable (el reporte persiste)
kubectl scale deploy/products-api-vulnerable --replicas 0 -n wiredbrain
```

Ejemplo YAML: [vulnerable-app.yaml](./5%20-%20configuring-managing-kubernetes-security-2/02/demos/m2/demo1/initial-scan/vulnerable-app.yaml), [block-critical-cves.yaml](./5%20-%20configuring-managing-kubernetes-security-2/02/demos/m2/demo1/admission-control/block-critical-cves.yaml)

---

## Politicas de Admision con Kyverno

Conceptos clave:
- **Kyverno** es un policy engine nativo de Kubernetes — las politicas se definen como YAML (ClusterPolicy)
- **Admission Control**: intercepta creaciones/actualizaciones antes de que se persistan en etcd
- `validationFailureAction: Enforce` — bloquea el recurso si viola la politica (hard gate)
- `validationFailureAction: Audit` — permite el recurso pero registra la violacion (soft gate)
- CVEs en modo Audit (no Enforce) para no interrumpir auto-scaling o rolling updates en produccion
- **Policy Reports**: Kyverno genera reportes automaticos consultables con kubectl

```bash
# Instalar Kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace --version 3.5.2 --wait

# Verificar los tres controladores
kubectl get pods -n kyverno

# Aplicar politicas de seguridad (Enforce: registry + non-root)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/02/demos/m2/demo2/admission-control/security-policies.yaml

# Aplicar politica de CVEs (Audit: no bloquea)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/02/demos/m2/demo2/admission-control/vulnerability-report-policy.yaml

# Ver ClusterPolicies activas
kubectl get clusterpolicies

# Ver Policy Reports (resultado de evaluaciones)
kubectl get policyreport -A
kubectl get policyreport -n wiredbrain -o yaml

# Ver solo violaciones (modo audit)
kubectl get policyreport -n wiredbrain -o jsonpath='{.items[0].results}' | jq '.[] | select(.result == "fail")'
```

Ejemplo YAML: [security-policies.yaml](./5%20-%20configuring-managing-kubernetes-security-2/02/demos/m2/demo2/admission-control/security-policies.yaml), [vulnerability-report-policy.yaml](./5%20-%20configuring-managing-kubernetes-security-2/02/demos/m2/demo2/admission-control/vulnerability-report-policy.yaml)

---

## Network Policies como Firewall

Conceptos clave:
- Kubernetes networking es **abierto por default** — cualquier pod puede hablar con cualquier otro
- **NetworkPolicy** es el firewall nativo de Kubernetes — usa label selectors para definir reglas
- `Ingress`: quien puede enviarme trafico. `Egress`: a donde puedo enviar trafico
- **Zero-trust baseline**: `podSelector: {}` sin reglas = default-deny para todos los pods del namespace
- Las politicas son **aditivas** (OR logico) y se evaluan en runtime sin restart
- **DNS critico**: bloquear todo egress tambien bloquea DNS (puerto 53/UDP) — siempre agregar `allow-dns`
- Requiere CNI con soporte: Calico, Cilium, k3d (Docker Desktop **no** soporta NetworkPolicy)
- Cada comunicacion necesita **egress en el origen + ingress en el destino**

```bash
# Crear cluster local con soporte de NetworkPolicy
k3d cluster create mi-cluster --agents 1 --k3s-arg "--disable=traefik@server:0"

# Desplegar app (sin restricciones iniciales)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo1/initial-deploy/

# Probar problema: web puede llegar a DB directamente
kubectl exec -n wiredbrain deploy/web-app -- nc -zv products-db 5432

# Aplicar default-deny (bloquea todo)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo1/default-deny/default-deny.yaml

# Permitir DNS (obligatorio o nada funciona)
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo1/allow-policies/allow-dns.yaml

# Aplicar todas las politicas de la app
kubectl apply -f ./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo1/allow-policies/

# Verificar segmentacion: debe FALLAR (web -> db directa)
kubectl exec -n wiredbrain deploy/web-app -- nc -zv products-db 5432

# Verificar: debe FUNCIONAR (web -> api)
kubectl exec -n wiredbrain deploy/web-app -- wget -qO- http://products-api/products

# Verificar: debe FALLAR (egress a internet)
kubectl exec -n wiredbrain deploy/web-app -- wget -qO- http://example.com

# Ver NetworkPolicies activas
kubectl get networkpolicy -n wiredbrain
kubectl describe networkpolicy default-deny-all -n wiredbrain
```

Ejemplo YAML: [default-deny.yaml](./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo1/default-deny/default-deny.yaml), [allow-dns.yaml](./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo1/allow-policies/allow-dns.yaml)

---

## Secretos Seguros con CSI Driver

Conceptos clave:
- **Kubernetes Secrets** usan base64 — NO es cifrado, trivialmente decodificable con `base64 -d`
- Tres vectores de ataque: en source control (values.yaml), en etcd (base64), como variable de entorno en el pod
- **External Secrets**: Azure Key Vault, AWS Secrets Manager, HashiCorp Vault — los secretos nunca tocan etcd
- **Secret Store CSI Driver** monta secretos externos como archivos read-only en el pod
- **SecretProviderClass** define que secretos obtener de que vault y como nombrar los archivos
- **Workload Identity / IRSA**: el pod se autentica al vault via OIDC usando su ServiceAccount — sin credenciales estaticas
- Los secretos se montan en memoria del nodo (`/mnt/secrets/`) — NO se persisten en disco

```bash
# Ver el problema con Kubernetes Secrets normales
kubectl get secret db-credentials -n wiredbrain -o yaml
kubectl get secret db-credentials -n wiredbrain -o jsonpath='{.data.password}' | base64 -d

# Ver el secret como variable de entorno (vector de ataque)
kubectl exec -n wiredbrain deploy/database -- printenv POSTGRES_PASSWORD

# Crear AKS con workload identity y CSI driver habilitados
az aks create --resource-group <rg> --name <cluster> --enable-managed-identity --enable-addons azure-keyvault-secrets-provider --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys

# Desplegar con CSI Driver (sin Kubernetes Secrets)
helm upgrade wiredbrain ./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo2/charts/wiredbrain-secure --namespace wiredbrain -f values-csi.yaml --wait

# Verificar que el secret ya NO existe en Kubernetes
kubectl get secret db-credentials -n wiredbrain

# Verificar que la variable de entorno ya NO tiene el password
kubectl exec -n wiredbrain deploy/database -- printenv POSTGRES_PASSWORD

# El secreto ahora esta como archivo (en memoria del nodo)
kubectl exec -n wiredbrain deploy/database -- ls /mnt/secrets/
kubectl exec -n wiredbrain deploy/database -- cat /mnt/secrets/postgres-password

# Verificar secretos en Azure Key Vault
az keyvault secret list --vault-name <vault-name> -o table
```

Ejemplo YAML: [secret-provider.yaml](./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo2/charts/wiredbrain-secure/templates/secret-provider.yaml), [serviceaccount.yaml](./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo2/charts/wiredbrain-secure/templates/serviceaccount.yaml), [database.yaml](./5%20-%20configuring-managing-kubernetes-security-2/03/demos/m3/demo2/charts/wiredbrain-secure/templates/database.yaml)
