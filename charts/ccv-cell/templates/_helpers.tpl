{{/*
Expand the name of the chart.
*/}}
{{- define "ccv-cell.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ccv-cell.fullname" -}}
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
{{- define "ccv-cell.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "ccv-cell.labels" -}}
helm.sh/chart: {{ include "ccv-cell.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "ccv-cell.verifier.fullname" -}}
{{- printf "%s-verifier" (include "ccv-cell.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ccv-cell.verifier.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ccv-cell.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: verifier
{{- end -}}

{{- define "ccv-cell.verifier.labels" -}}
{{ include "ccv-cell.labels" . }}
{{ include "ccv-cell.verifier.selectorLabels" . }}
{{- end -}}

{{- define "ccv-cell.aggregator.fullname" -}}
{{- printf "%s-aggregator" (include "ccv-cell.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ccv-cell.aggregator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ccv-cell.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: aggregator
{{- end -}}

{{- define "ccv-cell.aggregator.labels" -}}
{{ include "ccv-cell.labels" . }}
{{ include "ccv-cell.aggregator.selectorLabels" . }}
{{- end -}}

{{- define "ccv-cell.verifier.serviceAccountName" -}}
{{- if .Values.verifier.serviceAccount.create -}}
{{- default (include "ccv-cell.verifier.fullname" .) .Values.verifier.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.verifier.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "ccv-cell.aggregator.serviceAccountName" -}}
{{- if .Values.aggregator.serviceAccount.create -}}
{{- default (include "ccv-cell.aggregator.fullname" .) .Values.aggregator.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.aggregator.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Name of the K8s Secret (existingSecret/externalSecret) or SecretProviderClass (gcpSecretStore) backing a secret block.
include "ccv-cell.secretName" (dict "root" . "component" "aggregator" "subComponent" "app")
*/}}
{{- define "ccv-cell.secretName" -}}
  {{- $componentRoot := index .root.Values .component -}}
  {{- $secret := index $componentRoot.secrets .subComponent -}}
  {{- $default := printf "%s-%s-%s" (include "ccv-cell.fullname" .root) .component .subComponent -}}

  {{- if eq $secret.type "existingSecret" -}}
      {{- required (printf "Secret '%s' for the %s is of type 'existingSecret', but no name was provided" .subComponent .component) $secret.existingSecret.name -}}
  {{- else if eq $secret.type "externalSecret" -}}
    {{- $secret.externalSecret.name | default $default -}}
  {{- else if eq $secret.type "gcpSecretStore" -}}
    {{- $secret.gcpSecretStore.secretProviderClass.name | default $default -}}
  {{- else -}}
    {{- fail (printf "invalid secret type %q (must be existingSecret, externalSecret, or gcpSecretStore)" $secret.type) -}}
  {{- end -}}
{{- end -}}

{{/*
Full image reference for a component (verifier/aggregator), e.g.:
  {{ include "ccv-cell.image" (dict "root" $ "component" "verifier") }}
Global registry is the default, each component supplies its own repository and tag/digest.
*/}}
{{- define "ccv-cell.image" -}}
  {{- $image := (index .root.Values .component).image -}}

  {{- if and $image.tag $image.digest -}}
    {{- fail (printf "%s.image: tag and digest are mutually exclusive" .component) -}}
  {{- end -}}

  {{- $registry := $image.registry | default .root.Values.global.image.registry -}}
  {{- $repo := ternary (printf "%s/%s" $registry $image.repository) $image.repository (empty $registry | not) -}}

  {{- if $image.digest -}}
    {{- printf "%s@%s" $repo $image.digest -}}
  {{- else -}}
    {{- printf "%s:%s" $repo $image.tag -}}
  {{- end -}}
{{- end -}}

{{/*
Casts each key in .keys to int64 within map .m, in place. Values loaded from values.yaml render as
float64, and toToml then renders whole numbers as floats (e.g. "9988.0" instead of "9988"), which a
strict TOML decoder rejects for integer fields. Usage:
  {{ include "ccv-cell.castInts" (dict "m" $cfg.server "keys" (list "maxRecvMsgSizeBytes" "maxSendMsgSizeBytes")) }}
*/}}
{{- define "ccv-cell.castInts" -}}
{{- range .keys }}
{{- $_ := set $.m . (int64 (index $.m .)) }}
{{- end }}
{{- end -}}
