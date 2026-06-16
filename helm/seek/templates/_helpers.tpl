{{/*
Expand the name of the chart.
*/}}
{{- define "seek.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "seek.fullname" -}}
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
Create chart label.
*/}}
{{- define "seek.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "seek.labels" -}}
helm.sh/chart: {{ include "seek.chart" . }}
{{ include "seek.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "seek.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seek.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MySQL service hostname (within the cluster)
*/}}
{{- define "seek.mysql.host" -}}
{{- printf "%s-mysql" (include "seek.fullname" .) }}
{{- end }}

{{/*
Redis service hostname (within the cluster)
*/}}
{{- define "seek.redis.host" -}}
{{- printf "%s-redis" (include "seek.fullname" .) }}
{{- end }}

{{/*
Solr service hostname (within the cluster)
*/}}
{{- define "seek.solr.host" -}}
{{- printf "%s-solr" (include "seek.fullname" .) }}
{{- end }}

{{/*
DB secret name
*/}}
{{- define "seek.db.secretName" -}}
{{- printf "%s-db" (include "seek.fullname" .) }}
{{- end }}

{{/*
Environment variables shared by the seek web and seek_workers pods.
Includes all database, Solr, and Redis connection details.
*/}}
{{- define "seek.commonEnv" -}}
- name: RAILS_ENV
  value: {{ .Values.seek.railsEnv | quote }}
- name: RAILS_LOG_LEVEL
  value: {{ .Values.seek.railsLogLevel | quote }}
- name: SOLR_HOST
  value: {{ include "seek.solr.host" . | quote }}
- name: SOLR_PORT
  value: "8983"
- name: REDIS_URL
  value: {{ printf "redis://%s:6379/0" (include "seek.redis.host" .) | quote }}
- name: MYSQL_HOST
  value: {{ include "seek.mysql.host" . | quote }}
- name: MYSQL_DATABASE
  value: {{ .Values.mysql.auth.database | quote }}
- name: MYSQL_USER
  value: {{ .Values.mysql.auth.username | quote }}
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "seek.db.secretName" . }}
      key: password
- name: MYSQL_ROOT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "seek.db.secretName" . }}
      key: root-password
{{- if .Values.seek.relativeUrlRoot }}
- name: RAILS_RELATIVE_URL_ROOT
  value: {{ .Values.seek.relativeUrlRoot | quote }}
{{- end }}
{{- end }}

{{/*
Volume mounts shared by seek and seek_workers: filestore and cache.
*/}}
{{- define "seek.sharedVolumeMounts" -}}
- name: filestore
  mountPath: /seek/filestore
- name: cache
  mountPath: /seek/tmp/cache
{{- end }}

{{/*
Shared volumes referencing the filestore and cache PVCs.
*/}}
{{- define "seek.sharedVolumes" -}}
- name: filestore
  persistentVolumeClaim:
    claimName: {{ include "seek.fullname" . }}-filestore
- name: cache
  persistentVolumeClaim:
    claimName: {{ include "seek.fullname" . }}-cache
{{- end }}
