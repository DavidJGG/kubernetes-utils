# Seccion 6 - Mantenimiento, Monitoreo y Troubleshooting de Kubernetes

Referencia de comandos y conceptos extraidos de demos y transcripciones del curso.

## Indice

| Categoria | Demo |
|-----------|------|
| [Helm - Gestion de Aplicaciones](#helm---gestion-de-aplicaciones) | 01/demo1 |
| [Alta Disponibilidad (HA)](#alta-disponibilidad-ha) | 01/demo2 |
| [Upgrade de Cluster Kubernetes](#upgrade-de-cluster-kubernetes) | 01/demo3 |
| [Metrics Server](#metrics-server) | 02/demo4 |
| [Prometheus y Grafana](#prometheus-y-grafana) | 02/demo5 |
| [Logging Centralizado con Loki y Grafana Alloy](#logging-centralizado-con-loki-y-grafana-alloy) | 02/demo6 |
| [SLI, SLO, SLA y Chaos Engineering](#sli-slo-sla-y-chaos-engineering) | 02/demo7 |
| [Troubleshooting: Workflow General](#troubleshooting-workflow-general) | 03 |
| [Troubleshooting: CrashLoopBackOff](#troubleshooting-crashloopbackoff) | 03 |
| [Troubleshooting: ImagePullBackOff](#troubleshooting-imagepullbackoff) | 03 |
| [Troubleshooting: Pending Pods](#troubleshooting-pending-pods) | 03 |
| [Troubleshooting: Networking](#troubleshooting-networking) | 03 |
| [Troubleshooting: OOMKilled](#troubleshooting-oomkilled) | 03 |

---

## Helm - Gestion de Aplicaciones

Conceptos clave:
- **Helm** es el package manager para Kubernetes (equivalente a apt/Homebrew pero para K8s). Proyecto graduado en la CNCF
- Un **Helm chart** empaqueta todos los manifiestos YAML de una aplicacion en una unidad cohesiva con templates Go y valores separados
- Estructura basica de un chart: `Chart.yaml` (metadatos obligatorios), `values.yaml` (configuracion parametrizable), `templates/` (manifiestos Go-template)
- Los **valores** en `values.yaml` se inyectan en los templates al momento de instalar/actualizar, evitando duplicar configuracion en multiples archivos
- Cada `helm upgrade` crea una nueva **revision** del release, trazable con `helm history`
- **Helm trackea versiones** como Git: se puede hacer rollback a cualquier revision con un solo comando
- El release incluye `PodDisruptionBudget` para proteger disponibilidad durante actualizaciones

```bash
# Instalar una aplicacion desde un chart local
helm install guestbook ./guestbook

# Verificar pods del release
kubectl get pods -o wide

# Actualizar el release (nueva revision) con valores modificados
helm upgrade guestbook ./guestbook

# Actualizar con un archivo de valores alternativo
helm upgrade guestbook ./guestbook --values ./guestbook/values-v2.yaml

# Ver historial de revisiones del release
helm history guestbook

# Hacer rollback a una revision especifica
helm rollback guestbook 3

# Listar releases instalados
helm list

# Ver estado de un release
helm status guestbook

# Eliminar un release
helm uninstall guestbook
```

Ejemplo YAML: [values.yaml](./01/demos/maintaining-k8s-m1/demo1/guestbook/values.yaml)

---

## Alta Disponibilidad (HA)

Conceptos clave:
- **Replicas**: multiples copias de un Pod sirviendo el mismo trafico detras de un Service. Si uno crashea, los demas siguen activos
- **Pod Disruption Budget (PDB)**: recurso de Kubernetes que define el minimo de Pods que deben estar disponibles durante disrupciones **voluntarias** (drain de nodo, upgrade, scale down). Actua sobre la Eviction API
- **Disrupciones voluntarias** vs **involuntarias**: las voluntarias son controladas por el administrador (drain, upgrade). Las involuntarias son fallas de hardware o kernel
- **Pod Anti-Affinity**: regla de scheduling que le indica al scheduler que distribuya los Pods entre distintos nodos. Evita que todos los Pods queden en el mismo nodo
- La combinacion de Replicas + PDB + Anti-Affinity habilita **upgrades sin downtime**: al drenar un nodo, el PDB frena la eviccion hasta que se creen reemplazos
- Sin anti-affinity el scheduler puede colocar todos los Pods en un solo nodo, creando un **single point of failure**

```bash
# Ver Pod Disruption Budgets activos
kubectl get pdb

# Describir un PDB (minAvailable, maxUnavailable, replicas afectadas)
kubectl describe pdb guestbook-backend-pdb

# Verificar distribucion de pods entre nodos
kubectl get pods -o wide

# Ver anti-affinity configurada en un deployment
kubectl get deployment guestbook-frontend -o yaml | grep -A 10 affinity
```

Ejemplo YAML: [values.yaml](./01/demos/maintaining-k8s-m1/demo2/guestbook/values.yaml)

---

## Upgrade de Cluster Kubernetes

Conceptos clave:
- El orden de upgrade es **siempre**: Control Plane primero, luego worker nodes uno a la vez
- El Control Plane soporta worker nodes en versiones anteriores; nunca al reves
- **etcd** almacena todo el estado del cluster (Deployments, Services, ConfigMaps). Su backup previo al upgrade es obligatorio
- **kubeadm upgrade plan**: muestra el upgrade disponible y verifica compatibilidad antes de aplicar
- **kubeadm upgrade apply**: actualiza los componentes del control plane (apiserver, scheduler, controller-manager)
- **kubeadm upgrade node**: actualiza la configuracion de un worker node
- Los componentes `kubeadm`, `kubelet` y `kubectl` se gestionan con `apt-mark hold/unhold` para prevenir upgrades automaticos no planificados
- Durante el upgrade del control plane, los pods de aplicacion siguen corriendo porque los worker nodes no cambian
- Durante el upgrade de un worker: (1) cordon, (2) drain, (3) SSH y upgrade, (4) uncordon

```bash
# --- PRE-UPGRADE: Verificacion del cluster ---

# Verificar versiones actuales de todos los nodos
kubectl get nodes -o wide

# Verificar version del API server
kubectl version

# Verificar pods corriendo y su distribucion
kubectl get pods -o wide

# Verificar PodDisruptionBudgets en su lugar
kubectl get pdb

# --- BACKUP DE ETCD ---

# Hacer snapshot de etcd (ejecutar en el nodo control plane)
sudo etcdctl snapshot save /home/ubuntu/etcd-snapshot-pre-upgrade-1.33.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# --- UPGRADE DEL CONTROL PLANE ---

# Agregar el repositorio de la nueva version de Kubernetes
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes-v1.34.list

sudo apt-get update

# Ver versiones disponibles de kubeadm
apt-cache madison kubeadm

# Desbloquear kubeadm para actualizar
sudo apt-mark unhold kubeadm

# Instalar la nueva version de kubeadm
sudo apt-get install -y kubeadm=1.34.2-1.1

# Bloquear de nuevo para prevenir upgrades automaticos
sudo apt-mark hold kubeadm

# Previsualizar el plan de upgrade
sudo kubeadm upgrade plan

# Aplicar el upgrade al control plane
sudo kubeadm upgrade apply v1.34.2

# Actualizar kubelet y kubectl en el control plane
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.34.2-1.1 kubectl=1.34.2-1.1
sudo apt-mark hold kubelet kubectl

# Recargar systemd y reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verificar que el control plane muestra la nueva version
kubectl get nodes

# Verificar pods del sistema kube-system
kubectl get pods -n kube-system

# --- UPGRADE DE WORKER NODES (repetir para cada worker) ---

# 1. Marcar el nodo como no-schedulable
kubectl cordon k8s-worker-1

# 2. Drenar el nodo (mover pods a otros nodos)
kubectl drain k8s-worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=120s

# 3. Verificar que los pods se movieron
kubectl get pods -o wide

# 4. (SSH al worker) Agregar repo, actualizar kubeadm, aplicar upgrade de nodo
# sudo kubeadm upgrade node
# sudo apt-get install -y kubelet=1.34.2-1.1 kubectl=1.34.2-1.1
# sudo systemctl daemon-reload && sudo systemctl restart kubelet

# 5. Re-habilitar scheduling en el nodo
kubectl uncordon k8s-worker-1

# --- VERIFICACION FINAL ---

# Verificar todos los nodos en la nueva version
kubectl get nodes -o wide

# Verificar que la aplicacion sigue corriendo
kubectl get pods
kubectl get pods -o wide
```

Ejemplo: [upgrading-k8s-cluster.md](./01/demos/maintaining-k8s-m1/demo3/upgrading-k8s-cluster.md)

---

## Metrics Server

Conceptos clave:
- **Metrics Server** provee metricas basicas de CPU y memoria a nivel de nodo y pod via el API de Kubernetes (`metrics.k8s.io`)
- Es un requerimiento para `kubectl top` y para el **Horizontal Pod Autoscaler (HPA)**
- Solo guarda el **snapshot mas reciente** de metricas, sin persistencia historica
- Limitaciones: no apto para produccion como solucion de observabilidad completa; no tiene alertas ni dashboards
- Se instala tipicamente con el flag `--kubelet-insecure-tls` en entornos de desarrollo/lab

```bash
# Agregar el repositorio Helm de metrics-server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

helm repo update

# Instalar metrics-server en kube-system
helm install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set 'args[0]=--kubelet-insecure-tls'

# Verificar que el pod esta corriendo
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# Ver uso de CPU y memoria por nodo
kubectl top nodes

# Ver uso de CPU y memoria por pod
kubectl top pods

# Ver metricas de pods en un namespace especifico
kubectl top pods -n monitoring

# Ver pods ordenados por consumo de CPU
kubectl top pods --sort-by=cpu

# Ver pods ordenados por consumo de memoria
kubectl top pods --sort-by=memory
```

---

## Prometheus y Grafana

Conceptos clave:
- **Prometheus**: base de datos de series temporales open-source para metricas. Hace **scraping** (pull) de metricas de los targets automaticamente
- **PromQL**: lenguaje de consulta de Prometheus para analizar metricas con funciones como `rate()`, `histogram_quantile()`, `sum()`, `by()`
- **Alerting**: Prometheus evalua reglas definidas y dispara alertas cuando se superan umbrales (ej: CPU > 80% por 5 minutos)
- **Grafana**: plataforma de visualizacion que se conecta a Prometheus (y otras fuentes) para crear dashboards con graficas, gauges y tablas
- **kube-prometheus-stack**: chart de Helm que instala Prometheus, Grafana, Alertmanager y exporters de metricas en un solo paso
- **ServiceMonitor**: recurso CRD de Prometheus Operator que le indica a Prometheus que scrapeee las metricas de un Service especifico
- Niveles de metricas: **cluster** (salud global), **nodo** (CPU/memoria por servidor), **pod** (recursos por contenedor), **aplicacion** (metricas custom como request rate)
- Las **metricas custom de aplicacion** se exponen via `/metrics` en formato Prometheus (contadores, histogramas, gauges)

```bash
# Agregar repositorio de prometheus-community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

# Crear namespace de monitoreo
kubectl create namespace monitoring

# Instalar kube-prometheus-stack (Prometheus + Grafana + exporters)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Obtener password de Grafana
kubectl get secret --namespace monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode

# Port-forward a Grafana (usuario: admin)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Acceder en: http://localhost:3000

# Port-forward a Prometheus UI
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Acceder en: http://localhost:9090

# Verificar que los pods del stack estan corriendo
kubectl get pods -n monitoring

# Verificar ServiceMonitor creado para la aplicacion
kubectl get servicemonitor

# Describir un ServiceMonitor
kubectl describe servicemonitor guestbook-backend

# Port-forward al endpoint de metricas de la aplicacion
kubectl port-forward svc/guestbook-backend 5001:5000
# Ver metricas raw en: http://localhost:5001/metrics

# Upgrade de la aplicacion con metricas Prometheus habilitadas
helm upgrade guestbook ./guestbook
```

Ejemplos de PromQL:
```promql
# Tasa de requests por segundo (ventana de 1 minuto)
rate(guestbook_requests_total[1m])

# P95 de latencia en milisegundos
histogram_quantile(0.95, sum(rate(guestbook_request_duration_seconds_bucket[5m])) by (le)) * 1000

# Tasa de errores 5xx
sum(rate(guestbook_requests_total{status=~"5.."}[5m])) / sum(rate(guestbook_requests_total[5m])) * 100

# Porcentaje de pods de backend listos
(kube_deployment_status_replicas_ready{deployment=~".*backend.*"} / kube_deployment_spec_replicas{deployment=~".*backend.*"}) * 100
```

Ejemplo: [install-prometheus-grafana.md](./02/demos/maintaining-k8s-m2/demo5/install-prometheus-grafana.md)

---

## Logging Centralizado con Loki y Grafana Alloy

Conceptos clave:
- `kubectl logs` tiene limitaciones en produccion: solo un pod a la vez, los logs **desaparecen** cuando el pod crashea, sin busqueda cruzada, sin retencion
- **Loki**: sistema de agregacion de logs disenado por Grafana Labs. Almacena logs de todo el cluster con retencion configurable y permite busqueda cruzada con **LogQL**
- **Grafana Alloy**: DaemonSet que corre en **cada nodo** del cluster, recolecta los logs de todos los contenedores en ese nodo y los envia a Loki
- **Logging estructurado (JSON)**: en lugar de texto plano, los logs incluyen campos como `timestamp`, `level`, `event`, `pod`, facilitando el filtrado en Grafana
- **LogQL**: lenguaje de consulta de Loki para filtrar logs por namespace, pod, nivel, contenido del mensaje, etc.
- Integracion con Grafana: Loki se agrega como **data source** en Grafana para visualizar logs junto a metricas de Prometheus en el mismo dashboard
- Ventaja clave: al crashear un pod, los logs ya estan persistidos en Loki y no se pierden

```bash
# Agregar repositorio de Grafana
helm repo add grafana https://grafana.github.io/helm-charts

helm repo update

# Instalar Loki con valores custom
helm install loki grafana/loki \
  --namespace monitoring \
  --values monitoring/loki-values.yaml

# Instalar Grafana Alloy (recolector de logs)
helm install alloy grafana/alloy \
  --namespace monitoring \
  --values monitoring/alloy-values.yaml

# Verificar que Loki y Alloy estan corriendo
kubectl get pods -n monitoring

# Upgrade de la aplicacion con logging estructurado habilitado
helm upgrade guestbook ./guestbook

# Forzar rollout para que todos los pods usen la nueva configuracion
kubectl rollout restart deployment guestbook-backend
kubectl rollout restart deployment guestbook-frontend

# Verificar que los pods se reiniciaron correctamente
kubectl get pods

# Ver logs basicos de un pod (antes de Loki)
kubectl logs <pod-name>

# Ver logs del pod anterior (util si crasheo)
kubectl logs <pod-name> --previous

# Ver logs de todos los pods de un deployment
kubectl logs -l app=guestbook-backend --all-containers

# Seguir logs en tiempo real
kubectl logs -f <pod-name>
```

Ejemplos de LogQL en Grafana:
```logql
# Todos los logs del backend
{app="guestbook-backend"}

# Solo errores
{app="guestbook-backend"} |= "error"

# Evento especifico (button clicked)
{app="guestbook-backend"} |= "button_clicked"

# Logs por namespace
{namespace="default"} | json | level="error"
```

Ejemplo: [install-loki.md](./02/demos/maintaining-k8s-m2/demo6/install-loki.md)

---

## SLI, SLO, SLA y Chaos Engineering

Conceptos clave:
- **SLI (Service Level Indicator)**: metrica especifica que mide un aspecto de la confiabilidad. Tipos comunes: **Availability** (uptime / total time), **Latency** (percentil P95 de response time), **Error Rate** (errores / total requests)
- **SLO (Service Level Objective)**: objetivo interno de un SLI. Ej: disponibilidad >= 99.5%, P95 < 200ms, error rate < 0.5%. Son metas medibles, no aspiracionales
- **SLA (Service Level Agreement)**: contrato con el cliente que incluye consecuencias si se viola el SLO. Mas formal y legalmente vinculante que un SLO
- **Error Budget**: presupuesto de errores derivado del SLO. Si el SLO es 99.5%, el error budget es 0.5% (≈ 216 minutos/mes). Cuando se agota, se prioriza confiabilidad sobre velocidad de despliegue
- **Chaos Engineering**: practica de inyectar fallas deliberadas (latencia, errores HTTP 500, crashes de pods) para validar que el sistema de observabilidad detecta problemas en tiempo real
- Los modos de chaos son: **latency** (delays de 200-500ms), **errors** (HTTP 500), **crash** (exit 1 del proceso)
- Los dashboards de SLO en Grafana combinan metricas de Prometheus (SLIs) con visualizacion de error budget

```bash
# Habilitar chaos de latencia en la aplicacion
curl -X POST http://localhost:5000/api/chaos/enable \
  -H "Content-Type: application/json" \
  -d '{"mode": "latency", "intensity": 50}'

# Habilitar chaos de errores HTTP 500
curl -X POST http://localhost:5000/api/chaos/enable \
  -H "Content-Type: application/json" \
  -d '{"mode": "errors", "intensity": 30}'

# Habilitar chaos de crash de pods
curl -X POST http://localhost:5000/api/chaos/enable \
  -H "Content-Type: application/json" \
  -d '{"mode": "crash", "intensity": 100}'

# Verificar estado del chaos
curl http://localhost:5000/api/chaos/status

# Deshabilitar chaos
curl -X POST http://localhost:5000/api/chaos/disable

# Monitorear pods en tiempo real durante chaos de crash
kubectl get pods -w

# Ver reinicios de pods
kubectl get pods

# Importar dashboard de SLO en Grafana
# En Grafana: Dashboards > New > Import > seleccionar slo-dashboard.json
```

Ejemplo: [slo-definitions.md](./02/demos/maintaining-k8s-m2/demo7/slo/slo-definitions.md)

---

## Troubleshooting: Workflow General

Conceptos clave:
- El mismo flujo de 6 pasos aplica a **cualquier tipo de error** en Kubernetes: observe, describe, logs, events, fix, verify
- **Paso 1 - Observe**: `kubectl get pods` para identificar el sintoma y que pods estan afectados
- **Paso 2 - Describe**: `kubectl describe pod` para obtener el historial de eventos y estado detallado del pod
- **Paso 3 - Logs**: `kubectl logs` para ver que reporta la aplicacion. Usar `--previous` si el pod ya crasheo
- **Paso 4 - Events**: `kubectl get events` para ver mensajes de error del propio Kubernetes (scheduler, kubelet)
- **Paso 5 - Fix**: aplicar el cambio (actualizar manifiesto, corregir configuracion, ajustar recursos)
- **Paso 6 - Verify**: confirmar que los pods estan Running y la aplicacion responde correctamente
- La clave es ser **sistematico**: no saltar al fix sin entender primero el problema

```bash
# Paso 1: Ver estado de todos los pods
kubectl get pods
kubectl get pods -A  # todos los namespaces

# Paso 2: Obtener detalle de un pod especifico
kubectl describe pod <pod-name>

# Paso 3: Ver logs del pod
kubectl logs <pod-name>

# Ver logs del contenedor anterior (si crasheo)
kubectl logs <pod-name> --previous

# Paso 4: Ver eventos del cluster
kubectl get events
kubectl get events --sort-by='.lastTimestamp'

# Ver eventos de un namespace especifico
kubectl get events -n kube-system

# Paso 5: Aplicar el fix
kubectl apply -f <manifiesto-corregido>.yaml
helm upgrade <release> <chart> --values <valores-correctos>.yaml

# Paso 6: Verificar el fix
kubectl get pods
kubectl get pods -o wide
```

---

## Troubleshooting: CrashLoopBackOff

Conceptos clave:
- **CrashLoopBackOff** significa que el pod arranca, falla y Kubernetes lo reinicia repetidamente
- Kubernetes aplica **exponential backoff** entre reinicios (10s, 20s, 40s... hasta 5 min)
- Causas comunes: error de configuracion (variable de entorno erronea, secret incorrecto, endpoint que no existe), bug en la aplicacion, falta de recursos
- La clave esta en los **logs del contenedor anterior** (`--previous`): revelan el error exacto antes del crash
- El campo `Exit Code` en `kubectl describe pod` da pistas: `137` = OOMKilled, `1` = error de aplicacion, `0` = proceso termino normalmente
- Verificar siempre que los **servicios dependientes** (bases de datos, APIs externas) existen y tienen el nombre correcto

```bash
# Identificar pods en CrashLoopBackOff
kubectl get pods

# Obtener detalles del pod (restart count, exit code, eventos)
kubectl describe pod <pod-name>

# Ver logs del contenedor que acaba de crashear
kubectl logs <pod-name>

# Ver logs del contenedor ANTERIOR (el que crasheo)
kubectl logs <pod-name> --previous

# Verificar que los servicios dependientes existen
kubectl get services
kubectl get svc -A

# Verificar variables de entorno del pod
kubectl exec <pod-name> -- env | grep <VAR>

# Ver la configuracion del Helm values para detectar el error
helm get values <release-name>

# Fix: redeploy con valores correctos
helm upgrade guestbook ./guestbook --values ./guestbook/values.yaml

# Verificar recuperacion
kubectl get pods --watch
```

Ejemplo YAML de escenario: [3.2_crashloopbackoff-values.yaml](./03/demos/maintaining-k8s-m3/guestbook/scenarios/3.2_crashloopbackoff-values.yaml)

---

## Troubleshooting: ImagePullBackOff

Conceptos clave:
- **ImagePullBackOff** significa que Kubernetes no pudo descargar la imagen del contenedor
- Causas comunes: **tag incorrecto o inexistente**, nombre de imagen mal escrito, registry privado sin credenciales (`imagePullSecrets`), falta de acceso a red desde los nodos
- El comando `kubectl describe pod` muestra exactamente que imagen intento descargar y el error del registro
- Verificar siempre en el **registry publico** (Docker Hub, ECR, GCR) que la imagen y el tag existen
- En registros privados: verificar que el `ImagePullSecret` existe, tiene las credenciales correctas y esta referenciado en el pod/serviceaccount

```bash
# Identificar pods en ImagePullBackOff
kubectl get pods

# Ver que imagen esta intentando descargar y el error
kubectl describe pod <pod-name>

# Revisar la seccion "Events" del describe para ver el error exacto
# Buscar: Failed to pull image "..."

# Ver la imagen configurada en el Helm values
helm get values <release-name>

# Verificar imagenes de los pods en ejecucion
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Verificar ImagePullSecrets configurados
kubectl get secret
kubectl describe secret <pull-secret-name>

# Fix: redeploy con tag de imagen correcto
helm upgrade guestbook ./guestbook --values ./guestbook/values.yaml

# Verificar recuperacion
kubectl get pods
```

Ejemplo YAML de escenario: [3.3_imagepullbackoff-values.yaml](./03/demos/maintaining-k8s-m3/guestbook/scenarios/3.3_imagepullbackoff-values.yaml)

---

## Troubleshooting: Pending Pods

Conceptos clave:
- Un pod en estado **Pending** significa que el scheduler no pudo encontrar un nodo adecuado donde ejecutarlo
- Causas comunes: **recursos insuficientes** (CPU/memoria solicitada mayor a la disponible en cualquier nodo), **taints sin tolerations**, **nodeSelector/affinity** que no matchea ningun nodo, **PVC no disponible**
- La seccion `Events` de `kubectl describe pod` describe exactamente por que no pudo schedularse (ej: "0/3 nodes are available: 3 Insufficient cpu")
- `kubectl top nodes` muestra la capacidad restante en cada nodo
- `kubectl describe nodes` muestra los recursos totales, los requests actuales y la capacidad libre por nodo

```bash
# Identificar pods en Pending
kubectl get pods

# Ver el motivo de que el pod no puede schedularse
kubectl describe pod <pod-name>
# Buscar en "Events": "Insufficient cpu", "Insufficient memory", "no nodes available"

# Ver capacidad de CPU y memoria restante por nodo
kubectl top nodes

# Ver detalle de recursos por nodo (capacity, allocatable, requests actuales)
kubectl describe nodes

# Ver uso de CPU/memoria por nodo en detalle
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# Verificar taints de los nodos (pueden bloquear scheduling)
kubectl describe nodes | grep Taint

# Ver el request de recursos del pod
kubectl get pod <pod-name> -o yaml | grep -A 5 resources

# Verificar si hay PVCs pendientes (si el pod usa almacenamiento)
kubectl get pvc

# Fix: reducir los resource requests en el manifiesto o agregar nodos al cluster
helm upgrade guestbook ./guestbook --values ./guestbook/values.yaml

# Verificar recuperacion
kubectl get pods
```

Ejemplo YAML de escenario: [3.4_pending-values.yaml](./03/demos/maintaining-k8s-m3/guestbook/scenarios/3.4_pending-values.yaml)

---

## Troubleshooting: Networking

Conceptos clave:
- Los problemas de networking en Kubernetes frecuentemente son causados por **label selectors incorrectos** entre Services y Pods
- Un Service usa `selector` para determinar que Pods reciben el trafico. Si el selector no matchea ninguna label de los pods, el **Endpoint queda vacio**
- Los **Endpoints** son la lista de IPs de pods que reciben trafico del Service. Un endpoint vacio es el primer indicador de mismatch de selector
- `kubectl describe service` muestra el selector configurado y `kubectl get endpoints` muestra si hay pods detras del service
- Otros problemas comunes: **NetworkPolicy** que bloquea el trafico, **puerto incorrecto** en el Service o en el Pod, **Ingress** mal configurado

```bash
# Verificar pods corriendo (aunque los pods esten OK, la app puede fallar)
kubectl get pods

# Ver los endpoints del service (debe tener IPs de pods)
kubectl get endpoints

# Ver endpoints de un service especifico
kubectl get endpoints guestbook-backend

# Describir el service para ver su selector
kubectl describe service guestbook-backend
# Buscar: Selector: app=<nombre>

# Ver las labels de los pods del backend
kubectl get pods --show-labels
kubectl get pods -l app=guestbook-backend --show-labels

# Comparar selector del service vs labels del pod
kubectl get service guestbook-backend -o yaml | grep -A 5 selector
kubectl get pods -o yaml | grep -A 5 "labels:"

# Verificar NetworkPolicies activas
kubectl get networkpolicies -A

# Probar conectividad desde un pod a otro
kubectl exec -it <pod-name> -- curl http://guestbook-backend:5000/api/visits

# Ver los valores de Helm para detectar el selector incorrecto
helm get values guestbook

# Fix: redeploy con el selector correcto
helm upgrade guestbook ./guestbook --values ./guestbook/values.yaml

# Verificar recuperacion
kubectl get endpoints
kubectl get pods
```

Ejemplo YAML de escenario: [3.5_networking-values.yaml](./03/demos/maintaining-k8s-m3/guestbook/scenarios/3.5_networking-values.yaml)

---

## Troubleshooting: OOMKilled

Conceptos clave:
- **OOMKilled (Out Of Memory Killed)** significa que el contenedor supero su `memory limit` y el kernel lo termino con la senal SIGKILL (exit code `137`)
- Cuando ocurre OOMKill, el pod entra en **CrashLoopBackOff** porque no hay error de aplicacion sino un kill externo
- `kubectl describe pod` muestra el motivo exacto: `Reason: OOMKilled` y el `Exit Code: 137`
- Los logs pueden estar **vacios** porque el proceso fue terminado abruptamente por el kernel, no por la aplicacion
- La solucion es incrementar el `memory limit` del contenedor a un valor adecuado para la carga de trabajo
- Para determinar el limite adecuado: usar `kubectl top pods` durante carga normal para ver el consumo real

```bash
# Identificar pods con multiples reinicios (senal de OOMKill)
kubectl get pods

# Verificar si el estado es OOMKilled
kubectl describe pod <pod-name>
# Buscar en "Last State": Reason: OOMKilled, Exit Code: 137

# Ver los memory limits configurados para el pod
kubectl get pod <pod-name> -o yaml | grep -A 5 resources

# Verificar consumo real de memoria de los pods
kubectl top pods

# Ver consumo por contenedor
kubectl top pods --containers

# Verificar que los limits son suficientes vs el consumo observado
kubectl describe pod <pod-name> | grep -A 10 "Limits:"

# Los logs pueden estar vacios porque el kill fue abrupto
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Ver eventos del nodo relacionados con OOM
kubectl describe node <node-name> | grep -i oom

# Fix: incrementar memory limits en el manifiesto
helm upgrade guestbook ./guestbook --values ./guestbook/values.yaml

# Verificar recuperacion
kubectl get pods --watch
kubectl top pods
```

Ejemplo YAML de escenario: [3.6_oomkilled-values.yaml](./03/demos/maintaining-k8s-m3/guestbook/scenarios/3.6_oomkilled-values.yaml)
