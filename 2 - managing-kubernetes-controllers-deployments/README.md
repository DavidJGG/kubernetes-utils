# Controllers y Deployments

Comandos para gestionar controllers, deployments, replicasets, daemonsets, jobs y cronjobs.

## Indice

- [Deployments](#deployments)
- [ReplicaSets](#replicasets)
- [Rollouts y Rollbacks](#rollouts-y-rollbacks)
- [Scaling](#scaling)
- [DaemonSets](#daemonsets)
- [Jobs](#jobs)
- [CronJobs](#cronjobs)

---

## Deployments

```bash
# Crear deployment imperativamente
kubectl create deployment hello-world --image=hello-app:1.0

# Crear deployment con replicas
kubectl create deployment hello-world --image=hello-app:1.0 --replicas=5

# Crear deployment declarativamente
kubectl apply -f deployment.yaml

# Ver estado del deployment
kubectl get deployments hello-world
kubectl get deployment

# Describir deployment (replicas, conditions, events)
kubectl describe deployment hello-world
kubectl describe deployment

# Ver pods del deployment
kubectl get pods
kubectl describe pods | head -n 20

# Eliminar deployment
kubectl delete deployment hello-world
kubectl delete -f deployment.yaml

# Ver pods del sistema
kubectl get --namespace kube-system all
kubectl get --namespace kube-system deployments coredns
kubectl get --namespace kube-system daemonset
```

Ejemplo YAML: [deployment.yaml](./02/demos/deployment.yaml), [deployment-me.yaml](./02/demos/deployment-me.yaml)

---

## ReplicaSets

```bash
# Ver replicasets
kubectl get replicasets
kubectl get replicaset

# Describir replicaset (selector, labels, pod template)
kubectl describe replicaset hello-world
kubectl describe ReplicaSets

# Ver pods controlados por un replicaset
kubectl get pods --show-labels
kubectl describe pods | head -n 20

# Aislar un pod del replicaset (cambiar label)
kubectl label pod <POD_NAME> app=DEBUG --overwrite
# El replicaset crea un nuevo pod para mantener el numero deseado
kubectl get pods --show-labels

# Retomar un pod aislado (reasignar label original)
kubectl label pod <POD_NAME> app=hello-world-pod-me --overwrite
# Un pod sera terminado para mantener el numero deseado
kubectl get pods --show-labels
```

### Fallo de nodo

```bash
# Monitorear nodos
kubectl get nodes --watch

# Ver pods y en que nodo estan
kubectl get pods -o wide
kubectl get pods -o wide --watch

# Pods en nodo caido: Kubernetes espera ~5min (pod-eviction-timeout) antes de reschedulear
kubectl get pods --watch
```

Ejemplo YAML: [ReplicaSet.yaml](./02/demos/ReplicaSet.yaml), [ReplicaSet-matchExpressions.yaml](./02/demos/ReplicaSet-matchExpressions.yaml)

---

## Rollouts y Rollbacks

```bash
# Aplicar nueva version
kubectl apply -f deployment.v2.yaml

# Ver estado del rollout
kubectl rollout status deployment hello-world

# Codigo de retorno: 0 = completado, 1 = fallido
echo $?

# Historial de rollout
kubectl rollout history deployment hello-world

# Ver detalle de una revision especifica
kubectl rollout history deployment hello-world --revision=2
kubectl rollout history deployment hello-world --revision=3

# Rollback a una revision especifica
kubectl rollout undo deployment hello-world --to-revision=2

# Reiniciar deployment (crea nuevo replicaset con nuevos pods)
kubectl rollout restart deployment hello-world

# Aplicar deployment con --record para anotar change-cause
kubectl apply -f deployment.yaml --record
```

### Rollout fallido

```bash
# Aplicar imagen incorrecta
kubectl apply -f deployment.broken.yaml

# El rollout se queda en progreso (respeta maxUnavailable)
kubectl rollout status deployment hello-world

# Ver estado: ImagePullBackoff/ErrImagePull
kubectl get pods

# Ver maxUnavailable, maxSurge, OldReplicaSet, NewReplicaSet
kubectl describe deployments hello-world

# Rollback
kubectl rollout undo deployment hello-world --to-revision=2
```

Conceptos clave:
- `maxUnavailable`: pods que pueden estar offline durante el update (default 25%)
- `maxSurge`: pods adicionales permitidos sobre el deseado (default 25%)
- `progressDeadlineSeconds`: tiempo antes de marcar como fallido (default 10min)

Ejemplo YAML: [deployment.yaml](./03/demos/deployment.yaml), [deployment.v2.yaml](./03/demos/deployment.v2.yaml), [deployment.probes-1.yaml](./03/demos/deployment.probes-1.yaml)

---

## Scaling

```bash
# Escalar imperativamente
kubectl scale deployment hello-world --replicas=10

# Verificar estado
kubectl get deployment hello-world

# Escalar declarativamente (modificar replicas en YAML)
kubectl apply -f deployment.20replicas.yaml

# Ver eventos de scaling
kubectl describe deployment
```

Ejemplo YAML: [deployment.20replicas.yaml](./03/demos/deployment.20replicas.yaml)

---

## DaemonSets

Ejecutan un pod en cada nodo del cluster (excepto control plane por defecto).

```bash
# Ver daemonsets del sistema
kubectl get daemonsets --namespace kube-system
kubectl get daemonsets --namespace kube-system kube-proxy

# Crear daemonset
kubectl apply -f DaemonSet.yaml

# Ver estado del daemonset
kubectl get daemonsets
kubectl get daemonsets -o wide
kubectl describe daemonsets hello-world-ds | more

# Ver labels de pods del daemonset
kubectl get pods --show-labels

# Cambiar label de un pod (el daemonset crea uno nuevo)
kubectl label pods $MYPOD app=not-hello-world --overwrite

# Eliminar daemonset
kubectl delete daemonsets hello-world-ds
```

### DaemonSet con nodeSelector

```bash
# Crear daemonset con nodeSelector
kubectl apply -f DaemonSetWithNodeSelector.yaml

# No se crean pods hasta que un nodo tenga el label requerido
kubectl get daemonsets

# Agregar label al nodo
kubectl label node c1-node1 node=hello-world-ns
kubectl get daemonsets -o wide

# Remover label: el pod se termina
kubectl label node c1-node1 node-
```

### Actualizar DaemonSet

```bash
# Actualizar imagen del daemonset
kubectl apply -f DaemonSet-v2.yaml

# Ver estado del rollout (mas lento que deployments por maxUnavailable)
kubectl rollout status daemonsets hello-world-ds

# Ver update strategy
kubectl get DaemonSet hello-world-ds -o yaml | more
```

Ejemplo YAML: [DaemonSet.yaml](./04/demos/DaemonSet.yaml), [DaemonSetWithNodeSelector.yaml](./04/demos/DaemonSetWithNodeSelector.yaml), [DaemonSet-v2.yaml](./04/demos/DaemonSet-v2.yaml)

---

## Jobs

Ejecutan tareas hasta completarse. Requieren `restartPolicy: OnFailure` o `Never`.

```bash
# Crear job
kubectl apply -f job.yaml

# Ver estado del job
kubectl get job --watch

# Ver pods del job (status Completed)
kubectl get pods
kubectl get pods -l job-name=hello-world-job

# Describir job (Start Time, Duration, Pod Statuses)
kubectl describe job hello-world-job

# Logs del pod del job
kubectl logs <POD_NAME>

# Eliminar job (y sus pods)
kubectl delete job hello-world-job
```

### Job con fallos

```bash
# Job con backoffLimit y restartPolicy: Never
kubectl apply -f job-failure-OnFailure.yaml

# Los pods no se eliminan para poder inspeccionar
kubectl get pods --watch
kubectl get jobs
kubectl describe jobs | more
```

### Job en paralelo

```bash
# Ejecutar job con paralelismo
kubectl apply -f ParallelJob.yaml

# Monitorear completions
watch 'kubectl describe job | head -n 11'
kubectl get jobs
```

Ejemplo YAML: [job.yaml](./04/demos/job.yaml), [ParallelJob.yaml](./04/demos/ParallelJob.yaml), [job-failure-OnFailure.yaml](./04/demos/job-failure-OnFailure.yaml)

---

## CronJobs

```bash
# Crear cronjob
kubectl apply -f CronJob.yaml

# Ver cronjobs (schedule, last schedule)
kubectl get cronjobs

# Describir (schedule, concurrency, suspend, history)
kubectl describe cronjobs | more

# Ver configuracion completa (successfulJobsHistoryLimit, etc.)
kubectl get cronjobs -o yaml

# Ver pods generados por el cronjob
kubectl get pods --watch

# Eliminar cronjob (y sus pods)
kubectl delete cronjob hello-world-cron
```

Ejemplo YAML: [CronJob.yaml](./04/demos/CronJob.yaml)
