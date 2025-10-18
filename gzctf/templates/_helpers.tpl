{{/*
Expand the name of the chart.
*/}}
{{- define "gzctf.name" -}}
{{- default .Chart.Name .Values.gzctf.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gzctf.fullname" -}}
{{- if .Values.gzctf.fullnameOverride }}
{{- .Values.gzctf.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.gzctf.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gzctf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gzctf.labels" -}}
helm.sh/chart: {{ include "gzctf.chart" . }}
{{ include "gzctf.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gzctf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gzctf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gzctf.serviceAccountName" -}}
{{- if .Values.gzctf.serviceAccount.create }}
{{- default (include "gzctf.fullname" .) .Values.gzctf.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.gzctf.serviceAccount.name }}
{{- end }}
{{- end }}
