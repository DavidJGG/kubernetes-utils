# Kubernetes Commands Reference

Referencia de comandos `kubectl` organizados por categoria, extraidos de demos y transcripciones del curso.

Cada seccion tiene su propio README con mas detalle:

- [Seccion 1 - API, Namespaces, Labels y Pods](./1%20-%20Kubernetes%20api%20and%20pods/README.md)
- [Seccion 2 - Controllers y Deployments](./2%20-%20managing-kubernetes-controllers-deployments/README.md)
- [Seccion 3 - Networking, Services e Ingress](./3%20-%20configuring-managing-kubernetes-networking-services-ingress/README.md)

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

---

## API y Cluster

Informacion del cluster, contextos y descubrimiento de la API.

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

```bash
# Comparar manifiesto local contra lo que esta en el cluster
kubectl diff -f deployment-new.yaml
```

### proxy y verbosity

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

Los init containers se ejecutan en serie hasta completarse antes de que inicie el contenedor principal.

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

Restart policies: `Always` (default), `OnFailure`, `Never`.

Ejemplo YAML: [pod-restart-policy.yaml](./1%20-%20Kubernetes%20api%20and%20pods/pods/04/demos/pod-restart-policy.yaml)

---

## Probes

Tipos: `livenessProbe`, `readinessProbe`, `startupProbe`.

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

```bash
# Escalar imperativamente
kubectl scale deployment hello-world --replicas=10

# Escalar declarativamente (modificar replicas en YAML)
kubectl apply -f deployment.20replicas.yaml
```

---

## DaemonSets

Ejecutan un pod en cada nodo del cluster.

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

Investigar la red del cluster (pod network, interfaces, rutas).

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

CoreDNS en el cluster.

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

### ClusterIP

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

```bash
# Crear servicio NodePort
kubectl expose deployment hello-world --port=80 --target-port=8080 --type NodePort

# Obtener NodePort asignado
NODEPORT=$(kubectl get service hello-world -o jsonpath='{ .spec.ports[].nodePort }')

# Acceder desde cualquier nodo del cluster
curl http://c1-node1:$NODEPORT
```

### LoadBalancer

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
