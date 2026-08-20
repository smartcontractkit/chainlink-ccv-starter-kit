# CCV Cell Deployment Runbook

Deploy the [`ccv-cell`](charts/ccv-cell) Helm chart for [Chainlink CCV](https://github.com/smartcontractkit/chainlink-ccv).
This doc is the short path to a working deploy. For the full field-by-field reference, see the
[chart README](charts/ccv-cell/README.md) (generated from [values.yaml](charts/ccv-cell/values.yaml)).

**A CCV Cell is one aggregator plus one verifier (1 pod each).** The verifier watches on-ramps per chain, verifies
messages, signs results, and sends them to an aggregator (in-cluster or remote). The aggregator collects those
signed results and checks them against quorum. Multiple independently-run cells form a **committee** (isolation
requirements for a cell's Postgres/secrets/KMS are in the chart's [Requirements](charts/ccv-cell/README.md#requirements)).

## 1. Prerequisites

- Cluster and infra dependencies (Gateway/Ingress + mesh, Postgres, secrets manager, KMS, Cloud IAM): see the
  chart's [Requirements](charts/ccv-cell/README.md#requirements).
- Config field reference: `docs/config/` in `chainlink-ccv`:
  [aggregator](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/aggregator/config.documented.toml) ·
  [verifier](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/verifier/committee/config.documented.toml) ·
  [bootstrap](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/bootstrap/config.documented.toml) ·
  [evm](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/evm/config.documented.toml).
  Field names match the chart's `*.config` keys 1:1. Converting from TOML: don't hand-transcribe, convert it and
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

Want to check your config's actual runtime behavior before touching a real cluster? [`local/`](local) is a
docker-compose stack wired the same way as this chart, with real Postgres, aggregator, and verifier containers. Its
[`config/`](local/config) files are also handy as concrete, working examples of each `*.config` section (see the
table in [local/README.md](local/README.md) mapping each file to its chart equivalent).

```bash
NAMESPACE=your-cell-namespace
VALUES=your-values.yaml

helm template my-cell ./charts/ccv-cell -f "$VALUES"
helm upgrade --install my-cell ./charts/ccv-cell -n "$NAMESPACE" --create-namespace -f "$VALUES"

kubectl -n "$NAMESPACE" get pods
```

## 4. Verify it worked

| Check | How |
|---|---|
| Aggregator up | `GET :8080/health/live` and `:8080/health/ready` |
| Verifier up | `GET :8100/health` (app) and `:9988/health` (bootstrap) |
| Secrets synced | `kubectl -n "$NAMESPACE" get externalsecret` should show `SecretSynced` (or `kubectl describe pod` for CSI mount errors) |
| No crash loop | `kubectl -n "$NAMESPACE" logs sts/my-cell-ccv-cell-verifier -f` (and same for `-aggregator`) |

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
