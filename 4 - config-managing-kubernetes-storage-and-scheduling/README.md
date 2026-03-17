# Seccion 4 - Storage y Scheduling

Referencia de comandos `kubectl` para configuracion de almacenamiento persistente y scheduling avanzado de pods.

[Volver al README principal](../README.md)

## Indice

| Categoria | Modulo |
|-----------|--------|
| [PersistentVolumes y PersistentVolumeClaims](#persistentvolumes-y-persistentvolumeclaims) | 1 |
| [StorageClasses y Dynamic Provisioning](#storageclasses-y-dynamic-provisioning) | 1 |
| [Taints y Tolerations](#taints-y-tolerations) | 2 |
| [Node/Pod Affinity y Resource Limits](#nodepod-affinity-y-resource-limits) | 2 |
| [Pod Disruption Budgets](#pod-disruption-budgets) | 3 |
| [Topology Spread Constraints](#topology-spread-constraints) | 3 |

---

## PersistentVolumes y PersistentVolumeClaims

Conceptos clave:
- Los contenedores son **efimeros por defecto**: cualquier dato escrito en el sistema de archivos del contenedor desaparece al reiniciar o reemplazar el Pod
- Un **PersistentVolume (PV)** representa una pieza de almacenamiento en el cluster, provisionada por un admin o dinamicamente por una StorageClass
- Un **PersistentVolumeClaim (PVC)** es la solicitud de almacenamiento por parte de un workload — Kubernetes actua como "matchmaker" entre PVC y PV
- El campo `accessModes` define como se puede montar el volumen: `ReadWriteOnce` (un solo nodo), `ReadOnlyMany`, `ReadWriteMany`
- La `storageClassName` vincula el PV con la StorageClass que lo gestiona
- Una vez que el PVC queda en estado `Bound`, cualquier Pod que lo referencie tendra acceso al almacenamiento persistente incluso si el Pod es eliminado y recreado

```bash
# Crear PersistentVolume y PersistentVolumeClaim
kubectl apply -f pv-demo.yaml
kubectl apply -f pvc-demo.yaml

# Verificar estado del PVC (debe estar en Bound)
kubectl get pvc

# Crear el pod que consume el PVC
kubectl apply -f pod-demo.yaml

# Ver estado del pod
kubectl get pods

# Ejecutar shell dentro del pod para verificar el almacenamiento
kubectl exec -it pod-demo -- sh

# Verificar que el archivo persiste despues de eliminar y recrear el pod
kubectl delete pod pod-demo
kubectl apply -f pod-demo.yaml
kubectl exec -it pod-demo -- cat /data/test.txt
```

---

## StorageClasses y Dynamic Provisioning

Conceptos clave:
- Una **StorageClass** actua como una "receta" para el almacenamiento: define el provisioner, parametros de disco y politica de ciclo de vida
- El campo `provisioner` indica quien crea el almacenamiento (ej: `ebs.csi.aws.com`, `csi.vsphere.vmware.com`). Para entornos locales sin backend externo se usa `kubernetes.io/no-provisioner`
- `volumeBindingMode: Immediate` enlaza el volumen en cuanto se crea el PVC
- `reclaimPolicy: Delete` elimina el PV cuando el PVC es eliminado — util en dev/test. En produccion se prefiere `Retain` para evitar perdida accidental de datos
- El **provisionamiento dinamico** elimina la necesidad de que los admins creen PVs manualmente: Kubernetes crea el volumen correcto en el momento en que se solicita

```bash
# Crear la StorageClass
kubectl apply -f storageclass.yaml

# Ver StorageClasses disponibles
kubectl get sc

# Crear el PVC que referencia la StorageClass
kubectl apply -f pvc.yaml

# Verificar que el PVC quedo Bound
kubectl get pvc

# Desplegar un pod que use el PVC
kubectl apply -f pod.yaml

# Ver el pod corriendo
kubectl get pods

# Verificar almacenamiento dentro del pod
kubectl exec -it demo-pod -- sh
```

---

## Taints y Tolerations

Conceptos clave:
- Un **taint** marca un nodo con una condicion que impide que pods ordinarios sean programados en el: `key=value:Effect`
- Los efectos disponibles son: `NoSchedule` (no programar), `PreferNoSchedule` (evitar si es posible), `NoExecute` (tampoco ejecutar pods ya corriendo)
- Una **toleration** en la spec del Pod es la "llave" que le permite al pod ignorar ese taint y ser programado en el nodo
- Una toleration solo **permite** el scheduling en el nodo taintado, pero no lo **fuerza** — para forzarlo se combina con un `nodeSelector`
- Combinacion recomendada: taint + toleration + nodeSelector para aislar workloads en nodos dedicados (analytics, GPU, produccion, etc.)

```bash
# Verificar nodos del cluster
kubectl get nodes

# Aplicar taint a un nodo
kubectl taint nodes desktop-worker dedicated=analytics:NoSchedule

# Verificar que el taint fue aplicado
kubectl describe node desktop-worker | grep Taints

# Agregar label al nodo para que coincida con el nodeSelector del pod
kubectl label node desktop-worker dedicated=analytics

# Desplegar pod con toleration y nodeSelector
kubectl apply -f analytics-pod.yaml

# Verificar en que nodo fue programado
kubectl get pods -o wide

# Desplegar pod sin toleration (sera rechazado por el nodo taintado)
kubectl apply -f regular-pod.yaml
kubectl get pods -o wide

# Eliminar el taint de un nodo (agregar - al final)
kubectl taint nodes desktop-worker dedicated=analytics:NoSchedule-
```

---

## Node/Pod Affinity y Resource Limits

Conceptos clave:
- **Node affinity** guia al scheduler hacia nodos con labels especificos. `requiredDuringSchedulingIgnoredDuringExecution` es obligatoria; `preferredDuringSchedulingIgnoredDuringExecution` es opcional
- **Pod affinity** coloca pods cerca de otros pods con ciertos labels (misma topologia). Util para co-locacion de sidecars, caches locales, o agentes de monitoreo
- **Pod anti-affinity** fuerza que replicas del mismo servicio queden en nodos distintos, mejorando la tolerancia a fallos
- Los **resource requests** le dicen al scheduler cuanto CPU/memoria necesita el pod como minimo para ser programado en un nodo
- Los **resource limits** definen el maximo que un contenedor puede consumir — si supera el limite de CPU sera throttled, si supera el de memoria sera terminado (OOMKill)
- Sin requests/limits, Kubernetes asume recursos casi nulos y puede sobrecargar un nodo

```bash
# Etiquetar nodos para usarlos con affinity rules
kubectl label node desktop-worker role=analytics
kubectl label node desktop-worker2 role=web

# Desplegar pod con node affinity y resource limits
kubectl apply -f analytics-affinity-pod.yaml

# Verificar en que nodo fue programado
kubectl get pods -o wide

# Desplegar pod con pod affinity (sidecar junto al frontend)
kubectl apply -f frontend-sidecar.yaml

# Verificar co-locacion en el mismo nodo
kubectl get pods -o wide
```

---

## Pod Disruption Budgets

Conceptos clave:
- Un **Pod Disruption Budget (PDB)** define cuantos pods de un deployment pueden ser interrumpidos simultaneamente durante disrupciones voluntarias (drains, upgrades, rollouts)
- `minAvailable: N` garantiza que al menos N pods permanezcan corriendo en todo momento
- `maxUnavailable: N` es equivalente pero expresado como cuantos pueden estar caidos
- Solo aplica a **disrupciones voluntarias** (kubectl drain, rolling updates). Las involuntarias (fallo de nodo) no son controladas por el PDB
- Si una operacion de drain violaria el PDB, Kubernetes la bloquea hasta que haya suficientes pods disponibles

```bash
# Desplegar aplicacion con multiples replicas
kubectl apply -f webapp-deployment.yaml

# Ver pods del deployment
kubectl get pods -l app=webapp

# Crear el PDB con minAvailable
kubectl apply -f webapp-pdb.yaml

# Ver el PDB y las disrupciones permitidas
kubectl get pdb
kubectl describe pdb webapp-pdb

# Simular drain de un nodo (respeta el PDB)
kubectl drain desktop-worker --ignore-daemonsets --delete-emptydir-data

# Volver a poner el nodo en servicio
kubectl uncordon desktop-worker

# Intentar drain que violaría el PDB (sera bloqueado)
kubectl drain desktop-worker2 --ignore-daemonsets --delete-emptydir-data
```

---

## Topology Spread Constraints

Conceptos clave:
- Las **topology spread constraints** distribuyen pods uniformemente entre zonas, nodos u otros dominios de fallo, aumentando la tolerancia a fallos
- `maxSkew: N` limita la diferencia maxima en numero de pods entre nodos. Con `maxSkew: 1`, ningun nodo puede tener mas de 1 pod extra que otro
- `topologyKey` define el dominio de distribucion: `kubernetes.io/hostname` (por nodo), o labels de zona como `topology.kubernetes.io/zone`
- `whenUnsatisfiable: DoNotSchedule` bloquea el scheduling si no puede cumplir la restriccion. `ScheduleAnyway` la relaja
- Combinando topology spread constraints + PDB se garantiza **alta disponibilidad y distribucion balanceada** simultaneamente

```bash
# Ver nodos disponibles antes de aplicar la restriccion
kubectl get nodes

# Desplegar con topology spread constraints
kubectl apply -f topology-demo.yaml

# Verificar distribucion de pods entre nodos
kubectl get pods -o wide -l app=topology-demo

# Desplegar combinando topology spread + PDB
kubectl apply -f topology-pdb-demo.yaml
kubectl apply -f topology-pdb-demo-pdb.yaml

# Verificar distribucion
kubectl get pods -o wide

# Simular disruption (sera bloqueada si viola el PDB)
kubectl drain desktop-worker --ignore-daemonsets --delete-emptydir-data

# Restaurar el nodo
kubectl uncordon desktop-worker
```
