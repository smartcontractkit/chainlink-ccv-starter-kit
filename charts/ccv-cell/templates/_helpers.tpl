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

{{- define "ccv-cell.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ccv-cell.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "ccv-cell.verifier.fullname" -}}
{{- printf "%s-verifier" (include "ccv-cell.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ccv-cell.verifier.selectorLabels" -}}
{{ include "ccv-cell.selectorLabels" . }}
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
{{ include "ccv-cell.selectorLabels" . }}
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
Name of the K8s Secret (existingSecret/externalSecret) or SecretProviderClass (gcpSecretStore/awsSecretStore/azureKeyVault) backing a secret block.
include "ccv-cell.secretName" (dict "root" . "component" "aggregator" "subComponent" "app")
*/}}
{{- define "ccv-cell.secretName" -}}
  {{- $componentRoot := index .root.Values .component -}}
  {{- $secret := index $componentRoot.secrets .subComponent -}}
  {{- $default := printf "%s-%s-%s" (include "ccv-cell.fullname" .root) .component (.subComponent | lower) -}}

  {{- if eq $secret.type "existingSecret" -}}
      {{- required (printf "Secret '%s' for the %s is of type 'existingSecret', but no name was provided" .subComponent .component) $secret.existingSecret.name -}}
  {{- else if eq $secret.type "externalSecret" -}}
    {{- $secret.externalSecret.name | default $default -}}
  {{- else if eq $secret.type "gcpSecretStore" -}}
    {{- $secret.gcpSecretStore.secretProviderClass.name | default $default -}}
  {{- else if eq $secret.type "awsSecretStore" -}}
    {{- $secret.awsSecretStore.secretProviderClass.name | default $default -}}
  {{- else if eq $secret.type "azureKeyVault" -}}
    {{- $secret.azureKeyVault.secretProviderClass.name | default $default -}}
  {{- else -}}
    {{- fail (printf "invalid secret type %q (must be existingSecret, externalSecret, gcpSecretStore, awsSecretStore, or azureKeyVault)" $secret.type) -}}
  {{- end -}}
{{- end -}}

{{/*
Volume definition for a secret block. CSI-backed for gcpSecretStore/awsSecretStore/azureKeyVault, plain Secret otherwise.
include "ccv-cell.secretVolume" (dict "root" . "component" "aggregator" "subComponent" "app")
*/}}
{{- define "ccv-cell.secretVolume" -}}
  {{- $componentRoot := index .root.Values .component -}}
  {{- $secret := index $componentRoot.secrets .subComponent -}}
  {{- $name := include "ccv-cell.secretName" . -}}
  {{- if eq $secret.type "gcpSecretStore" }}
csi:
  driver: secrets-store-gke.csi.k8s.io
  readOnly: true
  volumeAttributes:
    secretProviderClass: {{ $name }}
  {{- else if list "awsSecretStore" "azureKeyVault" | has $secret.type }}
csi:
  driver: secrets-store.csi.k8s.io
  readOnly: true
  volumeAttributes:
    secretProviderClass: {{ $name }}
  {{- else }}
secret:
  secretName: {{ $name }}
  {{- end -}}
{{- end -}}

{{/*
Full SecretProviderClass resource for a CSI-backed secret block (gcpSecretStore/awsSecretStore/azureKeyVault).
include "ccv-cell.secretProviderClass" (dict "root" . "component" "verifier" "subComponent" "app")
*/}}
{{- define "ccv-cell.secretProviderClass" -}}
  {{- $componentRoot := index .root.Values .component -}}
  {{- $secret := index $componentRoot.secrets .subComponent -}}
  {{- $path := printf "%s.secrets.%s" .component .subComponent -}}
  {{- if list "gcpSecretStore" "awsSecretStore" "azureKeyVault" | has $secret.type }}
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: {{ include "ccv-cell.secretName" . }}
  labels:
    {{- include (printf "ccv-cell.%s.labels" .component) .root | nindent 4 }}
    {{- with $secret.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $secret.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
    {{- if eq $secret.type "gcpSecretStore" }}
  provider: gke
  parameters:
    secrets: |
      - resourceName: {{ required (printf "%s.gcpSecretStore.secretVersionResourceName is required when %s.type is gcpSecretStore" $path $path) $secret.gcpSecretStore.secretVersionResourceName | quote }}
        path: "secrets.toml"
    {{- else if eq $secret.type "awsSecretStore" }}
  provider: aws
  parameters:
    objects: |
      - objectName: {{ required (printf "%s.awsSecretStore.secretName is required when %s.type is awsSecretStore" $path $path) $secret.awsSecretStore.secretName | quote }}
        objectType: "secretsmanager"
        objectAlias: "secrets.toml"
    {{- with $secret.awsSecretStore.region }}
    region: {{ . | quote }}
    {{- end }}
    {{- if $secret.awsSecretStore.usePodIdentity }}
    usePodIdentity: "true"
    {{- end }}
    {{- else if eq $secret.type "azureKeyVault" }}
  provider: azure
  parameters:
    usePodIdentity: {{ ternary "true" "false" $secret.azureKeyVault.usePodIdentity | quote }}
    {{- with $secret.azureKeyVault.clientId }}
    clientID: {{ . | quote }}
    {{- end }}
    keyvaultName: {{ required (printf "%s.azureKeyVault.keyvaultName is required when %s.type is azureKeyVault" $path $path) $secret.azureKeyVault.keyvaultName | quote }}
    objects: |
      array:
        - |
          objectName: {{ required (printf "%s.azureKeyVault.secretName is required when %s.type is azureKeyVault" $path $path) $secret.azureKeyVault.secretName | quote }}
          objectType: secret
          objectAlias: secrets.toml
    tenantID: {{ required (printf "%s.azureKeyVault.tenantId is required when %s.type is azureKeyVault" $path $path) $secret.azureKeyVault.tenantId | quote }}
    {{- end }}
  {{- end -}}
{{- end -}}

{{/*
subPath to use when mounting a secret file. CSI-backed types always write "secrets.toml";
existingSecret uses the configured key.
include "ccv-cell.secretSubPath" (dict "root" . "component" "aggregator" "subComponent" "app")
*/}}
{{- define "ccv-cell.secretSubPath" -}}
  {{- $componentRoot := index .root.Values .component -}}
  {{- $secret := index $componentRoot.secrets .subComponent -}}
  {{- if eq $secret.type "existingSecret" -}}
    {{- $secret.existingSecret.key -}}
  {{- else -}}
    secrets.toml
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

{{/*
Fail loudly when keystore settings are supplied on a secret path that cannot use them.
On externalSecret the chart assembles secrets.toml and honours keystoreBackend / kms.*. On every other
type it mounts the operator's file verbatim and cannot inject into it, so those keys were silently
ignored: a cell would come up holding no keystore configuration at all, with nothing in the render or
the logs to say why. Fail instead.
include "ccv-cell.assertKeystoreUsable" (dict "root" . "component" "verifier" "subComponent" "bootstrap")
*/}}
{{- define "ccv-cell.assertKeystoreUsable" -}}
{{- $secret := index .root.Values .component "secrets" .subComponent -}}
{{- if ne $secret.type "externalSecret" -}}
  {{- $set := list -}}
  {{- if and (hasKey $secret "keystoreBackend") (ne (toString $secret.keystoreBackend) "postgres") -}}
    {{- $set = append $set "keystoreBackend" -}}
  {{- end -}}
  {{- if $secret.kms -}}
    {{- if or $secret.kms.provider $secret.kms.ecdsaKeyId $secret.kms.ed25519KeyId -}}
      {{- $set = append $set "kms.*" -}}
    {{- end -}}
  {{- end -}}
  {{- if $set -}}
    {{- fail (printf "%s.secrets.%s sets %s but type is %q. Those keys are only read on type: externalSecret, where the chart assembles secrets.toml for you. On %q you author secrets.toml yourself, so put the [keystore] and [keystore.kms] blocks inside the secret you supply and remove these keys." .component .subComponent (join " and " $set) $secret.type $secret.type) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
