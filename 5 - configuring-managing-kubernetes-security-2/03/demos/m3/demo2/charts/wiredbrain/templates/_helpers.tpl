{{/*
Expand the name of the chart.
*/}}
{{- define "wiredbrain.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "wiredbrain.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
Matches k8s-manifests simple label scheme
*/}}
{{- define "wiredbrain.labels" -}}
app: wiredbrain
{{- end }}

{{/*
Selector labels
Matches k8s-manifests simple label scheme
*/}}
{{- define "wiredbrain.selectorLabels" -}}
app: wiredbrain
{{- end }}

{{/*
Get image tag
*/}}
{{- define "wiredbrain.imageTag" -}}
{{- .tag | default .Values.global.imageTag }}
{{- end }}

{{/*
Get full image name
Expects a dict with: root (root context) and image (image config)
*/}}
{{- define "wiredbrain.image" -}}
{{- $root := .root }}
{{- $image := .image }}
{{- $registry := $root.Values.global.imageRegistry }}
{{- $repository := $image.repository }}
{{- $tag := $image.tag | default $root.Values.global.imageTag }}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}