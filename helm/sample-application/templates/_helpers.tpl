{{- define "sample.labels" -}}
app.kubernetes.io/name: sample-application
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- define "sample.image" -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- end }}
