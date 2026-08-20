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
  [aggregator](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/aggregator/config.documented.toml) ·
  [verifier](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/verifier/committee/config.documented.toml) ·
  [bootstrap](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/bootstrap/config.documented.toml) ·
  [evm](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/evm/config.documented.toml).
  Field names match the chart's `*.config` keys 1:1. Converting from TOML: convert it (don't hand-transcribe) and
  drop the result under the matching `*.config` key.

## 2. Wire up secrets

Set `type` on each of `aggregator.secrets.app`, `verifier.secrets.app`, `verifier.secrets.bootstrap`:

- **`externalSecret`** (default): chart creates an `ExternalSecret` that pulls from your `SecretStoreRef` via
  `*RemoteRef` fields (e.g. `storageUrlRemoteRef`, per-client `apiKeyRemoteRef`/`secretKeyRemoteRef`).
- **`gcpSecretStore`**: chart creates a `SecretProviderClass` pointing at one `secretVersionResourceName` holding a
  full pre-built `secrets.toml`. Requires Workload Identity on `*.serviceAccount.annotations`.
- **`existingSecret`**: you manage the `Secret` yourself, the chart just mounts it.

`api_key` must be a UUID, `secret_key` must be hex-encoded.

## 3. Deploy

To check runtime behavior before touching a real cluster: [`local/`](local) is a docker-compose stack wired the
same way as this chart. Its [`config/`](local/config) files double as working examples of each `*.config` section
(mapped to chart keys in [local/README.md](local/README.md)).

```bash
NAMESPACE=your-cell-namespace
VALUES=your-values.yaml

helm template my-cell ./charts/ccv-cell -f "$VALUES"
helm upgrade --install my-cell ./charts/ccv-cell -n "$NAMESPACE" --create-namespace -f "$VALUES"

kubectl -n "$NAMESPACE" get pods
```

## 4. Verify it worked

A minimal values file that renders and starts cleanly (placeholder addresses, `existingSecret`, one fake chain).
Swap in real addresses and RPC URLs before trusting it beyond a smoke test:

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

Then check the logs:

```bash
kubectl -n "$NAMESPACE" logs sts/my-cell-ccv-cell-aggregator
kubectl -n "$NAMESPACE" logs sts/my-cell-ccv-cell-verifier
```

Aggregator healthy:
```
{"level":"INFO",...,"msg":"Successfully resolved secrets",...}
{"level":"INFO",...,"msg":"Database connection pool configured",...}
{"level":"INFO",...,"msg":"gRPC server started :50051"}
{"level":"INFO",...,"msg":"Service health summary",...,"overall_status":"ready",...}
```

Verifier healthy:
```
{"level":"INFO",...,"msg":"Using signer address","address":"0x..."}
{"level":"INFO",...,"logger":"EVMCommitteeVerifier.Node.Lifecycle","msg":"RPC Node is online",...,"nodeState":"Alive"}
{"level":"INFO",...,"msg":"Coordinator started successfully",...}
{"level":"INFO",...,"msg":"🎯 Verifier service fully started and ready!"}
{"level":"INFO",...,"msg":"🌐 HTTP server starting","port":"8100"}
{"level":"INFO",...,"logger":"EVMCommitteeVerifier","msg":"Healthy\n"}
```

Verifier panics with this instead:
```
panic: failed to run EVM committee verifier: failed to start bootstrapper: failed to connect to bootstrapper
database: dial tcp[::1]:5432: connect: connection refused
```
Postgres isn't reachable. Check `secrets.bootstrap`'s DB URL and that Postgres is up.

## 5. If a pod won't start

| Symptom | Cause |
|---|---|
| Aggregator crash-loops, log mentions committee/quorum | `committee.quorumConfigs` or `destinationVerifiers` is empty. |
| Verifier crash-loops: `no enabled/initialized chain sources` | `committee_verifier_addresses`/`on_ramp_addresses` aren't both set for the same chain, or `evm.config.chains` is missing that chain. |
| `helm install` fails: `... but no apiKeyRemoteRef` | A `clients[]`/`aggregators[]` entry is missing its remote-ref while using `externalSecret`. |
| CSI mount errors (`gcpSecretStore`) | GKE Secret Manager add-on not enabled, or Workload Identity not wired on the ServiceAccount. |
| Verifier logs show RPC timeouts/429s | Public RPC endpoints throttle aggressively under sustained polling (the local docker-compose stack hits this too, with its default public Sepolia RPC). Add fallback nodes per chain in `evm.config.chains[].nodes` (each with an `order`), or switch to a dedicated/paid provider. |

## 6. Upgrades, rollback, scaling

- `helm upgrade` with a changed config/secret ref is enough. The chart stamps `checksum/config`/`checksum/secrets`
  pod annotations, so the StatefulSet restarts pods automatically.
- Rollback: `helm rollback my-cell <revision> -n "$NAMESPACE"` (see `helm history my-cell -n "$NAMESPACE"`).
- Both StatefulSets are hard-coded to `replicas: 1`. Scale a **committee** by deploying more cells (more `helm
  install` releases, each with its own Postgres/secrets/KMS), not by bumping replicas on one release.
