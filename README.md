# kubernetes-utils

📚 **Recursos educativos completos para aprender Kubernetes**, cubriendo API, gestión de objetos y administración de Pods.

---

## ⚠️ Nota Importante sobre IA

> [!WARNING]
> **Contenido Generado con IA**: Las guías markdown de este repositorio fueron creadas con asistencia de Inteligencia Artificial basándose en los scripts shell originales y manifiestos YAML existentes. Aunque se ha puesto cuidado en la precisión del contenido:
> 
> - **Puede contener alucinaciones o inexactitudes**: Siempre verifica los comandos y conceptos con la [documentación oficial de Kubernetes](https://kubernetes.io/docs/)
> - **Prueba en entornos seguros**: Ejecuta los ejemplos en clusters de prueba, nunca directamente en producción
> - **Reporta errores**: Si encuentras información incorrecta, por favor repórtala para mejorar el contenido
> 
> Los **scripts shell originales** (`.sh`) y **manifiestos YAML** son el material fuente original y se mantienen intactos como referencia autoritativa.

---

## 🎯 Sobre Este Repositorio

**Objetivo**: Este repositorio tiene como propósito principal servir como un **handbook de los conceptos clave de Kubernetes**, proporcionando una referencia rápida y educativa en formato de resumen.

Este repositorio contiene material de aprendizaje estructurado sobre Kubernetes, organizado en tres módulos progresivos. Cada módulo incluye:
- **Guías markdown** con teoría, ejemplos prácticos y ejercicios
- **Scripts shell** con comandos de demostración
- **Manifiestos YAML** de ejemplo
- **Presentaciones PDF** con material complementario

**Ideal para**:
- 📖 **Referencia rápida**: Consultar comandos y conceptos sin buscar en documentación extensa
- 🎓 **Aprendizaje estructurado**: Seguir una ruta progresiva de principiante a avanzado
- 🔄 **Repaso**: Refrescar conocimientos de Kubernetes de forma organizada
- 💼 **Onboarding**: Introducir nuevos miembros del equipo a Kubernetes

---

## 📚 Índice de Contenido

### 📘 Módulo 02: API de Kubernetes

**Ubicación**: `Kubernetes api and pods/api/02/demos/`

#### Guías de Aprendizaje
1. **[Objetos de API y Descubrimiento](./Kubernetes%20api%20and%20pods/api/02/demos/1-APIObjects.md)**
   - Descubrimiento de API con `kubectl api-resources`
   - Exploración con `kubectl explain`
   - Validación con `--dry-run`
   - Generación de YAML
   - Comparación con `kubectl diff`

2. **[Versiones de Objetos API](./Kubernetes%20api%20and%20pods/api/02/demos/2-APIObjectVersions.md)**
   - Sistema de versionado (alpha, beta, stable)
   - API Groups
   - Migración entre versiones
   - Políticas de deprecación

3. **[Anatomía de Requests API](./Kubernetes%20api%20and%20pods/api/02/demos/3-AnatomyApiRequest.md)**
   - Comunicación HTTP con API Server
   - Verbos HTTP y códigos de respuesta
   - Niveles de verbosity (`-v` flag)
   - kubectl proxy
   - Watch requests

**[📖 README del Módulo 02](./Kubernetes%20api%20and%20pods/api/02/demos/README.md)**

---

### 📗 Módulo 03: Namespaces, Labels y Annotations

**Ubicación**: `Kubernetes api and pods/namespaces tags annotations/03/demos/`

#### Guías de Aprendizaje
1. **[Namespaces](./Kubernetes%20api%20and%20pods/namespaces%20tags%20annotations/03/demos/1-namespaces.md)**
   - Creación y gestión de namespaces
   - Recursos namespaced vs cluster-scoped
   - Multi-tenancy
   - Organización de recursos

2. **[Labels y Selectors](./Kubernetes%20api%20and%20pods/namespaces%20tags%20annotations/03/demos/2-labels.md)**
   - Creación y gestión de labels
   - Queries con selectors
   - Labels en Deployments y Services
   - Node selection
   - Estrategias de organización

**[📖 README del Módulo 03](./Kubernetes%20api%20and%20pods/namespaces%20tags%20annotations/03/demos/README.md)**

---

### 📙 Módulo 04: Pods

**Ubicación**: `Kubernetes api and pods/pods/04/demos/`

#### Guías de Aprendizaje
1. **[Fundamentos de Pods](./Kubernetes%20api%20and%20pods/pods/04/demos/1-Pods.md)**
   - Creación y gestión de Pods
   - kubectl exec y port-forward
   - Static Pods
   - Monitoreo de eventos

2. **[Multi-Container Pods](./Kubernetes%20api%20and%20pods/pods/04/demos/2-Multi-Container-Pods.md)**
   - Patrones sidecar, ambassador, adapter
   - Shared volumes y networking
   - Producer-consumer pattern

3. **[Init Containers](./Kubernetes%20api%20and%20pods/pods/04/demos/2a-Init-Containers.md)**
   - Ejecución secuencial de setup
   - Casos de uso (migrations, dependencies)
   - Monitoreo de init containers

4. **[Ciclo de Vida de Pods](./Kubernetes%20api%20and%20pods/pods/04/demos/3-Pod-Lifecycle.md)**
   - Fases del Pod
   - Container states
   - Restart policies (Always, OnFailure, Never)
   - Backoff y troubleshooting

5. **[Probes y Health Checks](./Kubernetes%20api%20and%20pods/pods/04/demos/4-Probes.md)**
   - Liveness probes
   - Readiness probes
   - Startup probes
   - Configuración y debugging

**[📖 README del Módulo 04](./Kubernetes%20api%20and%20pods/pods/04/demos/README.md)**

---

## 🚀 Cómo Usar Este Repositorio

### Para Principiantes

1. **Sigue el orden de los módulos**: 02 → 03 → 04
2. **Lee cada guía markdown** con atención
3. **Ejecuta los comandos** en tu cluster de prueba
4. **Revisa los manifiestos YAML** de ejemplo
5. **Completa los ejercicios** al final de cada guía

### Para Usuarios Avanzados

- Usa las guías como **referencia rápida**
- Consulta las secciones **"Cuándo Usar"** y **"Mejores Prácticas"**
- Revisa los **scripts shell** originales para comandos avanzados
- Adapta los **manifiestos YAML** a tus necesidades

---

## 🛠️ Prerequisitos

### Software Requerido

- **Cluster de Kubernetes**: minikube, kind, Docker Desktop, o cluster remoto
- **kubectl**: Instalado y configurado
- **Terminal**: Bash, PowerShell, o equivalente

### Conocimientos Previos

- Conceptos básicos de contenedores y Docker
- Familiaridad con YAML
- Conocimientos básicos de línea de comandos

### Setup Recomendado

```bash
# Verificar kubectl
kubectl version --client

# Verificar conexión al cluster
kubectl cluster-info

# Verificar nodos
kubectl get nodes
```

---

## 📖 Estructura del Proyecto

```
kubernetes-utils/
├── README.md (este archivo)
└── Kubernetes api and pods/
    ├── api/
    │   └── 02/
    │       ├── demos/
    │       │   ├── README.md
    │       │   ├── 1-APIObjects.md
    │       │   ├── 2-APIObjectVersions.md
    │       │   ├── 3-AnatomyApiRequest.md
    │       │   ├── *.sh (scripts originales)
    │       │   └── *.yaml (manifiestos)
    │       └── using-the-kubernetes-api-slides.pdf
    ├── namespaces tags annotations/
    │   └── 03/
    │       ├── demos/
    │       │   ├── README.md
    │       │   ├── 1-namespaces.md
    │       │   ├── 2-labels.md
    │       │   ├── *.sh (scripts originales)
    │       │   └── *.yaml (manifiestos)
    │       └── managing-objects-with-labels-annotations-and-namespaces-slides.pdf
    └── pods/
        └── 04/
            ├── demos/
            │   ├── README.md
            │   ├── 1-Pods.md
            │   ├── 2-Multi-Container-Pods.md
            │   ├── 2a-Init-Containers.md
            │   ├── 3-Pod-Lifecycle.md
            │   ├── 4-Probes.md
            │   ├── *.sh (scripts originales)
            │   └── *.yaml (manifiestos)
            └── running-and-managing-pods-slides.pdf
```

---

## 🎓 Ruta de Aprendizaje

### Nivel Principiante (Semana 1-2)

- ✅ Módulo 02: API de Kubernetes
  - Entender cómo funciona la API
  - Aprender comandos básicos de kubectl
  - Validar y generar manifiestos

### Nivel Intermedio (Semana 3-4)

- ✅ Módulo 03: Namespaces y Labels
  - Organizar recursos
  - Implementar multi-tenancy básico
  - Usar selectors efectivamente

### Nivel Avanzado (Semana 5-6)

- ✅ Módulo 04: Pods
  - Dominar el ciclo de vida
  - Implementar patrones multi-container
  - Configurar health checks en producción

---

## 💡 Consejos de Aprendizaje

1. **Practica en un cluster de prueba**: Nunca en producción
2. **Experimenta con los ejemplos**: Modifica y observa resultados
3. **Lee los errores cuidadosamente**: Son educativos
4. **Usa `kubectl explain`**: Tu mejor amigo para escribir YAML
5. **Completa los ejercicios**: Refuerzan el aprendizaje
6. **Consulta la documentación oficial**: Para profundizar

---

## 📊 Resumen de Comandos Esenciales

### Descubrimiento
```bash
kubectl api-resources
kubectl api-versions
kubectl explain <recurso>
```

### Gestión de Recursos
```bash
kubectl apply -f <archivo.yaml>
kubectl get <recurso>
kubectl describe <recurso> <nombre>
kubectl delete <recurso> <nombre>
```

### Debugging
```bash
kubectl logs <pod>
kubectl exec -it <pod> -- sh
kubectl port-forward <pod> 8080:80
kubectl get events --watch
```

### Organización
```bash
kubectl get pods -n <namespace>
kubectl get pods -l <label-query>
kubectl label <recurso> <nombre> key=value
```

---

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

### Herramientas Útiles
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubeval](https://github.com/instrumenta/kubeval) - Validador de manifiestos
- [k9s](https://k9scli.io/) - Terminal UI para Kubernetes

### Comunidad
- [Kubernetes Slack](https://slack.k8s.io/)
- [Stack Overflow - Kubernetes](https://stackoverflow.com/questions/tagged/kubernetes)

---

## 🤝 Contribuciones

Si encuentras errores, tienes sugerencias de mejora, o quieres agregar contenido:

1. Reporta issues en el repositorio
2. Envía pull requests con mejoras
3. Comparte feedback sobre las guías

---

## 📄 Licencia

[Especificar licencia si aplica]

---

## ✨ Características de Este Repositorio

- ✅ **10 guías markdown** completas con teoría y práctica
- ✅ **Ejemplos prácticos** probados y funcionales
- ✅ **Ejercicios** con soluciones
- ✅ **Mejores prácticas** de la industria
- ✅ **Troubleshooting** de problemas comunes
- ✅ **Manifiestos YAML** listos para usar
- ✅ **Scripts shell** originales como referencia

---

## 🎯 Objetivos de Aprendizaje

Al completar este repositorio, serás capaz de:

- ✅ Interactuar con la API de Kubernetes efectivamente
- ✅ Organizar recursos con namespaces y labels
- ✅ Crear y gestionar Pods en producción
- ✅ Implementar patrones multi-container
- ✅ Configurar health checks apropiadamente
- ✅ Debuggear problemas comunes
- ✅ Escribir manifiestos YAML correctos
- ✅ Aplicar mejores prácticas de Kubernetes

---

**¡Feliz aprendizaje con Kubernetes! 🚀**

*Última actualización: 2026-01-27*