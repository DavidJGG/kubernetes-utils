# API de Kubernetes

Guías de referencia sobre la API de Kubernetes, descubrimiento de recursos, versionado y comunicación HTTP.

---

## 📑 Contenido

### Guías

1. **[Objetos de API y Descubrimiento](./1-APIObjects.md)**
   - `kubectl api-resources` - Listar recursos disponibles
   - `kubectl explain` - Explorar estructura de recursos
   - `--dry-run` - Validación de manifiestos
   - Generación automática de YAML
   - `kubectl diff` - Comparar cambios

2. **[Versiones de Objetos API](./2-APIObjectVersions.md)**
   - Sistema de versionado (alpha, beta, stable)
   - API Groups y organización
   - Migración entre versiones
   - Políticas de deprecación

3. **[Anatomía de Requests API](./3-AnatomyApiRequest.md)**
   - Comunicación HTTP con API Server
   - Verbos HTTP y códigos de respuesta
   - Niveles de verbosity (`-v` flag)
   - `kubectl proxy` para acceso directo
   - Watch requests y streaming

---

## 📂 Archivos

### Scripts Shell
- `1-APIObjects.sh` - Comandos de descubrimiento de API
- `2-APIObjectVersions.sh` - Exploración de versiones
- `3-AnatomyApiRequest.sh` - Análisis de requests HTTP

### Manifiestos YAML
- `pod.yaml` - Pod simple
- `deployment.yaml` - Deployment básico
- `deployment-new.yaml` - Deployment con cambios
- `deployment-error.yaml` - Deployment con error intencional
- `deployment-generated.yaml` - YAML generado automáticamente

### Material Complementario
- `using-the-kubernetes-api-slides.pdf` - Presentación del tema

---

## 🔑 Comandos Principales

```bash
# Descubrimiento
kubectl api-resources
kubectl api-versions
kubectl explain <recurso>

# Validación
kubectl apply --dry-run=server -f <archivo>
kubectl diff -f <archivo>

# Generación
kubectl create <recurso> --dry-run=client -o yaml

# Debugging
kubectl -v 6 <comando>
kubectl proxy
```

---

## 🔗 Enlaces

- [Documentación oficial de Kubernetes API](https://kubernetes.io/docs/reference/using-api/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

