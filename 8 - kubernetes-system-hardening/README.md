# Seccion 8 - Kubernetes System Hardening

Referencia de comandos y conceptos extraidos de la transcripcion del curso. Esta seccion cubre el hardening a nivel de plataforma: control plane, worker nodes y acceso al cluster.

## Indice

| Categoria | Modulo |
|-----------|--------|
| [Permisos de Archivos del Control Plane](#permisos-de-archivos-del-control-plane) | 01 |
| [Seguridad de etcd con mTLS](#seguridad-de-etcd-con-mtls) | 01 |
| [Hardening del API Server](#hardening-del-api-server) | 01 |
| [Restriccion de Acceso de Red al Control Plane](#restriccion-de-acceso-de-red-al-control-plane) | 01 |
| [Parametros del Kernel y Seguridad de Nodos](#parametros-del-kernel-y-seguridad-de-nodos) | 02 |
| [Limitacion de Privilegios del Kubelet (NodeRestriction)](#limitacion-de-privilegios-del-kubelet-noderestriction) | 02 |
| [Restriccion de Acceso Externo al Kubelet](#restriccion-de-acceso-externo-al-kubelet) | 02 |
| [Auditoria de ClusterRoles y RoleBindings](#auditoria-de-clusterroles-y-rolebindings) | 03 |
| [RoleBindings Restringidos y Least Privilege](#rolebindings-restringidos-y-least-privilege) | 03 |
| [Seguridad de Tokens de Service Accounts](#seguridad-de-tokens-de-service-accounts) | 03 |

---

## Permisos de Archivos del Control Plane

Conceptos clave:
- Los **static Pod manifests** definen componentes como API server, controller manager y scheduler. El kubelet los vigila directamente, asi que cualquier cambio afecta el control plane **sin pasar por el API Server**
- Los **kubeconfig files** representan identidad y autoridad. Si se exponen, un atacante obtiene acceso legitimo con credenciales validas
- Los **certificados y claves privadas** establecen la confianza dentro del cluster. Incluso acceso de solo lectura a una clave privada permite suplantacion de identidad
- El **CIS Kubernetes Benchmark** define ownership y permisos esperados: archivos criticos deben ser propiedad de **root**, escribibles solo donde sea absolutamente necesario
- Una configuracion segura es **least privilege aplicado a nivel de sistema de archivos**

```bash
# --- Auditar static Pod manifests ---
ls -l /etc/kubernetes/manifests/

# Corregir ownership (solo root)
chown root:root /etc/kubernetes/manifests/*.yaml

# Corregir permisos (solo root puede leer/escribir)
chmod 600 /etc/kubernetes/manifests/*.yaml

# --- Auditar kubeconfig files ---
ls -l /etc/kubernetes/*.conf

# Corregir ownership
chown root:root /etc/kubernetes/*.conf

# Corregir permisos
chmod 600 /etc/kubernetes/*.conf

# --- Auditar certificados y claves privadas ---
ls -l /etc/kubernetes/pki/

# Corregir ownership de claves privadas
chown root:root /etc/kubernetes/pki/*.key

# Corregir permisos de claves privadas (nunca world-readable)
chmod 600 /etc/kubernetes/pki/*.key
```

---

## Seguridad de etcd con mTLS

Conceptos clave:
- **etcd** es el source of truth del cluster. Si etcd se compromete, **todo el cluster se compromete**
- Acceso de lectura expone secretos y configuracion interna. Acceso de escritura significa **control total** del cluster
- etcd usa **mutual TLS (mTLS)** para toda comunicacion cliente y peer: ambos lados se autentican mutuamente antes de intercambiar datos
- mTLS garantiza: solo clientes autenticados conectan, los clientes verifican que hablan con el etcd correcto, y todo el trafico se cifra en transito
- El **directorio de datos de etcd** debe tener ownership del usuario etcd dedicado con permisos restringidos
- El CIS Benchmark define requisitos tanto para mTLS como para permisos del directorio de datos

```bash
# Obtener el nombre del Pod de etcd
kubectl get pods -n kube-system -l component=etcd

# Inspeccionar el manifiesto de etcd para verificar flags de TLS
# Buscar: --cert-file, --key-file, --trusted-ca-file, --peer-cert-file, --peer-key-file
cat /etc/kubernetes/manifests/etcd.yaml

# Exec en el contenedor de etcd (etcdctl esta disponible dentro del contenedor)
kubectl exec -it etcd-<NODE_NAME> -n kube-system -- sh

# Dentro del contenedor: verificar con certificados (debe retornar healthy)
etcdctl endpoint health \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar que acceso no autenticado es rechazado (debe fallar)
etcdctl endpoint health

# Salir del contenedor
exit

# --- Verificar permisos del directorio de datos de etcd ---
ls -ld /var/lib/etcd/

# Corregir ownership (solo root o etcd dedicado)
chown -R root:root /var/lib/etcd

# Corregir permisos (solo el owner puede acceder)
chmod 700 /var/lib/etcd
```

---

## Hardening del API Server

Conceptos clave:
- El **API Server** es el punto central de control: toda interaccion con el cluster pasa por el (kubectl, nodos, controllers)
- Un request pasa por: **Authentication** (quien es) -> **Authorization** (que puede hacer) -> **Admission Control** (es aceptable el request)
- El comportamiento del API Server se define por **flags de startup** en el static Pod manifest
- Por defecto, Kubernetes prioriza compatibilidad sobre seguridad. Los defaults pueden introducir riesgo silenciosamente
- Flags criticos: `--authorization-mode=Node,RBAC`, `--anonymous-auth=false`, `--tls-cert-file`, `--tls-private-key-file`, `--audit-log-path`, `--audit-policy-file`
- **Audit logging** proporciona un registro cronologico detallado de actividad: esencial para incident response, compliance y forensics

```bash
# Obtener el nombre del Pod del API Server
kubectl get pods -n kube-system -l component=kube-apiserver

# Verificar flags de seguridad del API Server
# Buscar: --authorization-mode=Node,RBAC, --anonymous-auth=false,
#         --tls-cert-file, --tls-private-key-file, --audit-log-path, --audit-policy-file
kubectl get pod kube-apiserver-<NODE_NAME> -n kube-system -o yaml | grep -E "\-\-authorization-mode|\-\-anonymous-auth|\-\-tls-cert-file|\-\-tls-private-key-file|\-\-audit-log-path|\-\-audit-policy-file|\-\-enable-admission-plugins"

# Simular request no autenticado (debe retornar "no" si RBAC esta activo)
kubectl auth can-i create pods --as=system:anonymous

# Verificar acceso autenticado
kubectl get pods
```

---

## Restriccion de Acceso de Red al Control Plane

Conceptos clave:
- **Conectividad equivale a oportunidad**: si un componente es alcanzable, puede ser atacado
- Los componentes a proteger: **API Server** (puerto 6443), **etcd**, **controller manager** y **scheduler**
- Las redes de Kubernetes son **flat** por defecto: comunicacion interna generalmente sin restricciones
- **Firewalls** operan a nivel de infraestructura (trafico a/desde nodos). **Network Policies** operan a nivel de cluster (trafico entre Pods)
- Ambos son complementarios: firewalls definen el perimetro, network policies limitan el **movimiento lateral** dentro del cluster
- El CIS Benchmark enfatiza que solo los paths requeridos deben existir; todo lo demas debe estar **explicitamente bloqueado**

```bash
# Identificar Pods del control plane (controller manager y scheduler)
kubectl get pods -n kube-system -l "component in (kube-controller-manager,kube-scheduler)"

# Ver puertos del controller manager
kubectl get pod kube-controller-manager-<NODE_NAME> -n kube-system -o yaml | grep -E "port|bind"

# Ver puertos del scheduler
kubectl get pod kube-scheduler-<NODE_NAME> -n kube-system -o yaml | grep -E "port|bind"

# --- Firewall rules (conceptual, para nodos reales) ---
# En produccion: permitir trafico al API Server (puerto 6443) solo desde control plane
# Bloquear acceso externo al controller manager (puerto 10257) y scheduler (puerto 10259)

# --- Crear network policy para restringir trafico entre Pods ---
# Crear archivo network-policy-restrict.yaml con editor (e.g. nano)
# Contenido: deny-all ingress para el namespace default
kubectl apply -f network-policy-restrict.yaml

# Verificar Pods disponibles y obtener IP de un Pod destino
kubectl get pods -o wide

# Lanzar pod temporal para probar que la network policy bloquea el trafico
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget --timeout=5 -qO- <TARGET_POD_IP>
# Si la network policy esta activa, la conexion debe fallar
```

---

## Parametros del Kernel y Seguridad de Nodos

Conceptos clave:
- Los **kernel parameters** (sysctl) controlan como el SO aplica aislamiento, scheduling y networking. Muchos defaults son permisivos
- En un entorno Kubernetes, parametros permisivos facilitan **container escapes**, **escalada de privilegios** y **ataques DoS**
- El CIS Benchmark define valores recomendados para worker nodes, enfocados en prevenir tecnicas comunes de ataque
- El mayor desafio es el **configuration drift**: los settings pueden cambiar por fixes manuales, updates del SO o automatizacion inconsistente
- El flag **`--protect-kernel-defaults`** del kubelet verifica que los kernel parameters criticos tengan valores seguros. Si un nodo esta mal configurado, el **kubelet se niega a iniciar** (fail-fast)
- El CIS Benchmark asume que los kernel parameters se **aplican**, no solo se documentan

```bash
# En Docker Desktop: exec al contenedor del control plane para acceder al entorno del nodo
docker exec -it <CONTAINER_NAME> bash

# Auditar kernel parameters de red (read-only)
# Valores seguros esperados (CIS):
#   net.ipv4.ip_forward = 1 (requerido por Kubernetes)
#   net.ipv4.conf.all.send_redirects = 0
#   net.ipv4.conf.all.accept_redirects = 0
sysctl net.ipv4.ip_forward
sysctl net.ipv4.conf.all.send_redirects
sysctl net.ipv4.conf.all.accept_redirects

# Snapshot de la configuracion actual del kernel
sysctl -a | grep -E "ip_forward|send_redirects|accept_redirects"

# Inspeccionar flags de inicio del kubelet
# Buscar el flag: --protect-kernel-defaults=true
ps aux | grep kubelet

# --- En produccion: habilitar protect-kernel-defaults ---
# En /var/lib/kubelet/config.yaml agregar:
#   protectKernelDefaults: true
# Reiniciar el kubelet:
systemctl restart kubelet
```

---

## Limitacion de Privilegios del Kubelet (NodeRestriction)

Conceptos clave:
- El kubelet se autentica ante el API Server como un actor **altamente confiable** representando un nodo
- Si esa confianza es demasiado amplia, un nodo comprometido puede escalar de acceso a nivel de nodo a **impacto a nivel de cluster**
- El **NodeRestriction admission controller** aplica reglas estrictas sobre lo que un nodo puede hacer: actualizar su propio objeto Node, reportar status, leer Pods asignados a el
- Con NodeRestriction, un nodo **no puede**: modificar otros nodos, acceder a Pods no relacionados, cambiar recursos cluster-wide, ni leer secretos no relacionados
- Esto reduce significativamente el **blast radius** de un worker node comprometido
- El CIS Benchmark recomienda explicitamente habilitar NodeRestriction

```bash
# Verificar admission controllers habilitados
kubectl get pod kube-apiserver-<NODE_NAME> -n kube-system -o yaml | grep enable-admission-plugins

# --- Habilitar NodeRestriction (si no esta activo) ---
# Editar el manifiesto del API Server y agregar NodeRestriction al flag:
#   --enable-admission-plugins=NodeRestriction
# El API Server se reinicia automaticamente al guardar
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Verificar que el admission controller esta activo despues del reinicio
kubectl get pod kube-apiserver-<NODE_NAME> -n kube-system -o yaml | grep enable-admission-plugins

# Verificar nodos disponibles
kubectl get nodes

# Demostrar que un nodo puede labelarse a si mismo (accion permitida por NodeRestriction)
kubectl label node <NODE_NAME> test-label=hardening-demo

# Verificar el label
kubectl get node <NODE_NAME> --show-labels | grep test-label

# Limpiar el label de prueba
kubectl label node <NODE_NAME> test-label-
```

---

## Restriccion de Acceso Externo al Kubelet

Conceptos clave:
- El kubelet expone una **API en cada nodo** (puerto 10250 HTTPS) para gestionar Pods, metricas y operaciones administrativas
- Un atacante que alcance la Kubelet API podria listar, eliminar o manipular Pods o **escalar privilegios al host**
- El CIS Benchmark recomienda: binding del kubelet a localhost o interfaz interna, uso de firewall rules, y habilitacion de autenticacion
- Flags criticos del kubelet: `--anonymous-auth=false`, `--authentication-token-webhook=true`, `--authorization-mode=Webhook`
- Incluso endpoints basicos como health checks deben estar protegidos

```bash
# En Docker Desktop: exec al contenedor del control plane
docker exec -it <CONTAINER_NAME> bash

# Intentar acceder a la Kubelet API sin credenciales (debe retornar Unauthorized)
curl -sk https://localhost:10250/pods
curl -sk https://localhost:10250/healthz

# Inspeccionar flags de seguridad del kubelet
# Buscar: --anonymous-auth=false, --authentication-token-webhook=true, --authorization-mode=Webhook
ps aux | grep kubelet

# --- En produccion: configurar kubelet seguro ---
# Editar /var/lib/kubelet/config.yaml:
#   authentication:
#     anonymous:
#       enabled: false
#     webhook:
#       enabled: true
#   authorization:
#     mode: Webhook
# Reiniciar kubelet:
systemctl restart kubelet
```

---

## Auditoria de ClusterRoles y RoleBindings

Conceptos clave:
- **RBAC** define quien puede hacer que en el cluster: **Roles/ClusterRoles** definen acciones, **RoleBindings/ClusterRoleBindings** asignan permisos a usuarios/grupos/service accounts
- Con el tiempo, los roles acumulan demasiados permisos y los bindings se aplican demasiado ampliamente
- Red flags en una auditoria RBAC: asignar **cluster-admin** sin justificacion, roles con **wildcards** (`*`) en verbs o resources, service accounts con privilegios excesivos
- El CIS Benchmark enfatiza: auditar roles y bindings regularmente, evitar cluster-admin o wildcards salvo que sea estrictamente necesario, scoping de service accounts a sus workloads

```bash
# Listar todos los ClusterRoles
kubectl get clusterroles

# Inspeccionar cluster-admin (ejemplo de permisos excesivos)
# Permite TODAS las acciones en TODOS los recursos del cluster
kubectl describe clusterrole cluster-admin

# Listar ClusterRoleBindings
kubectl get clusterrolebindings

# Inspeccionar quien tiene cluster-admin
# Si esta bound a un service account o grupo amplio = riesgo de escalada
kubectl describe clusterrolebinding cluster-admin

# Revisar RoleBindings a nivel de namespace
kubectl get rolebindings -A
```

---

## RoleBindings Restringidos y Least Privilege

Conceptos clave:
- Despues de auditar RBAC, el siguiente paso es aplicar **least privilege** con role bindings restringidos
- Los **roles a nivel de namespace** restringen acciones a un solo namespace, previniendo modificaciones fuera del scope asignado
- Cada workload debe tener un **service account dedicado** con solo los permisos que necesita
- El CIS Benchmark recomienda: limitar role bindings al scope minimo necesario, evitar cluster-wide privileges innecesarios, crear service accounts dedicados por workload

```bash
# Crear namespace aislado
kubectl create namespace rbac-demo

# Crear role de solo lectura para Pods (namespace-scoped)
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n rbac-demo

# Crear service account dedicado
kubectl create serviceaccount pod-reader-sa -n rbac-demo

# Crear RoleBinding: conectar service account al role (solo dentro del namespace)
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=rbac-demo:pod-reader-sa \
  -n rbac-demo

# Verificar permisos del service account
# Puede listar pods en su namespace (debe retornar "yes")
kubectl auth can-i list pods -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa

# No puede hacer acciones destructivas (debe retornar "no")
kubectl auth can-i delete pods -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa

# No tiene visibilidad fuera de su namespace (debe retornar "no")
kubectl auth can-i list pods -n default \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa

# Limpiar
kubectl delete namespace rbac-demo
```

---

## Seguridad de Tokens de Service Accounts

Conceptos clave:
- Cada Pod recibe un **service account token** para autenticarse con el API de Kubernetes. Si el token es over-permissive o se expone, un Pod comprometido accede a recursos fuera de su scope
- Por defecto, **todo Pod recibe un token** incluso si no necesita acceso al API. Limitar el montaje de tokens reduce el riesgo
- Los **tokens de larga duracion** aumentan la ventana de oportunidad para atacantes. Kubernetes puede **rotar tokens automaticamente** para workloads de larga duracion
- El CIS Benchmark recomienda: deshabilitar automount del token por defecto, limitar permisos del token al minimo, y aplicar rotacion con lifetimes acotados

```bash
# Crear namespace aislado
kubectl create namespace sa-token-demo

# Crear service account con automount deshabilitado
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted-sa
  namespace: sa-token-demo
automountServiceAccountToken: false
EOF

# Desplegar Pod SIN token de service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: no-token-pod
  namespace: sa-token-demo
spec:
  serviceAccountName: restricted-sa
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
EOF

# Verificar que NO hay token montado (debe fallar: directorio no existe)
kubectl exec -n sa-token-demo no-token-pod -- ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>&1

# Desplegar Pod CON token explicitamente habilitado
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: with-token-pod
  namespace: sa-token-demo
spec:
  serviceAccountName: restricted-sa
  automountServiceAccountToken: true
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
EOF

# Verificar que el token SI esta presente
# Debe mostrar: ca.crt, namespace, token
kubectl exec -n sa-token-demo with-token-pod -- ls /var/run/secrets/kubernetes.io/serviceaccount/

# Limpiar
kubectl delete namespace sa-token-demo
```
