# CCV Cell Deployment Runbook

Deploy the [`ccv-cell`](charts/ccv-cell) Helm chart for [Chainlink CCV](https://github.com/smartcontractkit/chainlink-ccv).
For the full field-by-field reference, see the [chart README](charts/ccv-cell/README.md)
(generated from [values.yaml](charts/ccv-cell/values.yaml)) — this doc is the short path to a working deploy.

**A CCV Cell = one aggregator + one verifier (1 pod each).** The verifier watches on-ramps per chain, verifies
messages, signs results, and sends them to an aggregator (in-cluster or remote). The aggregator collects those
signed results and checks them against quorum. Multiple independently-run cells form a **committee** — each cell
needs its **own** Postgres, secrets, and KMS; never share these across cells, or one compromised cell endangers the
whole committee.

## 1. Prerequisites

- `helm` >= 3.x, `kubectl` pointed at the target cluster.
- A Gateway API or Ingress controller with HTTP/2 + gRPC support, usually behind a service mesh (Istio/Linkerd —
  Istio can also be the Gateway controller). Pick **one** way to expose the aggregator's gRPC endpoint:
  `aggregator.grpcRoute` (preferred), `aggregator.httpRoute` (fallback), or `aggregator.ingress`.
- A secrets backend: [External Secrets Operator](https://external-secrets.io/) (`type: externalSecret`) or GKE's
  [Secret Manager CSI add-on](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component)
  + Workload Identity (`type: gcpSecretStore`). `existingSecret` also exists but is for local dev only.
- **PostgreSQL >= 15**, encrypted, with 3 separate logical databases: `bootstrap`, `verifier`, `aggregator`.
- **KMS** for the verifier's signing key in production (`verifier.secrets.bootstrap.keystoreBackend: kms`) — the
  Postgres keystore backend works but isn't recommended beyond dev.
- IAM / Workload Identity for the aggregator and verifier ServiceAccounts — no static long-lived credentials.
- Field-level config reference (source of truth for every field, always current): `docs/config/` in the
  `chainlink-ccv` repo:
  [aggregator](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/aggregator/config.documented.toml) ·
  [verifier](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/verifier/committee/config.documented.toml) ·
  [bootstrap](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/bootstrap/config.documented.toml) ·
  [evm](https://github.com/smartcontractkit/chainlink-ccv/blob/main/docs/config/evm/config.documented.toml).
  Field names match the chart's `*.config` keys 1:1.
  Starting from a TOML snippet? Convert instead of
  hand-transcribing, then drop the result under the matching `*.config` key.

## 2. Wire up secrets

Set `type` on each of `aggregator.secrets.app`, `verifier.secrets.app`, `verifier.secrets.bootstrap`:

- **`externalSecret`** (default) — chart creates an `ExternalSecret` that pulls from your `SecretStoreRef` via
  `*RemoteRef` fields (e.g. `storageUrlRemoteRef`, per-client `apiKeyRemoteRef`/`secretKeyRemoteRef`).
- **`gcpSecretStore`** — chart creates a `SecretProviderClass` pointing at one `secretVersionResourceName` holding a
  full pre-built `secrets.toml`. Requires Workload Identity on `*.serviceAccount.annotations`.
- **`existingSecret`** — you manage the `Secret` yourself; chart just mounts it.

Never put real credentials in a values file. `api_key` must be a UUID, `secret_key` must be hex-encoded.

## 3. Deploy

Want to sanity-check your config's actual runtime behavior (not just that it renders) before touching a real
cluster? [`local/`](local) is a docker-compose stack wired the same way as this chart — real Postgres, aggregator,
and verifier containers. Its [`config/`](local/config) files are also handy as concrete, working examples of each
`*.config` section (see the table in [local/README.md](local/README.md) mapping each file to its chart equivalent).

```bash
kubectl create namespace ccv-cell

# render locally first
helm lint ./charts/ccv-cell
helm template my-cell ./charts/ccv-cell -f values.yaml --debug > /dev/null

# install/upgrade (same command either way)
helm upgrade --install my-cell ./charts/ccv-cell -n ccv-cell -f values.yaml

kubectl -n ccv-cell rollout status statefulset/my-cell-ccv-cell-aggregator
kubectl -n ccv-cell rollout status statefulset/my-cell-ccv-cell-verifier
```

## 4. Verify it worked

| Check | How |
|---|---|
| Aggregator up | `GET :8080/health/live` and `:8080/health/ready` |
| Verifier up | `GET :8100/health` (app) and `:9988/health` (bootstrap) |
| Secrets synced | `kubectl -n ccv-cell get externalsecret` → `SecretSynced` (or `kubectl describe pod` for CSI mount errors) |
| No crash loop | `kubectl -n ccv-cell logs sts/my-cell-ccv-cell-verifier -f` (and same for `-aggregator`) |

## 5. If a pod won't start

| Symptom | Cause |
|---|---|
| Aggregator crash-loops, log mentions committee/quorum | `committee.quorumConfigs` or `destinationVerifiers` is empty. |
| Verifier crash-loops: `no enabled/initialized chain sources` | `committee_verifier_addresses`/`on_ramp_addresses` aren't both set for the same chain, or `evm.config.chains` is missing that chain. |
| `helm install` fails: `... but no apiKeyRemoteRef` | A `clients[]`/`aggregators[]` entry is missing its remote-ref while using `externalSecret`. |
| CSI mount errors (`gcpSecretStore`) | GKE Secret Manager add-on not enabled, or Workload Identity not wired on the ServiceAccount. |
| Verifier logs show RPC timeouts/429s | Public RPC endpoints throttle aggressively under sustained polling (the local docker-compose stack hits this with its default public Sepolia RPC too). Add fallback nodes per chain in `evm.config.chains[].nodes` (each with an `order`), or switch to a dedicated/paid provider. |

## 6. Upgrades, rollback, scaling

- `helm upgrade` with a changed config/secret ref is enough — the chart stamps `checksum/config`/`checksum/secrets`
  pod annotations, so the StatefulSet restarts pods automatically.
- Rollback: `helm rollback my-cell <revision> -n ccv-cell` (see `helm history my-cell -n ccv-cell`).
- Both StatefulSets are hard-coded to `replicas: 1`. Scale a **committee** by deploying more cells (more `helm
  install` releases, each with its own Postgres/secrets/KMS), not by bumping replicas on one release.
