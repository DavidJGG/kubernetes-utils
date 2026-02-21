# Networking, Services e Ingress

Comandos para networking, DNS, services, service discovery e ingress en Kubernetes.

## Indice

- [Networking](#networking)
- [DNS](#dns)
- [Services](#services)
  - [ClusterIP](#clusterip)
  - [NodePort](#nodeport)
  - [LoadBalancer](#loadbalancer)
- [Service Discovery](#service-discovery)
- [Ingress](#ingress)
  - [Ingress Controller](#ingress-controller)
  - [Ingress Rules](#ingress-rules)
  - [Ingress TLS](#ingress-tls)

---

## Networking

Investigar la red del cluster (pod network, interfaces, rutas, tuneles).

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
```

### Red en el nodo (Calico - tunnels)

```bash
# Ver rutas en el nodo (tunl0 para trafico entre nodos)
route

# Ver interfaces (tunl0, cali*)
ip addr
```

### Red en el nodo (kubenet - bridges, AKS)

```bash
# Debug de un nodo en AKS
NODENAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$NODENAME -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11

# Ver rutas (cbr0 bridge para pods locales)
route

# Ver interfaces (eth0, cbr0, veth)
ip addr

# Ver conexiones del bridge
brctl show
```

Ejemplo YAML: [Deployment.yaml](./02/demos/Deployment.yaml)

---

## DNS

CoreDNS en el cluster.

```bash
# Ver servicio DNS del cluster
kubectl get service --namespace kube-system

# Ver deployment de CoreDNS
kubectl describe deployment coredns --namespace kube-system | more

# Ver configmap de CoreDNS
kubectl get configmaps --namespace kube-system coredns -o yaml | more

# Aplicar configuracion DNS custom (forwarders personalizados)
kubectl apply -f CoreDNSConfigCustom.yaml --namespace kube-system

# Restaurar configuracion DNS default
kubectl apply -f CoreDNSConfigDefault.yaml --namespace kube-system

# Ver logs de CoreDNS (esperar reload)
kubectl logs --namespace kube-system --selector 'k8s-app=kube-dns' --follow
```

### Consultas DNS

```bash
# Obtener IP del servicio DNS
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{ .spec.clusterIP }')

# Consultar dominio externo contra el DNS del cluster
nslookup www.example.com $SERVICEIP

# Registro A de un pod (reemplazar dots por dashes en la IP)
nslookup 192-168-206-68.default.pod.cluster.local $SERVICEIP

# Registro A de un servicio
nslookup hello-world.default.svc.cluster.local $SERVICEIP
```

### DNS custom en un pod

```bash
# Crear deployment con dnsConfig personalizado
kubectl apply -f DeploymentCustomDns.yaml

# Verificar resolv.conf del pod
PODNAME=$(kubectl get pods --selector=app=hello-world-customdns -o jsonpath='{ .items[0].metadata.name }')
kubectl exec -it $PODNAME -- cat /etc/resolv.conf
```

### Debug DNS con tcpdump

```bash
# Encontrar nodo del pod DNS
DNSPODNODENAME=$(kubectl get pods --namespace kube-system --selector=k8s-app=kube-dns -o jsonpath='{ .items[0].spec.nodeName }')

# Capturar trafico DNS en ese nodo
ssh aen@$DNSPODNODENAME
sudo tcpdump -i ens33 port 53 -n

# Lanzar pod temporal para pruebas DNS
kubectl run -it --rm debian --image=debian
apt-get update && apt-get install dnsutils -y
nslookup www.example.com
```

Ejemplo YAML: [CoreDNSConfigCustom.yaml](./02/demos/CoreDNSConfigCustom.yaml), [CoreDNSConfigDefault.yaml](./02/demos/CoreDNSConfigDefault.yaml), [DeploymentCustomDns.yaml](./02/demos/DeploymentCustomDns.yaml)

---

## Services

### ClusterIP

Accesible solo dentro del cluster.

```bash
# Crear deployment y servicio ClusterIP
kubectl create deployment hello-world-clusterip --image=hello-app:1.0
kubectl expose deployment hello-world-clusterip --port=80 --target-port=8080 --type ClusterIP

# Ver servicios
kubectl get service

# Obtener ClusterIP
SERVICEIP=$(kubectl get service hello-world-clusterip -o jsonpath='{ .spec.clusterIP }')

# Acceder al servicio dentro del cluster
curl http://$SERVICEIP

# Ver endpoints del servicio
kubectl get endpoints hello-world-clusterip

# Acceder directo al pod (target port, sin pasar por el servicio)
PODIP=$(kubectl get endpoints hello-world-clusterip -o jsonpath='{ .subsets[].addresses[].ip }')
curl http://$PODIP:8080

# Escalar y verificar nuevos endpoints
kubectl scale deployment hello-world-clusterip --replicas=6
kubectl get endpoints hello-world-clusterip

# Describir servicio (selector, endpoints)
kubectl describe service hello-world-clusterip
kubectl get pods --show-labels
```

### NodePort

Accesible desde fuera del cluster en el puerto del nodo.

```bash
# Crear deployment y servicio NodePort
kubectl create deployment hello-world-nodeport --image=hello-app:1.0
kubectl expose deployment hello-world-nodeport --port=80 --target-port=8080 --type NodePort

# Obtener puerto asignado
NODEPORT=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.ports[].nodePort }')

# Acceder desde cualquier nodo del cluster
curl http://c1-cp1:$NODEPORT
curl http://c1-node1:$NODEPORT

# Tambien accesible via ClusterIP
CLUSTERIP=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.clusterIP }')
PORT=$(kubectl get service hello-world-nodeport -o jsonpath='{ .spec.ports[].port }')
curl http://$CLUSTERIP:$PORT
```

### LoadBalancer

Accesible con IP publica (solo en cloud).

```bash
# Cambiar contexto a cloud
kubectl config use-context 'CSCluster'

# Crear deployment y servicio LoadBalancer
kubectl create deployment hello-world-loadbalancer --image=hello-app:1.0
kubectl expose deployment hello-world-loadbalancer --port=80 --target-port=8080 --type LoadBalancer

# Esperar IP publica (EXTERNAL-IP pasa de <pending> a IP)
kubectl get service

# Obtener IP publica
LOADBALANCERIP=$(kubectl get service hello-world-loadbalancer -o jsonpath='{ .status.loadBalancer.ingress[].ip }')
curl http://$LOADBALANCERIP
```

Ejemplo YAML: [service-hello-world-clusterip.yaml](./03/demos/service-hello-world-clusterip.yaml), [service-hello-world-nodeport.yaml](./03/demos/service-hello-world-nodeport.yaml), [service-hello-world-loadbalancer.yaml](./03/demos/service-hello-world-loadbalancer.yaml)

---

## Service Discovery

```bash
# Formato DNS de un servicio: <service>.<namespace>.svc.<clusterdomain>
nslookup hello-world-clusterip.default.svc.cluster.local 10.96.0.10

# Mismo nombre de servicio en diferente namespace
kubectl create namespace ns1
kubectl create deployment hello-world-clusterip --namespace ns1 --image=hello-app:1.0
kubectl expose deployment hello-world-clusterip --namespace ns1 --port=80 --target-port=8080 --type ClusterIP
nslookup hello-world-clusterip.ns1.svc.cluster.local 10.96.0.10

# Variables de entorno del servicio (solo disponibles si el servicio existia antes del pod)
PODNAME=$(kubectl get pods -o jsonpath='{ .items[].metadata.name }')
kubectl exec -it $PODNAME -- env | sort

# ExternalName service (CNAME a un dominio externo)
kubectl apply -f service-externalname.yaml
nslookup hello-world-api.default.svc.cluster.local 10.96.0.10
```

Ejemplo YAML: [service-externalname.yaml](./03/demos/service-externalname.yaml)

---

## Ingress

### Ingress Controller

```bash
# Desplegar ingress controller nginx (cloud)
kubectl apply -f ./cloud/deploy.yaml

# Desplegar ingress controller nginx (bare metal)
kubectl apply -f ./baremetal/deploy.yaml

# Verificar pods del ingress controller
kubectl get pods --namespace ingress-nginx

# Verificar servicio del ingress controller (EXTERNAL-IP en cloud)
kubectl get services --namespace ingress-nginx

# Ver ingress class
kubectl describe ingressclasses nginx

# Marcar como default ingress class (opcional)
kubectl annotate ingressclasses nginx "ingressclass.kubernetes.io/is-default-class=true"
```

### Ingress Rules

```bash
# Ingress simple (un solo backend, todo el trafico)
kubectl apply -f ingress-single.yaml

# Ingress con rutas por path
kubectl apply -f ingress-path.yaml

# Ingress con path y default backend
kubectl apply -f ingress-path-backend.yaml

# Ingress con virtual hosts (name-based)
kubectl apply -f ingress-namebased.yaml

# Ver estado del ingress (esperar ADDRESS)
kubectl get ingress --watch

# Describir ingress (backends, rules)
kubectl describe ingress ingress-single
kubectl describe ingress ingress-path

# Obtener IP del ingress
INGRESSIP=$(kubectl get ingress -o jsonpath='{ .items[].status.loadBalancer.ingress[].ip }')

# Acceder por path (con host header)
curl http://$INGRESSIP/red  --header 'Host: path.example.com'
curl http://$INGRESSIP/blue --header 'Host: path.example.com'

# Acceder por virtual host
curl http://$INGRESSIP/ --header 'Host: red.example.com'
curl http://$INGRESSIP/ --header 'Host: blue.example.com'
```

### Ingress TLS

```bash
# 1. Generar certificado auto-firmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout tls.key -out tls.crt -subj "/C=US/ST=ILLINOIS/L=CHICAGO/O=IT/OU=IT/CN=tls.example.com"

# 2. Crear secret TLS en Kubernetes
kubectl create secret tls tls-secret --key tls.key --cert tls.crt

# 3. Crear ingress con TLS
kubectl apply -f ingress-tls.yaml

# 4. Verificar que tiene IP asignada
kubectl get ingress --watch

# 5. Probar HTTPS (--resolve porque no hay DNS registrado)
curl https://tls.example.com:443 --resolve tls.example.com:443:$INGRESSIP --insecure
```

Ejemplo YAML: [ingress-single.yaml](./04/demos/ingress-single.yaml), [ingress-path.yaml](./04/demos/ingress-path.yaml), [ingress-namebased.yaml](./04/demos/ingress-namebased.yaml), [ingress-tls.yaml](./04/demos/ingress-tls.yaml)
