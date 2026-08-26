{{/*
Assemble a full image reference from a registry/repository/tag block.
  {{ include "ccv-cell-mp.image" .Values.verify.postgres.image }}
Used by the verify overlay templates, whose images are parameterized in data-test/schema.yaml.
*/}}
{{- define "ccv-cell-mp.image" -}}
{{- if .registry -}}
{{ .registry }}/{{ .repository }}:{{ .tag }}
{{- else -}}
{{ .repository }}:{{ .tag }}
{{- end -}}
{{- end -}}
