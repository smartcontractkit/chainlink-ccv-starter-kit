{{- define "ccv-cell-mp.image" -}}
{{- if .registry -}}
{{ .registry }}/{{ .repository }}:{{ .tag }}
{{- else -}}
{{ .repository }}:{{ .tag }}
{{- end -}}
{{- end -}}
