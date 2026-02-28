{{/*
Expand the name of the chart.
*/}}
{{- define "milkapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "milkapp.fullname" -}}
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
*/}}
{{- define "milkapp.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "milkapp.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "milkapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "milkapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Nginx selector labels
*/}}
{{- define "milkapp.nginxSelectorLabels" -}}
app.kubernetes.io/name: {{ include "milkapp.name" . }}-nginx
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Database host — use the self-managed PostgreSQL service if enabled
*/}}
{{- define "milkapp.databaseHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "milkapp.fullname" .) }}
{{- else }}
{{- .Values.database.host }}
{{- end }}
{{- end }}

{{/*
DATABASE_URL connection string
When postgresql is enabled, derive credentials from postgresql.auth values.
*/}}
{{- define "milkapp.databaseURL" -}}
{{- if .Values.postgresql.enabled -}}
postgres://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "milkapp.databaseHost" . }}:{{ .Values.database.port }}/{{ .Values.postgresql.auth.database }}?sslmode={{ .Values.database.sslmode }}
{{- else -}}
postgres://{{ .Values.database.user }}:{{ .Values.database.password }}@{{ include "milkapp.databaseHost" . }}:{{ .Values.database.port }}/{{ .Values.database.name }}?sslmode={{ .Values.database.sslmode }}
{{- end -}}
{{- end }}
