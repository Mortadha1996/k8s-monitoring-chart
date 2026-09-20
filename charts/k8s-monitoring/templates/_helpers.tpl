{{- define "k8s-monitoring.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "k8s-monitoring.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "k8s-monitoring.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "k8s-monitoring.labels" -}}
app.kubernetes.io/name: {{ include "k8s-monitoring.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
