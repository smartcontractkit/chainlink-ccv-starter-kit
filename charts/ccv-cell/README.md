# ccv-cell

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Chainlink CCIP 2.0 CCV Cell deployment, including aggregator and verifier

**Homepage:** <https://github.com/smartcontractkit/chainlink-ccv>

## Requirements

Kubernetes: `>= 1.19`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aggregator.affinity | object | `{}` | Affinity rules for pod scheduling. See [affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity). |
| aggregator.annotations | object | `{}` | Annotations to add to the aggregator Deployment object. |
| aggregator.configMap.annotations | object | `{}` | Annotations to add to the aggregator ConfigMap. |
| aggregator.configMap.labels | object | `{}` | Labels to add to the aggregator ConfigMap. |
| aggregator.enabled | bool | `true` | Enable the aggregator component. |
| aggregator.env | list | `[]` | Extra environment variables for the aggregator container. See [env](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). |
| aggregator.envFrom | list | `[]` | Extra envFrom sources (ConfigMaps / Secrets) for the aggregator container. See [envFrom](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). |
| aggregator.extraContainers | list | `[]` | Sidecar containers appended to the aggregator pod. See [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/#pod-templates). |
| aggregator.extraInitContainers | list | `[]` | Init containers prepended to the aggregator pod. See [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/). |
| aggregator.extraVolumeMounts | list | `[]` | Extra volume mounts appended to the aggregator container. See [volumes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/). |
| aggregator.extraVolumes | list | `[]` | Extra volumes appended to the aggregator pod. See [volumes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/). |
| aggregator.httpRoute.annotations | object | `{}` | Annotations to add to the HTTPRoute. |
| aggregator.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the aggregator gRPC endpoint. Mutually independent of `ingress.enabled`. |
| aggregator.httpRoute.hostnames | list | `[]` | Hostnames to match. See [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/#api-kind-httproute).    Treat as stable, changing it requires updating every peer and the indexer. |
| aggregator.httpRoute.labels | object | `{}` | Labels to add to the HTTPRoute. |
| aggregator.httpRoute.parentRefs | list | `[]` | Parent Gateway references. See [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/#api-kind-httproute).    Make sure that the endpoint is served under TLS with HTTP/2 end-to-end and with gRPC support. Some controllers    require annotations, while others support it out of the box. |
| aggregator.image.digest | string | `""` | Image digest (`sha256:...`). Mutually exclusive with `tag`. |
| aggregator.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. See [imagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy). |
| aggregator.image.registry | string | `""` | OCI registry, overrides `global.image.registry` when set. |
| aggregator.image.repository | string | `"w0i8p0z9/chainlink-ccv-aggregator"` | Image repository. |
| aggregator.image.tag | string | `"PLACEHOLDER"` | Image tag. Mutually exclusive with `digest`. |
| aggregator.ingress.annotations | object | `{}` | Annotations to add to the Ingress (e.g. controller-specific TLS/HTTP2 or gRPC wiring). |
| aggregator.ingress.className | string | `""` | Ingress class name. See [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).    Make sure that the endpoint is served under TLS with HTTP/2 end-to-end and with gRPC support. Some controllers    require annotations, while others support it out of the box. |
| aggregator.ingress.enabled | bool | `false` | Enable an Ingress for the aggregator gRPC endpoint. |
| aggregator.ingress.host | string | `"your-ccv-aggregator.example.com"` | Hostname for the aggregator. Treat as stable, changing it requires updating every peer and the indexer. |
| aggregator.ingress.labels | object | `{}` | Labels to add to the Ingress. |
| aggregator.ingress.tls.enabled | bool | `false` | Enable TLS for the Ingress. |
| aggregator.ingress.tls.secretName | string | `""` | Name of the TLS Secret. |
| aggregator.labels | object | `{}` | Labels to add to the aggregator Deployment object. |
| aggregator.livenessProbe | object | `{"failureThreshold":10,"httpGet":{"path":"/health/live","port":"health"},"initialDelaySeconds":15,"periodSeconds":15}` | Liveness probe for the aggregator container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| aggregator.networkPolicy.annotations | object | `{}` | Annotations to add to the NetworkPolicy. |
| aggregator.networkPolicy.enabled | bool | `false` | Enable a NetworkPolicy for the aggregator. See [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). |
| aggregator.networkPolicy.ingress | list | `[{"from":[{"podSelector":{}}]}]` | Ingress rules for the NetworkPolicy. When enabled, add a rule allowing traffic from your ingress/gateway controller. Each rule's `ports` defaults to the aggregator's own ports when omitted. See [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). |
| aggregator.networkPolicy.labels | object | `{}` | Labels to add to the NetworkPolicy. |
| aggregator.nodeSelector | object | `{}` | Node selector for pod scheduling. See [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector). |
| aggregator.podAnnotations | object | `{}` | Annotations to add to the aggregator pods. |
| aggregator.podLabels | object | `{}` | Labels to add to the aggregator pods. |
| aggregator.podResources | object | `{}` | CPU/memory resource requests and limits for init/sidecar containers. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/). |
| aggregator.podSecurityContext | object | `{"seccompProfile":{"type":"RuntimeDefault"}}` | Security context applied at the pod level. See [podSecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/). |
| aggregator.readinessProbe | object | `{"httpGet":{"path":"/health/ready","port":"health"},"initialDelaySeconds":5,"periodSeconds":10}` | Readiness probe for the aggregator container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| aggregator.resources | object | `{}` | CPU/memory resource requests and limits for the aggregator container. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/). |
| aggregator.secrets.app.annotations | object | `{}` | Annotations to add to the aggregator app Secret. |
| aggregator.secrets.app.existingSecret.key | string | `"secrets.toml"` | Key inside the existing Secret that holds the secrets file. |
| aggregator.secrets.app.existingSecret.name | string | `""` | Name of an existing Kubernetes Secret to use as the app secret. |
| aggregator.secrets.app.externalSecret.clients | list | `[]` | Per-client API/secret key remote refs. |
| aggregator.secrets.app.externalSecret.name | string | `""` | Name of the ExternalSecret resource to create. |
| aggregator.secrets.app.externalSecret.secretStoreRef | object | `{"kind":"ClusterSecretStore","name":""}` | SecretStore reference for the ExternalSecret. |
| aggregator.secrets.app.externalSecret.storageUrlRemoteRef | object | `{}` | RemoteRef for the storage URL secret. |
| aggregator.secrets.app.gcpSecretStore | object | `{"fileName":"secrets.toml","secretProviderClass":{"name":""},"secretVersionResourceName":""}` | GCP Secret Manager, mounted via the [Secret Manager add-on for the Secrets Store CSI Driver](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component).    Requires the add-on enabled on the GKE cluster and Workload Identity Federation configured for `aggregator.serviceAccount` as described in    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
| aggregator.secrets.app.gcpSecretStore.fileName | string | `"secrets.toml"` | Filename the CSI driver mounts the secret content as. |
| aggregator.secrets.app.gcpSecretStore.secretProviderClass.name | string | `""` | Name of the SecretProviderClass resource to create. |
| aggregator.secrets.app.gcpSecretStore.secretVersionResourceName | string | `""` | Fully-qualified GCP Secret Manager secret version resource name, e.g. `projects/<project>/secrets/<secret>/versions/latest`. |
| aggregator.secrets.app.labels | object | `{}` | Labels to add to the aggregator app Secret. |
| aggregator.secrets.app.type | string | `"externalSecret"` | Secret provisioning strategy: `externalSecret`, `existingSecret`, or `gcpSecretStore`. |
| aggregator.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. For GKE Workload Identity Federation (required by `aggregator.secrets.app.gcpSecretStore`),    set `iam.gke.io/gcp-service-account` to the Google service account bound to this KSA. See    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
| aggregator.serviceAccount.create | bool | `true` | Create a dedicated ServiceAccount for the aggregator. |
| aggregator.serviceAccount.labels | object | `{}` | Labels to add to the ServiceAccount. |
| aggregator.serviceAccount.name | string | `""` | Use an existing ServiceAccount instead of creating one; ignored when `create` is true. |
| aggregator.shareProcessNamespace | bool | `false` | Share a single process namespace across all containers in the pod. See [shareProcessNamespace](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/). |
| aggregator.startupProbe | string | `nil` | Startup probe for the aggregator container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| aggregator.tolerations | list | `[]` | Tolerations for pod scheduling. See [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/). |
| fullnameOverride | string | `""` | Override the fully-qualified resource name. |
| global.image | object | `{"registry":"public.ecr.aws"}` | Default OCI registry for all images; overridden per-component by setting `image.registry`. |
| global.imagePullSecrets | list | `[]` | Image pull secrets to add to every pod. See [imagePullSecrets](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod). |
| global.labels | object | `{}` | Labels added to every resource created by this chart. |
| nameOverride | string | `""` | Override the chart name used in resource names. |
| verifier.affinity | object | `{}` | Affinity rules for pod scheduling. See [affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity). |
| verifier.annotations | object | `{}` | Annotations to add to the verifier Deployment object. |
| verifier.configMap.annotations | object | `{}` | Annotations to add to the verifier ConfigMap. |
| verifier.configMap.labels | object | `{}` | Labels to add to the verifier ConfigMap. |
| verifier.enabled | bool | `true` | Enable the verifier component. |
| verifier.env | list | `[]` | Extra environment variables for the verifier container. See [env](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). |
| verifier.envFrom | list | `[]` | Extra envFrom sources (ConfigMaps / Secrets) for the verifier container. See [envFrom](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). |
| verifier.extraContainers | list | `[]` | Sidecar containers appended to the verifier pod. See [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/#pod-templates). |
| verifier.extraInitContainers | list | `[]` | Init containers prepended to the verifier pod. See [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/). |
| verifier.extraVolumeMounts | list | `[]` | Extra volume mounts appended to the verifier container. See [volumes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/). |
| verifier.extraVolumes | list | `[]` | Extra volumes appended to the verifier pod. See [volumes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/). |
| verifier.image.digest | string | `""` | Image digest (`sha256:...`). Mutually exclusive with `tag`. |
| verifier.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. See [imagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy). |
| verifier.image.registry | string | `""` | OCI registry; overrides `global.image.registry` when set. |
| verifier.image.repository | string | `"w0i8p0z9/chainlink-ccv-verifier"` | Image repository. |
| verifier.image.tag | string | `"PLACEHOLDER"` | Image tag. Mutually exclusive with `digest`. |
| verifier.labels | object | `{}` | Labels to add to the verifier Deployment object. |
| verifier.livenessProbe | object | `{"failureThreshold":10,"httpGet":{"path":"/health","port":"http"},"initialDelaySeconds":15,"periodSeconds":15}` | Liveness probe for the verifier container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| verifier.networkPolicy.annotations | object | `{}` | Annotations to add to the NetworkPolicy. |
| verifier.networkPolicy.enabled | bool | `false` | Enable a NetworkPolicy for the verifier. See [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). |
| verifier.networkPolicy.ingress | list | `[{"from":[{"podSelector":{}}]}]` | Ingress rules for the NetworkPolicy. Each rule's `ports` defaults to the verifier's own ports when omitted. See [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). |
| verifier.networkPolicy.labels | object | `{}` | Labels to add to the NetworkPolicy. |
| verifier.nodeSelector | object | `{}` | Node selector for pod scheduling. See [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector). |
| verifier.podAnnotations | object | `{}` | Annotations to add to the verifier pods. |
| verifier.podLabels | object | `{}` | Labels to add to the verifier pods. |
| verifier.podResources | object | `{}` | CPU/memory resource requests and limits for init/sidecar containers. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/). |
| verifier.podSecurityContext | object | `{"seccompProfile":{"type":"RuntimeDefault"}}` | Security context applied at the pod level. See [podSecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/). |
| verifier.readinessProbe | object | `{"httpGet":{"path":"/ready","port":"bootstrap-info"},"initialDelaySeconds":5,"periodSeconds":10}` | Readiness probe for the verifier container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| verifier.resources | object | `{}` | CPU/memory resource requests and limits for the verifier container. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/). |
| verifier.secrets.app.annotations | object | `{}` | Annotations to add to the verifier app Secret. |
| verifier.secrets.app.existingSecret.key | string | `"secrets.toml"` | Key inside the existing Secret that holds the secrets file. |
| verifier.secrets.app.existingSecret.name | string | `""` | Name of an existing Kubernetes Secret to use as the app secret. |
| verifier.secrets.app.externalSecret.aggregators | list | `[]` | Per-aggregator API/secret key remote refs. |
| verifier.secrets.app.externalSecret.dbUrlRemoteRef | object | `{}` | RemoteRef for the database URL secret. |
| verifier.secrets.app.externalSecret.name | string | `""` | Name of the ExternalSecret resource to create. |
| verifier.secrets.app.externalSecret.secretStoreRef | object | `{"kind":"ClusterSecretStore","name":""}` | SecretStore reference for the ExternalSecret. |
| verifier.secrets.app.gcpSecretStore | object | `{"fileName":"secrets.toml","secretProviderClass":{"name":""},"secretVersionResourceName":""}` | GCP Secret Manager, mounted via the [Secret Manager add-on for the Secrets Store CSI Driver](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component).    Requires the add-on enabled on the GKE cluster and Workload Identity Federation configured for `verifier.serviceAccount` as described in    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
| verifier.secrets.app.gcpSecretStore.fileName | string | `"secrets.toml"` | Filename the CSI driver mounts the secret content as. |
| verifier.secrets.app.gcpSecretStore.secretProviderClass.name | string | `""` | Name of the SecretProviderClass resource to create. |
| verifier.secrets.app.gcpSecretStore.secretVersionResourceName | string | `""` | Fully-qualified GCP Secret Manager secret version resource name, e.g. `projects/<project>/secrets/<secret>/versions/latest`. |
| verifier.secrets.app.labels | object | `{}` | Labels to add to the verifier app Secret. |
| verifier.secrets.app.type | string | `"externalSecret"` | Secret provisioning strategy: `externalSecret`, `existingSecret`, or `gcpSecretStore`. |
| verifier.secrets.bootstrap.annotations | object | `{}` | Annotations to add to the verifier bootstrap Secret. |
| verifier.secrets.bootstrap.existingSecret.key | string | `"secrets.toml"` | Key inside the existing Secret that holds the secrets file. |
| verifier.secrets.bootstrap.existingSecret.name | string | `""` | Name of an existing Kubernetes Secret to use as the bootstrap secret. |
| verifier.secrets.bootstrap.externalSecret.dbUrlRemoteRef | object | `{}` | RemoteRef for the database URL secret. |
| verifier.secrets.bootstrap.externalSecret.keystorePasswordRemoteRef | object | `{}` | RemoteRef for the keystore password (only when `keystoreBackend` is `postgres`). |
| verifier.secrets.bootstrap.externalSecret.name | string | `""` | Name of the ExternalSecret resource to create. |
| verifier.secrets.bootstrap.externalSecret.secretStoreRef | object | `{"kind":"ClusterSecretStore","name":""}` | SecretStore reference for the ExternalSecret. |
| verifier.secrets.bootstrap.gcpSecretStore | object | `{"fileName":"secrets.toml","secretProviderClass":{"name":""},"secretVersionResourceName":""}` | GCP Secret Manager, mounted via the [Secret Manager add-on for the Secrets Store CSI Driver](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component).    Requires the add-on enabled on the GKE cluster and Workload Identity Federation configured for `verifier.serviceAccount` as described in    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
| verifier.secrets.bootstrap.gcpSecretStore.fileName | string | `"secrets.toml"` | Filename the CSI driver mounts the secret content as. |
| verifier.secrets.bootstrap.gcpSecretStore.secretProviderClass.name | string | `""` | Name of the SecretProviderClass resource to create. |
| verifier.secrets.bootstrap.gcpSecretStore.secretVersionResourceName | string | `""` | Fully-qualified GCP Secret Manager secret version resource name, e.g. `projects/<project>/secrets/<secret>/versions/latest`. |
| verifier.secrets.bootstrap.keystoreBackend | string | `"postgres"` | Keystore backend: `postgres` or `kms`. |
| verifier.secrets.bootstrap.kms.ecdsaKeyId | string | `""` | AWS KMS key ID for the ECDSA key (only when `keystoreBackend` is `kms`). |
| verifier.secrets.bootstrap.kms.ed25519KeyId | string | `""` | AWS KMS key ID for the Ed25519 key (only when `keystoreBackend` is `kms`). |
| verifier.secrets.bootstrap.labels | object | `{}` | Labels to add to the verifier bootstrap Secret. |
| verifier.secrets.bootstrap.type | string | `"externalSecret"` | Secret provisioning strategy: `externalSecret`, `existingSecret`, or `gcpSecretStore`. |
| verifier.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. For GKE Workload Identity Federation (required by `verifier.secrets.*.gcpSecretStore`),    set `iam.gke.io/gcp-service-account` to the Google service account bound to this KSA. See    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
| verifier.serviceAccount.create | bool | `true` | Create a dedicated ServiceAccount for the verifier, usually used for OIDC auth with your cloud provider. |
| verifier.serviceAccount.labels | object | `{}` | Labels to add to the ServiceAccount. |
| verifier.serviceAccount.name | string | `""` | Use an existing ServiceAccount instead of creating one; ignored when `create` is true. |
| verifier.shareProcessNamespace | bool | `false` | Share a single process namespace across all containers in the pod. See [shareProcessNamespace](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/). |
| verifier.startupProbe | string | `nil` | Startup probe for the verifier container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| verifier.tolerations | list | `[]` | Tolerations for pod scheduling. See [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/). |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
