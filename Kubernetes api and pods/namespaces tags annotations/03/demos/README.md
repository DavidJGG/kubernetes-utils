# Módulo 03: Namespaces, Labels y Annotations

## 📖 Descripción

Este módulo cubre la organización y gestión de recursos en Kubernetes usando namespaces para aislamiento lógico, y labels/selectors para identificación y filtrado de objetos.

## 🎯 Objetivos del Módulo

- Implementar multi-tenancy con namespaces
- Organizar recursos con labels y selectors
- Entender cómo Deployments y Services usan labels
- Programar Pods en nodos específicos con node selection

## 📚 Prerequisitos

- Módulo 02 completado
- Cluster de Kubernetes funcional
- Conocimientos de Pods y Deployments

## 📑 Contenido del Módulo

### Guías de Aprendizaje

1. **[Namespaces](./1-namespaces.md)**
   - Creación y gestión de namespaces
   - Recursos namespaced vs cluster-scoped
   - Estrategias de organización multi-tenant

2. **[Labels y Selectors](./2-labels.md)**
   - Creación y gestión de labels
   - Queries con selectors (equality y set-based)
   - Labels en Deployments, Services y ReplicaSets
   - Node selection con labels

### Archivos de Demostración

#### Scripts Shell
- `1-namespaces.sh` - Gestión de namespaces
- `2-labels.sh` - Labels, selectors y node selection

#### Manifiestos YAML
- `namespace.yaml` - Namespace declarativo
- `deployment.yaml` - Deployment con namespace
- `CreatePodsWithLabels.yaml` - Pods con diferentes labels
- `PodsToNodes.yaml` - Pods con nodeSelector
- `service.yaml` - Service con selector
- `deployment-label.yaml` - Deployment para demos de labels

## 🚀 Orden de Estudio Recomendado

1. **Guía 1: Namespaces** - Aprende aislamiento lógico
2. **Guía 2: Labels** - Domina organización y selección

## 💡 Conceptos Clave

- **Namespace**: Partición virtual del cluster
- **Label**: Par clave-valor para identificar objetos
- **Selector**: Query para filtrar por labels
- **nodeSelector**: Programar Pods en nodos específicos

## 📊 Comandos Clave

| Comando | Propósito |
|---------|-----------|
| `kubectl create namespace` | Crear namespace |
| `kubectl get pods -n <ns>` | Listar en namespace |
| `kubectl get pods -A` | Listar en todos los namespaces |
| `kubectl label <recurso> key=value` | Agregar label |
| `kubectl get pods -l key=value` | Filtrar por label |
| `kubectl get pods --show-labels` | Ver labels |

## ✅ Checklist de Dominio

- [ ] Puedo crear y gestionar namespaces
- [ ] Entiendo cuándo usar namespaces vs labels
- [ ] Puedo agregar y modificar labels
- [ ] Domino queries con selectors
- [ ] Entiendo cómo Services usan labels
- [ ] Puedo programar Pods en nodos específicos

## 🔗 Recursos Adicionales

- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- **Slides**: `managing-objects-with-labels-annotations-and-namespaces-slides.pdf`

## ➡️ Siguiente Módulo

**[Módulo 04: Pods](../../pods/04/demos/README.md)**

---

**¡Feliz aprendizaje! 🚀**
