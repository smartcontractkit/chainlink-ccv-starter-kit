# CCV Cell Deployment Runbook

Deploy the [`ccv-cell`](charts/ccv-cell) Helm chart for [Chainlink CCV](https://github.com/smartcontractkit/chainlink-ccv).
Full field reference: the [chart README](charts/ccv-cell/README.md) (generated from [values.yaml](charts/ccv-cell/values.yaml)).

**A CCV Cell is one aggregator plus one verifier (1 pod each).** The verifier watches on-ramps, verifies messages,
signs results, and sends them to an aggregator. The aggregator checks signed results against quorum. Multiple
cells form a **committee**; each cell's Postgres/secrets/KMS isolation requirements are in the chart's
[Requirements](charts/ccv-cell/README.md#requirements).

## 1. Prerequisites

- Cluster and infra dependencies (Gateway/Ingress + mesh, Postgres, secrets manager, KMS, Cloud IAM): see the
  chart's [Requirements](charts/ccv-cell/README.md#requirements).
- Config field reference: `docs/config/` in `chainlink-ccv`:
  [aggregator](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/aggregator/config.documented.toml)·
  [verifier](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/verifier/committee/config.documented.toml)·
  [bootstrap](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/bootstrap/config.documented.toml)·
  [evm](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/evm/config.documented.toml).
  Field names match the chart's `*.config` keys _almost_ 1:1. If you are not sure how to convert, simply write the
  original TOML file, convert it drop the result under the matching `*.config` key.

## 2. Configure the Values

Deployment is done through a standard Helm Chart's values. If this isn't clear to you, check-out [Helm's docs](
https://helm.sh/docs/intro/introduction) before proceeding.

If you've never used Helm, a good starting point it to create a new `my-values.yaml` file, empty, and open on the side
the chart provided `values.yaml`. You can then follow along the original file, and override any values as you need.
Every value accompanies a small snippet documentation, commented out example, or helper link.

We do not recommend you copy the entire file, since you'll have to maintain all values, specially across
updates, making maitenance difficult.

We'll detail here the "important bits" to watch out for.

### Configs

A minimal values file that renders and starts cleanly, with placeholder addresses, `existingSecret`s, and one fake
chain (see bellow for the secrets). Swap in real addresses and RPC URLs before trusting it beyond a smoke test:

```yaml
aggregator:
  config:
    clients:
      - clientId: committee-verifier-1
        groups: ["default"]
        enabled: true
    committee:
      quorumConfigs:
        "1":
          sourceVerifierAddress: "0x00000000000000000000000000000000000000a1"
          threshold: 1
          signers:
            - address: "0x00000000000000000000000000000000000000b1"
      destinationVerifiers:
        "2": "0x00000000000000000000000000000000000000c2"
  secrets:
    app:
      type: existingSecret
      existingSecret:
        name: aggregator-app-secret

verifier:
  config:
    verifier_id: "committee-verifier-1"
    signer_address: "0x00000000000000000000000000000000000000b1"
    aggregators:
      - name: aggregator-1
        secret_name: aggregator_1
        useInClusterAggregator: true
    committee_verifier_addresses:
      "1": "0x00000000000000000000000000000000000000c1"
    on_ramp_addresses:
      "1": "0x00000000000000000000000000000000000000a1"
    rmn_remote_addresses:
      "1": "0x00000000000000000000000000000000000000b1"
  evm:
    config:
      chains:
        "1":
          nodes:
            - name: node-1
              http_url: "https://your-rpc-url"
              order: 1
  secrets:
    app:
      type: existingSecret
      existingSecret:
        name: verifier-app-secret
    bootstrap:
      type: existingSecret
      existingSecret:
        name: verifier-bootstrap-secret
```

The configs here map almost directly to the Verifier's and Aggregators settings, see their links for for info.
Some changes include `useInClusterAggregator: true`, where the chart automatically configures the aggregator that is
also deployed in this chart for the verifier, sparing you from wiring it yourself. Read the values' documentation
for more info as you go.

Keep reading until the end of this guide for some tips and tricks on committee size, and how to organize values for
many ccv-cells deployments.

### Secrets

To configure the application secrets,
Set `type` on each of `aggregator.secrets.app`, `verifier.secrets.app`, `verifier.secrets.bootstrap`
(and optionally `verifier.secrets.evm`):

- **`externalSecret`** (default): chart creates an `ExternalSecret` that pulls from your `SecretStoreRef` via
  `*RemoteRef` fields (e.g. `storageUrlRemoteRef`, per-client `apiKeyRemoteRef`/`secretKeyRemoteRef`).
- **`gcpSecretStore`**: chart creates a `SecretProviderClass` pointing at one `secretVersionResourceName` holding a
  full pre-built `secrets.toml`. Requires Workload Identity on `*.serviceAccount.annotations`.
- **`awsSecretStore`**: chart creates a `SecretProviderClass` using the [AWS ASCP](https://github.com/aws/secrets-store-csi-driver-provider-aws)
  pointing at one `secretName` (name or ARN) in AWS Secrets Manager holding a full pre-built `secrets.toml`.
  Supports both IRSA (annotate the ServiceAccount with `eks.amazonaws.com/role-arn`) and EKS Pod Identity
  (set `awsSecretStore.usePodIdentity: true` and create a Pod Identity association via EKS).
- **`existingSecret`**: you manage the `Secret` yourself, the chart just mounts it.

Both API Keys and Secrets keys are generated by you. `api_key` must be a UUID, `secret_key` must be hex-encoded.

See [Peer information and credential exchange](#8-peer-information-and-credential-exchange) below for a recommendation
on how to exchange credentials between peers.

### Ingress

You can configure an ingress to the aggregator, which must be exposed to the internet, using one of these three values:
```yaml
aggregator:
  ingress:
    enabled: false
    className: "some-ingress"
    host: "your-ccv-aggregator.example.com"

  grpcRoute:
    enabled: false
    annotations: {}
    labels: {}
    parentRefs:
      - group: gateway.networking.k8s.io
        kind: Gateway
        name: gateway
        namespace: istio-ingress
        sectionName: https
    hostnames:
      - "your-ccv-aggregator.example.com"

  httpRoute:
    enabled: false
    parentRefs:
      - group: gateway.networking.k8s.io
        kind: Gateway
        name: gateway
        namespace: istio-ingress
        sectionName: https
    hostnames:
      - "your-ccv-aggregator.example.com"
```

Note that they are all `enabled: false` by default. You only need to enable one. If you don't know which one, contact
your cluster administrator, and they'll be able to guide you properly. Note to them that the aggregator needs a
dedicated and unchanging hostname, exposed to the internet, and is gRPC.

### Resources

While not required, you'll see blocks like these:

```yaml
  # -- CPU/memory resource requests and limits for the <component> container. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).
  resources: {}
    # limits:
    #   cpu: 1500m
    #   memory: 1Gi
    # requests:
    #   cpu: 1
    #   memory: 512Mi

  # -- CPU/memory resource requests and limits for the entire pod. See [resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).
  podResources: {}
    # limits:
    #   cpu: 2
    #   memory: 2Gi
    # requests:
    #   cpu: 1
    #   memory: 1Gi
```

It is highly recommended that you configure resources for any production deployment. Normally, requests and limits
memory must be equal, and request CPU is defined, while limits aren't. The commented out values are a good baseline.
Check with your cluster administrator when in doubt.

### Service Accounts

You'll also see blocks like this:
```yaml
  serviceAccount:
    create: true
    annotations: {}
    labels: {}
    name: ""
```

Service accounts are used by your cloud to allow access from the pods to Secrets, KMS or similar API resources.
Configuring these properly, including name and namespace on the cloud IAM's side, is critical for production use.
Check the comments and your cloud's documentation for more.

### Policy Hooks

The Verifier supports [policy hooks](https://github.com/smartcontractkit/chainlink-ccv/blob/main/verifier/docs/policy_hook.md).
While you can deploy these as part of the chart, using extra containers:
```yaml
verifier:
  config:
    policy_hook:
      base_url: "http://localhost:1234"
      insecure_connection: true
    extraContainers:
      - name: my-policy-hook
        image: my-policy-hook:v1.2.3
```

We recommend a separate deployment/helm install entirely, so you have extra control over the scaling and configuration
of the running container. See the main documentation for more details.

## 3. Deploy

Once you have the values above, you just need to follow standard helm install procedures.

To check runtime behavior before touching a real cluster: [`local/`](local) is a docker-compose stack wired the
same way as this chart. Its [`config/`](local/config) files double as working examples of each `*.config` section
(mapped to chart keys in [local/README.md](local/README.md)).

```bash
NAMESPACE=your-cell-namespace
VALUES=your-values.yaml
RELEASE_NAME=my-cell

helm template "$RELEASE_NAME" ./charts/ccv-cell -f "$VALUES"  # Verify the output and configs first!
helm upgrade --install "$RELEASE_NAME" ./charts/ccv-cell -n "$NAMESPACE" --create-namespace -f "$VALUES"

kubectl -n "$NAMESPACE" get pods
```

To tear down, simply run the relevant Helm commands:

```bash
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
```

See [Helm Docs](https://helm.sh/docs/intro/quickstart) for more information on Helm commands.

> [!NOTE]
> You'll have to tear down any infrastructure setup in the [Prerequisites](#1-prerequisites) yourself!

## 4. Verify it worked

Check the logs:

```bash
kubectl -n "$NAMESPACE" logs sts/my-cell-ccv-cell-aggregator
kubectl -n "$NAMESPACE" logs sts/my-cell-ccv-cell-verifier
```

Aggregator healthy:
```jsonl
{"level":"INFO",...,"msg":"Successfully resolved secrets",...}
{"level":"INFO",...,"msg":"Database connection pool configured",...}
{"level":"INFO",...,"msg":"gRPC server started :50051"}
{"level":"INFO",...,"msg":"Service health summary",...,"overall_status":"ready",...}
```

Verifier healthy:
```jsonl
{"level":"INFO",...,"msg":"Using signer address","address":"0x..."}
{"level":"INFO",...,"logger":"EVMCommitteeVerifier.Node.Lifecycle","msg":"RPC Node is online",...,"nodeState":"Alive"}
{"level":"INFO",...,"msg":"Coordinator started successfully",...}
{"level":"INFO",...,"msg":"🎯 Verifier service fully started and ready!"}
{"level":"INFO",...,"msg":"🌐 HTTP server starting","port":"8100"}
{"level":"INFO",...,"logger":"EVMCommitteeVerifier","msg":"Healthy\n"}
```

> [!TIP]
> Depending on chain RPC connectivity, aggregator connectivity and other patterns, it may take a few moments for the
> verifier to start! Don't panic on a few errors and warnings in the logs for the first minute.

## 5. If a pod won't start

| Symptom                                                      | Cause                                                                                                                                                         |
|--------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Aggregator crash-loops, log mentions committee/quorum        | `committee.quorumConfigs` or `destinationVerifiers` is empty.                                                                                                 |
| Verifier crash-loops: `no enabled/initialized chain sources` | `committee_verifier_addresses`/`on_ramp_addresses` aren't both set for the same chain, or `evm.config.chains` is missing that chain.                          |
| `helm install` fails: `... but no apiKeyRemoteRef`           | A `clients[]`/`aggregators[]` entry is missing its remote-ref while using `externalSecret`.                                                                   |
| CSI mount errors (`gcpSecretStore`)                          | GKE Secret Manager add-on not enabled, or Workload Identity not wired on the ServiceAccount.                                                                  |
| CSI mount errors (`awsSecretStore`)                          | ASCP not installed, IAM role missing `secretsmanager:GetSecretValue`/`DescribeSecret`, or IRSA/Pod Identity not wired on the ServiceAccount.                  |
| Verifier logs show RPC timeouts/429s                         | Public RPC endpoints throttle aggressively under sustained polling. Add dedicated/paid nodes per chain in `evm.config.chains[].nodes` (each with an `order`). |

## 6. Upgrades, rollback, scaling

- `helm upgrade` with a changed config/secret ref is enough for base upgrades.
  - The chart stamps `checksum/config`/`checksum/secrets` pod annotations, so the StatefulSet restarts pods automatically.
  - Database migrations are run at container startup.
  - Pods are recreated, since no two copies of a cell must exist at once. This minimal downtime is expected.
- Rollback: `helm rollback "$RELEASE_NAME" -n "$NAMESPACE"` (see `helm history "$RELEASE_NAME" -n "$NAMESPACE"`).
- Both StatefulSets are hard-coded to `replicas: 1`. Scale a **committee** by deploying more cells (more `helm
  install` releases, each with its own Postgres/secrets/KMS), not by bumping replicas on one release.

## 7. Committee size recommendations

For a production-ready committee, we recommend the following number of members:
- **4 cells with quorum 3**: baseline recommendation, but only tolerates one cell down.
- **7 cells with quorum 5**: tolerates two cells going down, a good middle ground.
- **10 cells with quorum 7**: a strong committee, tolerates up to three cells going down.

We further recommend that cells be spread apart geographically, across different providers, or across different
operators. Consider the single-points of failure in each domain that could compromise a quorum.

> [!IMPORTANT]
> While you can run a committee with only 1 or 2 cells, it is not recommended for production. Such a small amount of
> cells are not fault-tolerant or secure enough for live use.

## 8. Peer information and credential exchange

Each individual combination of verifier and aggregator across all cells of a committee will have one secret key pair.
Because this can get complicated, we recommend the following:
- Name each cell (and helm release) in a predictable manner: use number indexes, or simple identifiers:
  - `helm install ccv-cell-0`, `helm install ccv-cell-1`, `helm install ccv-cell-2`, etc. are easily identifiable.
  - If you deploy one cell per region, that may be a reasonable suffix: `ccv-cell-use1`, `ccv-cell-euw2`, etc.
- Keep hostnames consistent with aggregator names: if you deploy a cell named `ccv-cell-potato` and `ccv-cell-banana`,
  consider hostnames like `aggregator-potato.example.com` and `aggregator-banana.example.com`.
  - Consider the hostname carefully. **Changing it requires updating it in all peers and the indexer**!
- In each cell, references to any other aggregator or verifier can have arbitrary names. We recommend you also keep
  these names consistent across cells, for ease of identification.

As for the credentials, you'll need to generate one key pair for each combination of aggregator and verifier.
Aggregators hold the hostnames, and verifiers hold a signer address that must be shared. If you followed the
recommendation above, you may create a small table, which you can use for the initial peer-info exchange:

|    Verifier \ Aggregator    | aggregator-0<br>`agg-0.example.com`          | aggregator-1<br>`agg-1.example.com`          | aggregator-2<br>`agg-2.example.com`          | aggregator-3<br>`agg-3.example.com`          |
|:---------------------------:|----------------------------------------------|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| **verifier-0**<br>`0x0a...` | `api_key: 0000-...`<br>`secret_key: 0x00...` | `api_key: 0001-...`<br>`secret_key: 0x01...` | `api_key: 0002-...`<br>`secret_key: 0x02...` | `api_key: 0003-...`<br>`secret_key: 0x03...` |
| **verifier-1**<br>`0x1a...` | `api_key: 0010-...`<br>`secret_key: 0x10...` | `api_key: 0011-...`<br>`secret_key: 0x11...` | `api_key: 0012-...`<br>`secret_key: 0x12...` | `api_key: 0013-...`<br>`secret_key: 0x13...` |
| **verifier-2**<br>`0x2a...` | `api_key: 0020-...`<br>`secret_key: 0x20...` | `api_key: 0021-...`<br>`secret_key: 0x21...` | `api_key: 0022-...`<br>`secret_key: 0x22...` | `api_key: 0023-...`<br>`secret_key: 0x23...` |
| **verifier-3**<br>`0x3a...` | `api_key: 0030-...`<br>`secret_key: 0x30...` | `api_key: 0031-...`<br>`secret_key: 0x31...` | `api_key: 0032-...`<br>`secret_key: 0x32...` | `api_key: 0033-...`<br>`secret_key: 0x33...` |

Use this format to go by row or by column filling out the data, depending on if you consider the aggregator or verifier
as the source of truth.

> [!NOTE]
> If your cells are distributed amongst multiple operators, then the table won't be complete, as you shouldn't share
> credentials for cells you don't host or connect to.
>
> Instead, we recommend each operator configure keys at their aggregator for each expected client, then individually
> share the credentials with other operators.

### Reducing repetition with YAML anchors

Values files for multi-chain committees repeat the same addresses and chain selectors many times. YAML anchors help:

```yaml
# Some examples of what you define once at the top of your values file, this structure is fully up to you!
x-addresses:
  resolver: &resolver  0xD5C448Fc5B81EFd3108656Ce5FF9bacF2b582bdB
  signers: &allSigners
    - address: &verifier-0 0x407ac788a176C3C752cb0052cfc3fEA5Bd7307F2
    - address: &verifier-1 0x3311a51f82b41f7e1b39F4EF558fE5BaC74F0657

x-chains:
  - &sepolia "16015286601757825753"
  - &fuji    "14767482510784806043"
  - &amoy    "16281711391670634445"

aggregator:
  config:
    committee:
      destinationVerifiers:
        *sepolia: *resolver
        *fuji:    *resolver
        *amoy:    *resolver
      quorumConfigs:
        *sepolia:
          sourceVerifierAddress: *resolver
          threshold: 2
          # This is one way to define these
          signers:
            - address: *verifier-0
            - address: *verifier-1
        *fuji:
          sourceVerifierAddress: *resolver
          threshold: 2
          # This is equivalent to the one above
          signers: *allSigners
        *amoy:
          sourceVerifierAddress: *resolver
          threshold: 2
          signers: *allSigners

verifier:
  config:
    signer_address: *verifier-0
    committee_verifier_addresses:
      *sepolia: *resolver
      *fuji:    *resolver
      *amoy:    *resolver
```

> [!TIP]
> The `x-*` top-level keys are completely ignored by Helm, they exist only to hold anchors. You can change the structure,
> anchors and values as you see fit without affecting the rest of the chart. If you want to see the end result, try
> `helm template` or `yq 'explode(.)' your-values.yaml`.

## 9. Metrics: deploy an OTel Collector

Both the aggregator and the verifier export metrics over OTLP via Beholder: `aggregator.config.monitoring.Beholder` ·
`verifier.bootstrap.config.Monitoring.Beholder`.

> [!NOTE]
> If you don't already have an OTel collector running in your cluster, deploy one first, see below. If you already
> have one accepting OTLP, skip ahead to [Point ccv-cell at it](#point-ccv-cell-at-it).

### Deploy a collector

Pick one. Both accept OTLP gRPC (`4317`) and HTTP (`4318`) out of the box:

- **[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)** (upstream, vendor-agnostic):
  ```bash
  helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
  helm install otel-collector open-telemetry/opentelemetry-collector -n monitoring --create-namespace \
    --set mode=deployment --set image.repository="otel/opentelemetry-collector-contrib"
  ```
- **[Grafana Alloy](https://grafana.com/docs/alloy/latest/)** (vendor-neutral OTel distribution, Grafana's own
  agent):
  ```bash
  helm repo add grafana https://grafana.github.io/helm-charts
  helm install alloy grafana/alloy -n monitoring --create-namespace
  ```

Either way, the collector needs a pipeline turning received OTLP metrics into something your metrics backend can
ingest. Minimal working example, in Alloy config:

```alloy
otelcol.receiver.otlp "ccv_cell" {
  grpc { endpoint = "0.0.0.0:4317" }
  http { endpoint = "0.0.0.0:4318" }

  output {
    metrics = [otelcol.exporter.prometheus.default.input]
  }
}

otelcol.exporter.prometheus "default" {
  forward_to = [prometheus.remote_write.default.receiver]
}

prometheus.remote_write "default" {
  endpoint {
    url = "https://<your-metrics-backend>/api/v1/write"
  }
}
```

The OTel Collector equivalent is the same shape (`otlp` receiver → `prometheusremotewrite` exporter). See the
[configuration docs](https://opentelemetry.io/docs/collector/configuration/) for exact syntax.

> [!NOTE]
> Nothing here is prescriptive. The collector, the metrics backend it forwards to (Prometheus, Mimir, Grafana Cloud,
> Datadog, ...), and how you eventually visualize the data are all just examples. Use whatever your organization
> already runs.

### Point ccv-cell at it

Set only one of `OtelExporterGRPCEndpoint`/`OtelExporterHTTPEndpoint`, pick whichever protocol your
collector pipeline above is set up to receive on.

```yaml
aggregator:
  config:
    monitoring:
      Beholder:
        Enabled: true
        InsecureConnection: true # unless you terminate TLS in front of the collector
        OtelExporterGRPCEndpoint: "<collector-service>.<namespace>.svc.cluster.local:4317"
  env:
    - name: OTEL_SERVICE_NAME
      value: my-cell-aggregator # otherwise reports as unknown_service:aggregator

verifier:
  bootstrap:
    config:
      Monitoring:
        Beholder:
          Enabled: true
          InsecureConnection: true
          OtelExporterGRPCEndpoint: "<collector-service>.<namespace>.svc.cluster.local:4317"
  env:
    - name: OTEL_SERVICE_NAME
      value: my-cell-verifier
```

Full field reference: the `Beholder` block in the config docs linked under [Prerequisites](#1-prerequisites).
`OTEL_SERVICE_NAME` is the standard OTel env var for naming a service; it's confirmed to work on both the aggregator
and the verifier.
