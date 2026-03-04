{{/*
Expand the name of the chart.
*/}}
{{- define "babymilk.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "babymilk.fullname" -}}
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
{{- define "babymilk.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "babymilk.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "babymilk.selectorLabels" -}}
app.kubernetes.io/name: {{ include "babymilk.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Nginx selector labels
*/}}
{{- define "babymilk.nginxSelectorLabels" -}}
app.kubernetes.io/name: {{ include "babymilk.name" . }}-nginx
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Database host — use the self-managed PostgreSQL service if enabled
*/}}
{{- define "babymilk.databaseHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "babymilk.fullname" .) }}
{{- else }}
{{- .Values.database.host }}
{{- end }}
{{- end }}

{{/*
DATABASE_URL connection string
When postgresql is enabled, derive credentials from postgresql.auth values.
*/}}
{{- define "babymilk.databaseURL" -}}
{{- if .Values.postgresql.enabled -}}
postgres://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "babymilk.databaseHost" . }}:{{ .Values.database.port }}/{{ .Values.postgresql.auth.database }}?sslmode={{ .Values.database.sslmode }}
{{- else -}}
postgres://{{ .Values.database.user }}:{{ .Values.database.password }}@{{ include "babymilk.databaseHost" . }}:{{ .Values.database.port }}/{{ .Values.database.name }}?sslmode={{ .Values.database.sslmode }}
{{- end -}}
{{- end }}

{{/*
App DB secret name
*/}}
{{- define "babymilk.dbSecretName" -}}
{{- default (printf "%s-db" (include "babymilk.fullname" .)) .Values.secrets.db.name -}}
{{- end }}

{{/*
PostgreSQL auth secret name
*/}}
{{- define "babymilk.postgresqlSecretName" -}}
{{- default (printf "%s-postgresql" (include "babymilk.fullname" .)) .Values.secrets.postgresql.name -}}
{{- end }}
