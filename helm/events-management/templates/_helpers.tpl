{{- define "events-management.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "events-management.fullname" -}}
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

{{- define "events-management.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "events-management.labels" -}}
helm.sh/chart: {{ include "events-management.chart" . }}
{{ include "events-management.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "events-management.selectorLabels" -}}
app.kubernetes.io/name: {{ include "events-management.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "events-management.dbHost" -}}
{{- if .Values.database.host }}
{{- .Values.database.host }}
{{- else }}
{{- printf "%s-postgres" (include "events-management.fullname" .) }}
{{- end }}
{{- end }}
