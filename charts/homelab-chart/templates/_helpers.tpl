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

{{/*
Render a container definition. Accepts a dict with:
  - container: the container configuration object
  - root: the root context (.)
  - pvcVolumeMounts: optional list of PVC volume mounts to merge
*/}}
{{- define "homelab-chart.container" -}}
{{- $container := .container -}}
{{- $root := .root -}}
{{- $pvcVolumeMounts := .pvcVolumeMounts | default list -}}
- name: {{ $container.name }}
  {{- if $container.securityContext }}
  securityContext:
    {{- toYaml $container.securityContext | nindent 4 }}
  {{- end }}
  image: "{{ $container.image.repository }}:{{ $container.image.tag }}"
  imagePullPolicy: {{ $container.image.pullPolicy | default "IfNotPresent" }}
  {{- if $container.ports }}
  ports:
    {{- range $container.ports }}
    - name: {{ .name }}
      containerPort: {{ .containerPort }}
      protocol: {{ .protocol | default "TCP" }}
    {{- end }}
  {{- end }}
  {{- with $container.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $container.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $container.resources }}
  resources:
    {{- toYaml $container.resources | nindent 4 }}
  {{- end }}
  {{- $allVolumeMounts := list }}
  {{- if $pvcVolumeMounts }}
  {{- $allVolumeMounts = concat $allVolumeMounts $pvcVolumeMounts }}
  {{- end }}
  {{- if $container.volumeMounts }}
  {{- $allVolumeMounts = concat $allVolumeMounts $container.volumeMounts }}
  {{- end }}
  {{- if $allVolumeMounts }}
  volumeMounts:
    {{- toYaml $allVolumeMounts | nindent 4 }}
  {{- end }}
  {{- with $container.env }}
  env:
    {{- range $key, $value := . }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- with $container.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Create a volume mount dictionary from a PVC configuration.
Accepts a PVC configuration object with: name, mountPath, readOnly, and optionally subPath.
Returns a dictionary suitable for use in volumeMounts.
*/}}
{{- define "homelab-chart.pvcVolumeMount" -}}
{{- $volumeMount := dict "name" (printf "pvc-%s" .name) "mountPath" .mountPath "readOnly" (default false .readOnly) -}}
{{- if .subPath -}}
{{- $_ := set $volumeMount "subPath" .subPath -}}
{{- end -}}
{{- $volumeMount | toYaml -}}
{{- end -}}

{{/*
Create a volume definition from a PVC configuration.
Accepts a PVC configuration object with: name.
Returns a dictionary suitable for use in volumes.
*/}}
{{- define "homelab-chart.pvcVolume" -}}
{{- dict "name" (printf "pvc-%s" .name) "persistentVolumeClaim" (dict "claimName" .name) | toYaml -}}
{{- end -}}

{{/*
Create a volume mount dictionary from a ConfigMap configuration.
Accepts a ConfigMap configuration object with: name, mountPath, readOnly, and optionally subPath.
Returns a dictionary suitable for use in volumeMounts.
*/}}
{{- define "homelab-chart.configMapVolumeMount" -}}
{{- $volumeMount := dict "name" (printf "configmap-%s" .name) "mountPath" .mountPath "readOnly" (default false .readOnly) -}}
{{- if .subPath -}}
{{- $_ := set $volumeMount "subPath" .subPath -}}
{{- end -}}
{{- $volumeMount | toYaml -}}
{{- end -}}

{{/*
Create a volume definition from a ConfigMap configuration.
Accepts a ConfigMap configuration object with: name.
Returns a dictionary suitable for use in volumes.
*/}}
{{- define "homelab-chart.configMapVolume" -}}
{{- dict "name" (printf "configmap-%s" .name) "configMap" (dict "name" .name) | toYaml -}}
{{- end -}}
