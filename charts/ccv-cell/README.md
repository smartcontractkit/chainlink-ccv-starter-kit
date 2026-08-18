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
| aggregator.config.aggregation.backgroundWorkerCount | int | `10` | Number of background workers processing aggregation requests. |
| aggregator.config.aggregation.channelBufferSize | int | `200` | Buffer size of the aggregation request channel. |
| aggregator.config.aggregation.drainTimeout | string | `"10s"` | How long shutdown waits for in-flight aggregation workers before proceeding anyway. |
| aggregator.config.aggregation.maxConsecutiveErrors | int | `0` | Maximum consecutive errors before aggregation is considered failed. 0 disables the check. |
| aggregator.config.aggregation.operationTimeout | string | `"0s"` | Timeout for each aggregation operation. 0 disables the timeout. |
| aggregator.config.aggregatorID | string | `""` | Unique identifier for this aggregator instance. An empty value defaults to the pod's hostname,    which is already stable and unique per replica. |
| aggregator.config.clients | list | `[]` | Authenticated API clients. `apiKeyRemoteRef`/`secretKeyRemoteRef` (used only when    `aggregator.secrets.app.type` is `externalSecret`) tell the ExternalSecret where to fetch the    matching API key/secret key for this same `clientId`. Both are chart-only fields and are not    written to `config.toml`. |
| aggregator.config.committee | object | `{"destinationVerifiers":{},"quorumConfigs":{}}` | Signer quorums and destination verifiers this aggregator trusts. Empty by default: this is    deployment-specific and has no safe default. |
| aggregator.config.committee.destinationVerifiers | object | `{}` | Destination verifier contract address per destination chain selector. |
| aggregator.config.committee.quorumConfigs | object | `{}` | Quorum config per source chain selector. |
| aggregator.config.generatedConfigPath | string | `""` | Path to a generated config file merged over this one. Rarely needed. |
| aggregator.config.healthCheck.enabled | bool | `true` | Enable the health-check HTTP server. This chart's liveness/readiness probes require it; do    not disable it unless you replace those probes too. |
| aggregator.config.healthCheck.port | int | `8080` | Port the health-check HTTP server listens on. |
| aggregator.config.heartbeat.storeType | string | `"memory"` | Heartbeat storage backend: `memory` or `redis`. |
| aggregator.config.maxCommitVerifierNodeResultRequestsPerBatch | int | `100` | Maximum verifier-result requests per batch, from 1 to 1000. |
| aggregator.config.maxMessageIDsPerBatch | int | `100` | Maximum message IDs per batch request, from 1 to 1000. |
| aggregator.config.messageDisablementRules.refreshInterval | string | `"30s"` | How often the in-memory message-disablement registry refreshes from the database. |
| aggregator.config.monitoring.Beholder.CACertFile | string | `""` | Path to the CA certificate file for the Beholder client. |
| aggregator.config.monitoring.Beholder.Enabled | bool | `false` | Enable Beholder telemetry. |
| aggregator.config.monitoring.Beholder.InsecureConnection | bool | `false` | Disable TLS for the Beholder client. |
| aggregator.config.monitoring.Beholder.LogStreamingEnabled | bool | `false` | Enable log streaming to the collector. |
| aggregator.config.monitoring.Beholder.LogStreamingLevel | string | `"info"` | Minimum log level to stream to Beholder. |
| aggregator.config.monitoring.Beholder.MetricReaderInterval | int | `0` | Interval to scrape metrics, in seconds. |
| aggregator.config.monitoring.Beholder.OtelExporterGRPCEndpoint | string | `""` | gRPC endpoint for the Beholder client to send data to the collector. |
| aggregator.config.monitoring.Beholder.OtelExporterHTTPEndpoint | string | `""` | HTTP endpoint for the Beholder client to send data to the collector. |
| aggregator.config.monitoring.Beholder.TraceBatchTimeout | int | `0` | Timeout for a batch of traces. |
| aggregator.config.monitoring.Beholder.TraceSampleRatio | float | `0` | Ratio of traces to sample. |
| aggregator.config.monitoring.LogLevel | string | `"info"` | Log level for the service logger. |
| aggregator.config.monitoring.Pyroscope.Enabled | bool | `false` | Enable Pyroscope telemetry. |
| aggregator.config.monitoring.Pyroscope.URL | string | `""` | Remote endpoint of the Pyroscope service. |
| aggregator.config.orphanRecovery.checkAggregationTimeout | string | `"5s"` | Timeout for each check-aggregation operation. |
| aggregator.config.orphanRecovery.enabled | bool | `false` | Enable recovery of orphaned aggregation records. |
| aggregator.config.orphanRecovery.interval | string | `"5m0s"` | How often orphan recovery runs. |
| aggregator.config.orphanRecovery.maxAge | string | `"168h0m0s"` | Maximum age of orphan records to consider for recovery. Older records are skipped. |
| aggregator.config.orphanRecovery.maxConsecutiveErrors | int | `3` | Maximum consecutive errors before orphan recovery is considered failed. |
| aggregator.config.orphanRecovery.maxOrphansPerScan | int | `10000` | Maximum orphans processed per scan cycle. |
| aggregator.config.orphanRecovery.pageSize | int | `100` | Orphaned keys fetched per database page during a scan. |
| aggregator.config.orphanRecovery.scanTimeout | string | `"4m0s"` | Timeout for each orphan recovery scan. |
| aggregator.config.pyroscope_url | string | `""` | Pyroscope server URL for continuous profiling. An empty value disables it. |
| aggregator.config.rateLimiting.enabled | bool | `false` | Enable rate limiting. |
| aggregator.config.rateLimiting.storage.type | string | `"memory"` | Rate-limit storage backend: `memory` or `redis`. |
| aggregator.config.server.connectionTimeout | string | `"0s"` | Timeout for connection establishment. Empty uses the gRPC default (no timeout). |
| aggregator.config.server.host | string | `""` | Host the gRPC server binds to. Leave empty to bind all interfaces, which is almost always    what you want in a container. |
| aggregator.config.server.keepaliveMinTime | string | `"0s"` | Minimum time between client pings. Empty uses the gRPC default (5m). |
| aggregator.config.server.keepaliveTime | string | `"0s"` | Time after which the server pings idle clients. Empty uses the gRPC default (2h). |
| aggregator.config.server.keepaliveTimeout | string | `"0s"` | Timeout for a ping ack before closing the connection. Empty uses the gRPC default (20s). |
| aggregator.config.server.maxConnectionAge | string | `"0s"` | Forces connections closed after this duration. Empty uses the gRPC default (no limit). |
| aggregator.config.server.maxRecvMsgSizeBytes | int | `0` | Maximum message size the server can receive, in bytes. 0 uses the default (4MB). |
| aggregator.config.server.maxSendMsgSizeBytes | int | `0` | Maximum message size the server can send, in bytes. 0 uses the default (4MB). |
| aggregator.config.server.port | int | `50051` | Port the gRPC server listens on. |
| aggregator.config.server.requestTimeout | string | `"10s"` | Maximum duration for any gRPC request. |
| aggregator.config.storage.connMaxIdleTime | string | `"5m0s"` | Maximum time a database connection may sit idle before it's closed. |
| aggregator.config.storage.connMaxLifetime | string | `"1h0m0s"` | Maximum lifetime of a database connection. |
| aggregator.config.storage.maxIdleConns | int | `5` | Maximum idle database connections. |
| aggregator.config.storage.maxOpenConns | int | `25` | Maximum open database connections. |
| aggregator.config.storage.pageSize | int | `100` | Records fetched per page in paginated queries. |
| aggregator.config.storage.queryTimeout | string | `"10s"` | Timeout for a single database query. |
| aggregator.config.storage.type | string | `"postgres"` | Storage backend. Only `postgres` is supported. |
| aggregator.configMap.annotations | object | `{}` | Annotations to add to the aggregator ConfigMap. |
| aggregator.configMap.labels | object | `{}` | Labels to add to the aggregator ConfigMap. |
| aggregator.enabled | bool | `true` | Enable the aggregator component. |
| aggregator.env | list | `[]` | Extra environment variables for the aggregator container. See [env](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). |
| aggregator.envFrom | list | `[]` | Extra envFrom sources (ConfigMaps / Secrets) for the aggregator container. See [envFrom](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). |
| aggregator.extraContainers | list | `[]` | Sidecar containers appended to the aggregator pod. See [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/#pod-templates). |
| aggregator.extraInitContainers | list | `[]` | Init containers prepended to the aggregator pod. See [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/). |
| aggregator.extraVolumeMounts | list | `[]` | Extra volume mounts appended to the aggregator container. See [volumes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/). |
| aggregator.extraVolumes | list | `[]` | Extra volumes appended to the aggregator pod. See [volumes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/). |
| aggregator.grpcRoute.annotations | object | `{}` | Annotations to add to the GRPCRoute. |
| aggregator.grpcRoute.enabled | bool | `false` | Enable a Gateway API GRPCRoute for the aggregator gRPC endpoint. **Preferred over `httpRoute`** when your    gateway controller supports it. Mutually independent of `ingress.enabled` and `httpRoute.enabled`. |
| aggregator.grpcRoute.hostnames | list | `[]` | Hostnames to match. See [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/#api-kind-grpcroute).    Treat as stable, changing it requires updating every peer and the indexer. |
| aggregator.grpcRoute.labels | object | `{}` | Labels to add to the GRPCRoute. |
| aggregator.grpcRoute.parentRefs | list | `[]` | Parent Gateway references. See [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/#api-kind-grpcroute).    Make sure that the endpoint is served under TLS with HTTP/2 end-to-end and with gRPC support. Some controllers    require annotations, while others support it out of the box. |
| aggregator.httpRoute.annotations | object | `{}` | Annotations to add to the HTTPRoute. |
| aggregator.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the aggregator gRPC endpoint. Only needed as a fallback when your gateway    controller doesn't yet support GRPCRoute (see `grpcRoute` above, which is preferred for gRPC traffic when    available). Mutually independent of `ingress.enabled` and `grpcRoute.enabled`. |
| aggregator.httpRoute.hostnames | list | `[]` | Hostnames to match. See [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/#api-kind-httproute).    Treat as stable, changing it requires updating every peer and the indexer. |
| aggregator.httpRoute.labels | object | `{}` | Labels to add to the HTTPRoute. |
| aggregator.httpRoute.parentRefs | list | `[]` | Parent Gateway references. See [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/#api-kind-httproute).    Make sure that the endpoint is served under TLS with HTTP/2 end-to-end and with gRPC support. Some controllers    require annotations, while others support it out of the box. |
| aggregator.image.digest | string | `""` | Image digest (`sha256:...`). Mutually exclusive with `tag`. |
| aggregator.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. See [imagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy). |
| aggregator.image.registry | string | `""` | OCI registry, overrides `global.image.registry` when set. |
| aggregator.image.repository | string | `"w0i8p0z9/chainlink-ccv-aggregator"` | Image repository. |
| aggregator.image.tag | string | `"v0.3.0"` | Image tag. Mutually exclusive with `digest`. |
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
| aggregator.secrets.app.externalSecret.name | string | `""` | Name of the ExternalSecret resource to create. |
| aggregator.secrets.app.externalSecret.secretStoreRef | object | `{"kind":"ClusterSecretStore","name":""}` | SecretStore reference for the ExternalSecret. |
| aggregator.secrets.app.externalSecret.storageUrlRemoteRef | object | `{}` | RemoteRef for the storage URL secret. |
| aggregator.secrets.app.gcpSecretStore | object | `{"secretProviderClass":{"name":""},"secretVersionResourceName":""}` | GCP Secret Manager, mounted via the [Secret Manager add-on for the Secrets Store CSI Driver](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component).    Requires the add-on enabled on the GKE cluster and Workload Identity Federation configured for `aggregator.serviceAccount` as described in    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
| aggregator.secrets.app.gcpSecretStore.secretProviderClass.name | string | `""` | Name of the SecretProviderClass resource to create. |
| aggregator.secrets.app.gcpSecretStore.secretVersionResourceName | string | `""` | Fully-qualified GCP Secret Manager secret version resource name, e.g. `projects/<project>/secrets/<secret>/versions/latest`. |
| aggregator.secrets.app.labels | object | `{}` | Labels to add to the aggregator app Secret. |
| aggregator.secrets.app.type | string | `"externalSecret"` | Secret provisioning strategy: `externalSecret`, `existingSecret`, or `gcpSecretStore`. |
| aggregator.service.annotations | object | `{}` | Annotations to add to the aggregator Service. |
| aggregator.service.clusterIP | string | `""` | Static ClusterIP to assign to the Service. Leave empty to let Kubernetes allocate one. |
| aggregator.service.labels | object | `{}` | Labels to add to the aggregator Service. |
| aggregator.service.type | string | `"ClusterIP"` | Service type. See [Service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types). |
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
| verifier.bootstrap.config.Monitoring.Beholder.CACertFile | string | `"/etc/ssl/certs/otel-collector.pem"` | Path to the CA certificate file for the Beholder client. |
| verifier.bootstrap.config.Monitoring.Beholder.Enabled | bool | `false` | Enable Beholder telemetry. |
| verifier.bootstrap.config.Monitoring.Beholder.InsecureConnection | bool | `true` | Disable TLS for the Beholder client. |
| verifier.bootstrap.config.Monitoring.Beholder.LogStreamingEnabled | bool | `false` | Enable log streaming to the collector. |
| verifier.bootstrap.config.Monitoring.Beholder.LogStreamingLevel | string | `"info"` | Minimum log level to stream to Beholder. |
| verifier.bootstrap.config.Monitoring.Beholder.MetricReaderInterval | int | `60` | Interval to scrape metrics, in seconds. |
| verifier.bootstrap.config.Monitoring.Beholder.OtelExporterGRPCEndpoint | string | `"otel-collector:4317"` | gRPC endpoint for the Beholder client to send data to the collector. |
| verifier.bootstrap.config.Monitoring.Beholder.OtelExporterHTTPEndpoint | string | `"otel-collector:4318"` | HTTP endpoint for the Beholder client to send data to the collector. |
| verifier.bootstrap.config.Monitoring.Beholder.TelemetryAttributes | object | `{}` | Extra labels to add during OTel transmission. |
| verifier.bootstrap.config.Monitoring.Beholder.TraceBatchTimeout | int | `5` | Timeout for a batch of traces, in seconds. |
| verifier.bootstrap.config.Monitoring.Beholder.TraceSampleRatio | float | `0.1` | Ratio of traces to sample. |
| verifier.bootstrap.config.Monitoring.LogLevel | string | `"info"` | Log level for the service logger. |
| verifier.bootstrap.config.Monitoring.Pyroscope.Enabled | bool | `false` | Enable Pyroscope telemetry. |
| verifier.bootstrap.config.Monitoring.Pyroscope.URL | string | `"http://pyroscope:4040"` | Remote endpoint of the Pyroscope service. |
| verifier.bootstrap.config.chains | list | `[]` | List of chains where this node has a signing identity. Each entry registers the node's signing    key for that chain in JD. Empty performs no signing-key sync. |
| verifier.bootstrap.config.local_app_config_path | string | `"/etc/committee-verifier/config.toml"` | Path to the application config file for local mode. This file holds the application config,    not the bootstrap config. |
| verifier.bootstrap.config.server.listen_port | int | `9988` | Port for the bootstrap HTTP server. |
| verifier.config.aggregators | list | `[]` | Aggregators that this verifier writes to.    Set `useInClusterAggregator: true` to use the aggregator this chart release deploys, or set    `address` for any other aggregator. `secret_name` doubles as the credential lookup key for    `apiKeyRemoteRef`/`secretKeyRemoteRef` (used only when `verifier.secrets.app.type` is    `externalSecret`). `useInClusterAggregator`, `apiKeyRemoteRef`, and `secretKeyRemoteRef` are    chart-only fields and are not written to `config.toml`. |
| verifier.config.committee_verifier_addresses | object | `{}` | Addresses of the committee verifiers, one per chain selector. |
| verifier.config.default_executor_on_ramp_addresses | object | `{}` | Addresses of the default executor on-ramps, one per chain selector. Messages naming the default    executor are verified even if they don't name this committee verifier. |
| verifier.config.disable_finality_checkers | list | `[]` | Chain selectors, as strings, for which to disable the finality violation checker. |
| verifier.config.message_disablement_rules_client_timeout | string | `"500ms"` | Go duration string for the message-disablement-rules RPC timeout (e.g. `"500ms"`). Empty uses the    integration default. |
| verifier.config.message_disablement_rules_poll_interval | string | `"2s"` | Go duration string for the message-disablement-rules poll interval (e.g. `"2s"`). Empty uses the    integration default. |
| verifier.config.on_ramp_addresses | object | `{}` | Addresses of the on-ramps, one per chain selector. |
| verifier.config.pyroscope_url | string | `""` | Pyroscope server URL for continuous profiling. An empty value disables it. |
| verifier.config.rmn_remote_addresses | object | `{}` | Addresses of the RMN Remote contracts, one per chain selector. Required for curse detection. |
| verifier.config.signer_address | string | `""` | On-chain address of this verifier's result-signing key. Set a different value for each verifier. |
| verifier.config.verifier_id | string | `""` | Unique identifier for this committee verifier instance. Set a different value for each verifier    in the committee. |
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
| verifier.image.tag | string | `"v0.3.0"` | Image tag. Mutually exclusive with `digest`. |
| verifier.labels | object | `{}` | Labels to add to the verifier Deployment object. |
| verifier.livenessProbe | object | `{"failureThreshold":10,"httpGet":{"path":"/health","port":"bootstrap-info"},"initialDelaySeconds":15,"periodSeconds":15}` | Liveness probe for the verifier container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| verifier.networkPolicy.annotations | object | `{}` | Annotations to add to the NetworkPolicy. |
| verifier.networkPolicy.enabled | bool | `false` | Enable a NetworkPolicy for the verifier. See [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). |
| verifier.networkPolicy.ingress | list | `[{"from":[{"podSelector":{}}]}]` | Ingress rules for the NetworkPolicy. Each rule's `ports` defaults to the verifier's own ports when omitted. See [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). |
| verifier.networkPolicy.labels | object | `{}` | Labels to add to the NetworkPolicy. |
| verifier.nodeSelector | object | `{}` | Node selector for pod scheduling. See [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector). |
| verifier.podAnnotations | object | `{}` | Annotations to add to the verifier pods. |
| verifier.podLabels | object | `{}` | Labels to add to the verifier pods. |
| verifier.podResources | object | `{}` | CPU/memory resource requests and limits for init/sidecar containers. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/). |
| verifier.podSecurityContext | object | `{"seccompProfile":{"type":"RuntimeDefault"}}` | Security context applied at the pod level. See [podSecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/). |
| verifier.readinessProbe | object | `{"httpGet":{"path":"/health","port":"http"},"initialDelaySeconds":5,"periodSeconds":10}` | Readiness probe for the verifier container. See [probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/). |
| verifier.resources | object | `{}` | CPU/memory resource requests and limits for the verifier container. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/). |
| verifier.secrets.app.annotations | object | `{}` | Annotations to add to the verifier app Secret. |
| verifier.secrets.app.existingSecret.key | string | `"secrets.toml"` | Key inside the existing Secret that holds the secrets file. |
| verifier.secrets.app.existingSecret.name | string | `""` | Name of an existing Kubernetes Secret to use as the app secret. |
| verifier.secrets.app.externalSecret.dbUrlRemoteRef | object | `{}` | RemoteRef for the database URL secret. |
| verifier.secrets.app.externalSecret.name | string | `""` | Name of the ExternalSecret resource to create. |
| verifier.secrets.app.externalSecret.secretStoreRef | object | `{"kind":"ClusterSecretStore","name":""}` | SecretStore reference for the ExternalSecret. |
| verifier.secrets.app.gcpSecretStore | object | `{"secretProviderClass":{"name":""},"secretVersionResourceName":""}` | GCP Secret Manager, mounted via the [Secret Manager add-on for the Secrets Store CSI Driver](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component).    Requires the add-on enabled on the GKE cluster and Workload Identity Federation configured for `verifier.serviceAccount` as described in    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
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
| verifier.secrets.bootstrap.gcpSecretStore | object | `{"secretProviderClass":{"name":""},"secretVersionResourceName":""}` | GCP Secret Manager, mounted via the [Secret Manager add-on for the Secrets Store CSI Driver](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component).    Requires the add-on enabled on the GKE cluster and Workload Identity Federation configured for `verifier.serviceAccount` as described in    [Configure Workload Identity](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#configure-workload-identity). |
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
