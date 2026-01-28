# Módulo 02: API de Kubernetes

## 📖 Descripción

Este módulo cubre los fundamentos de la API de Kubernetes, enseñándote cómo descubrir recursos, entender el versionado de API, y analizar la comunicación HTTP entre kubectl y el API Server.

## 🎯 Objetivos del Módulo

Al completar este módulo, serás capaz de:
- Descubrir y explorar recursos de la API de Kubernetes
- Entender el sistema de versionado y API Groups
- Analizar requests HTTP y debuggear problemas de comunicación
- Validar y generar manifiestos YAML
- Trabajar directamente con la API usando kubectl proxy

## 📚 Prerequisitos

- Cluster de Kubernetes funcional (minikube, kind, o cluster remoto)
- kubectl instalado y configurado
- Conocimientos básicos de HTTP y REST APIs
- Familiaridad con YAML

## 📑 Contenido del Módulo

### Guías de Aprendizaje

1. **[Objetos de API y Descubrimiento](./1-APIObjects.md)**
   - Descubrimiento de API con `kubectl api-resources`
   - Exploración de recursos con `kubectl explain`
   - Validación de manifiestos con `--dry-run`
   - Generación automática de YAML
   - Comparación de cambios con `kubectl diff`

2. **[Versiones de Objetos API](./2-APIObjectVersions.md)**
   - Sistema de versionado de Kubernetes (alpha, beta, stable)
   - API Groups y su organización
   - Migración entre versiones de API
   - Políticas de deprecación

3. **[Anatomía de Requests API](./3-AnatomyApiRequest.md)**
   - Comunicación HTTP con el API Server
   - Verbos HTTP y códigos de respuesta
   - Niveles de verbosity (`-v` flag)
   - kubectl proxy para acceso directo
   - Watch requests y streaming

### Archivos de Demostración

#### Scripts Shell
- `1-APIObjects.sh` - Comandos de descubrimiento de API
- `2-APIObjectVersions.sh` - Exploración de versiones
- `3-AnatomyApiRequest.sh` - Análisis de requests HTTP

#### Manifiestos YAML
- `pod.yaml` - Pod simple de ejemplo
- `deployment.yaml` - Deployment básico
- `deployment-new.yaml` - Deployment con cambios
- `deployment-error.yaml` - Deployment con error intencional
- `deployment-generated.yaml` - YAML generado automáticamente

## 🚀 Orden de Estudio Recomendado

1. **Comienza con la Guía 1**: Aprende a descubrir y explorar la API
2. **Continúa con la Guía 2**: Entiende el versionado antes de escribir manifiestos
3. **Finaliza con la Guía 3**: Profundiza en cómo funciona la comunicación

## 💡 Consejos de Aprendizaje

- **Practica cada comando**: No solo leas, ejecuta los ejemplos en tu cluster
- **Experimenta con verbosity**: Usa `-v 6` para entender qué hace cada comando
- **Completa los ejercicios**: Refuerzan el aprendizaje práctico
- **Usa kubectl explain**: Es tu mejor amigo para escribir YAML
- **Guarda tus manifiestos**: Crea un repositorio de ejemplos reutilizables

## 🔬 Laboratorio Práctico

### Setup Inicial

```bash
# Verificar conexión al cluster
kubectl cluster-info

# Verificar contexto
kubectl config current-context

# Listar nodos
kubectl get nodes
```

### Ejercicio Integrador

Combina lo aprendido en las tres guías:

1. **Descubre** qué versión usa el recurso `StatefulSet`
   ```bash
   kubectl api-resources | grep statefulsets
   ```

2. **Explora** su estructura
   ```bash
   kubectl explain statefulset.spec
   ```

3. **Genera** un manifiesto de ejemplo
   ```bash
   kubectl create statefulset web --image=nginx --dry-run=client -o yaml
   ```

4. **Analiza** el request HTTP
   ```bash
   kubectl create statefulset web --image=nginx --dry-run=server -v 6
   ```

## 📊 Comandos Clave del Módulo

| Comando | Propósito |
|---------|-----------|
| `kubectl api-resources` | Listar todos los recursos disponibles |
| `kubectl api-versions` | Listar versiones de API soportadas |
| `kubectl explain <recurso>` | Ver documentación de un recurso |
| `kubectl apply --dry-run=server` | Validar manifiestos |
| `kubectl create --dry-run -o yaml` | Generar YAML |
| `kubectl diff -f <archivo>` | Comparar cambios |
| `kubectl -v <nivel>` | Ver detalles de requests HTTP |
| `kubectl proxy` | Acceder a la API directamente |

## 🎓 Conceptos Clave

- **API Server**: Componente central que expone la API de Kubernetes
- **API Resource**: Tipo de objeto que puedes crear (Pod, Deployment, etc.)
- **API Group**: Agrupación lógica de recursos (apps, batch, networking)
- **API Version**: Nivel de estabilidad (alpha, beta, v1)
- **Dry Run**: Validación sin crear recursos reales
- **kubectl proxy**: Proxy local para acceso directo a la API
- **Verbosity**: Nivel de detalle en logs de kubectl

## ✅ Checklist de Dominio

Marca cuando te sientas cómodo con cada concepto:

- [ ] Puedo listar todos los recursos disponibles en mi cluster
- [ ] Entiendo la diferencia entre API Groups y versiones
- [ ] Puedo usar `kubectl explain` para escribir manifiestos
- [ ] Sé validar YAML con `--dry-run` antes de aplicar
- [ ] Puedo generar manifiestos automáticamente
- [ ] Entiendo qué verbo HTTP usa cada operación de kubectl
- [ ] Puedo interpretar códigos de respuesta HTTP (200, 404, 403)
- [ ] Sé usar kubectl proxy para acceder a la API
- [ ] Puedo debuggear problemas de autenticación

## 🔗 Recursos Adicionales

### Documentación Oficial
- [Kubernetes API Overview](https://kubernetes.io/docs/reference/using-api/)
- [API Conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

### Herramientas Útiles
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [API Reference Documentation](https://kubernetes.io/docs/reference/kubernetes-api/)
- [kubeval](https://github.com/instrumenta/kubeval) - Validador de manifiestos

### Material Complementario
- **Slides**: `using-the-kubernetes-api-slides.pdf`

## 🚧 Troubleshooting Común

### Problema: "error: You must be logged in"
**Solución**: Verifica tu kubeconfig con `kubectl config view`

### Problema: "error: the server doesn't have a resource type"
**Solución**: Verifica que el recurso existe con `kubectl api-resources`

### Problema: Dry run dice "created" pero no veo el recurso
**Solución**: Esto es esperado, dry run simula sin persistir

## ➡️ Siguiente Módulo

Una vez domines la API de Kubernetes, continúa con:

**[Módulo 03: Namespaces, Labels y Annotations](../../namespaces%20tags%20annotations/03/demos/README.md)**

Aprenderás a organizar y gestionar recursos usando namespaces, labels y selectors.

---

## 📝 Notas

- Los scripts `.sh` originales se mantienen como referencia
- Las guías `.md` son complementarias y educativas
- Todos los ejemplos asumen un cluster de prueba
- Ajusta nombres de nodos/IPs según tu entorno

## 🤝 Contribuciones

Si encuentras errores o tienes sugerencias de mejora, por favor reporta issues o envía pull requests.

---

**¡Feliz aprendizaje! 🚀**
