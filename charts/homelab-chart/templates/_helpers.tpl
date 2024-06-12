{{/*
Expand the name of the chart.
*/}}
{{- define "homelab-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "homelab-chart.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "homelab-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "homelab-chart.labels" -}}
helm.sh/chart: {{ include "homelab-chart.chart" . }}
{{ include "homelab-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "homelab-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homelab-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "homelab-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "homelab-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "mergeMaps" -}}
  {{- $source := index . 0 -}}
  {{- $override := index . 1 -}}
  {{- $result := dict -}}  {{/* Create a new dictionary to avoid altering the source directly */}}
  {{- range $key, $value := $source -}}
    {{- if hasKey $override $key -}}
      {{- if and (kindIs "map" $value) (kindIs "map" (index $override $key)) -}}
        {{- $mergedSubMap := include "mergeMaps" (list $value (index $override $key)) | fromYaml -}}
        {{- $_ := set $result $key $mergedSubMap -}}
      {{- else -}}
        {{- $_ := set $result $key (index $override $key) -}}
      {{- end -}}
    {{- else -}}
      {{- $_ := set $result $key $value -}}
    {{- end -}}
  {{- end -}}
  {{- range $key, $value := $override -}}
    {{- if not (hasKey $source $key) -}}
      {{- $_ := set $result $key $value -}}
    {{- end -}}
  {{- end -}}
  {{- $result | toYaml -}}
{{- end -}}
