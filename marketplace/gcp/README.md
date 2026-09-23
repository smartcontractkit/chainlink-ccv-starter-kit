# Deploying a CCV Cell from Google Cloud Marketplace

This listing deploys into infrastructure you already run. You provide the GKE cluster, the PostgreSQL
instance, the secrets and, if you expose the aggregator over gRPC, the Gateway. The listing installs the
software onto that cluster and nothing else.

This page covers the first hour: what the listing creates for you, what you have to create yourself, and what
the early failures look like. Once both pods are running, everything else lives in the
[RUNBOOK](../../RUNBOOK.md): verifying the cell, committee sizing, credential exchange with peers, indexer
onboarding, metrics and alerting.

If you are deploying with `helm` rather than through the listing, read the RUNBOOK instead. This page only
describes what the Marketplace path does differently.

## What the listing does

- Installs the `ccv-cell` chart **into a GKE cluster you already run**, wrapped so that all configuration
  arrives as pre-built TOML files held in Secret Manager rather than as Helm values. The listing creates no
  cluster, no database, no network and no keys.
- Creates the two Kubernetes ServiceAccounts the pods run as, **but only if you leave those fields blank on
  the form**. If you type a name, Marketplace assumes the account already exists and does not create it.

## Before you deploy

**The form has no database fields, and no fields for credentials of any kind.** It asks for seven Secret
Manager *pointers*. Connection strings, passwords and API keys live inside those secrets, because anything
typed into the form is stored in plaintext in the deployment's metadata. So most of the work happens before
you open the form.

Do these in order.

### 0. Preflight the cluster

You bring the cluster; the listing deploys into it. Everything below has to be in place before you open the
form, and none of it can be fixed from the form afterwards. Run the preflight, then read the notes for
anything that fails.

| Check | Why it matters | Fix |
| --- | --- | --- |
| Workload Identity Federation enabled | Without it a pod cannot hold a Google Cloud identity, so no IAM grant has any effect | recreate or update with `--workload-pool=<project-id>.svc.id.goog` |
| Managed Secret Manager CSI component enabled | Every secret in this listing is mounted through it | `--enable-secret-manager` |
| A route kind your Gateway serves | `GRPCRoute` needs a controller that implements it; GKE's managed Gateway serves `HTTPRoute` only | pick the matching Route kind on the form, see step 5 |
| A `Gateway` that a controller actually programs | A GRPCRoute attached to nothing leaves the aggregator unreachable | run Istio, Envoy Gateway or similar, see step 5 |
| Network path to PostgreSQL | The pods connect directly, there is no proxy in the chart | private IP on the same VPC, or peering, see step 1 |
| Capacity for the cell | The listing declares 2 vCPU and 2Gi as its constraint | a node pool with room for two StatefulSets plus your own workloads |
| The Application CRD | Every Marketplace deployment creates an `Application` object; without the CRD the install fails | `kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml` |
| The target namespace exists | The deployment does not create it | `kubectl create namespace <name>` |

```bash
PROJECT=<project-id>; CLUSTER=<cluster>; LOCATION=<zone-or-region>; NAMESPACE=<namespace>

echo -n "workload identity:   "; gcloud container clusters describe "$CLUSTER" --location="$LOCATION" \
  --project="$PROJECT" --format='value(workloadIdentityConfig.workloadPool)' | grep -q . && echo PASS || echo FAIL
echo -n "secret manager csi:  "; [ "$(gcloud container clusters describe "$CLUSTER" --location="$LOCATION" \
  --project="$PROJECT" --format='value(secretManagerConfig.enabled)')" = "True" ] && echo PASS || echo FAIL
echo -n "csi driver running:  "; kubectl get csidriver 2>/dev/null | grep -q secrets-store-gke && echo PASS || echo FAIL
echo -n "GRPCRoute CRD:       "; kubectl api-resources --api-group=gateway.networking.k8s.io 2>/dev/null \
  | grep -q grpcroutes && echo "PASS (GRPCRoute available)" || echo "absent - choose Route kind HTTPRoute, see step 5"
echo -n "a programmed Gateway:"; kubectl get gateway -A 2>/dev/null | grep -q True \
  && echo " PASS" || echo " FAIL (only needed if you expose the aggregator, see step 5)"
echo -n "Application CRD:     "; kubectl get crd applications.app.k8s.io >/dev/null 2>&1 && echo PASS \
  || echo "FAIL (apply the Application CRD, see the table above)"
echo -n "HealthCheckPolicy:   "; kubectl get crd healthcheckpolicies.networking.gke.io >/dev/null 2>&1 \
  && echo "PASS (GKE Gateway - you will need one, see step 5)" || echo "n/a (not GKE Gateway)"
echo -n "target namespace:    "; kubectl get ns "$NAMESPACE" >/dev/null 2>&1 && echo PASS \
  || echo "FAIL (kubectl create namespace $NAMESPACE)"
```

A `Gateway` shows `PROGRAMMED: True` only once a controller has accepted it. `Unknown` means the CRDs exist
but nothing is acting on them, which will leave your aggregator unreachable even though the deployment
reports success.

### 1. Create the database

PostgreSQL the cluster can reach, Cloud SQL recommended. Nothing in the listing provisions one.

Create the databases yourself. The cell runs schema migrations at first startup, but migrations create
tables inside a database that already exists; they do not create the database.

How many you need depends on where the verifier's signing key lives:

| Keystore backend | Databases |
| --- | --- |
| `postgres` (default) | three: `bootstrap`, `verifier`, `aggregator` |
| `kms` | two: `verifier`, `aggregator`. The bootstrap database exists only to hold the encrypted keystore, so a KMS-held key removes the need for it |

```bash
for db in bootstrap verifier aggregator; do   # drop "bootstrap" if you use the KMS keystore
  gcloud sql databases create "$db" --instance=<instance> --project=<project-id>
done
```

The cluster must be able to reach the instance. With Cloud SQL that usually means private IP with the cluster
on the same VPC, or a peering arrangement. Connection strings carry a username and password, so the pods need
no IAM for the database itself.

Every example below uses `sslmode=require`. Match it to your instance: Cloud SQL accepts it, a plain
PostgreSQL without TLS needs `sslmode=disable` or the connection fails.

Keep the connection details to hand. You need them in step 2.

### 2. Write the seven TOML files

Each secret holds one complete file. Worked examples for all seven follow; they are a working set, taken from
a cell that runs. Replace the addresses, chain selectors, RPC endpoints and credentials with yours.

| File | Form field | Purpose |
| --- | --- | --- |
| aggregator secrets | Aggregator secrets | aggregator database, and the credentials verifiers present to it |
| aggregator config | Aggregator config | committee membership and quorum |
| verifier secrets | Verifier secrets | verifier database, and the credentials it presents to aggregators |
| verifier config | Verifier config | this verifier's identity, its aggregators, and the on-chain addresses per chain |
| verifier bootstrap config | Verifier bootstrap config | how the verifier finds its own config, and which chains it serves |
| verifier bootstrap secrets | Verifier bootstrap secrets | the keystore, and its database when the backend is `postgres` |
| verifier EVM config | Verifier EVM config | RPC endpoints per source chain |

**Three values must match across files, and nothing validates them for you.**

| Value | Must be identical in |
| --- | --- |
| the client id | aggregator secrets `[[clients]] client_id` and aggregator config `[[clients]] clientId` |
| the aggregator secret name | verifier config `[[aggregators]] secret_name` and verifier secrets `[[aggregators]] secret_name` |
| the chain selector | every address table and `[[chains]]` entry that refers to the same chain |

**Note the casing.** The aggregator's *secrets* file uses `client_id`; its *config* file uses `clientId`.
That is not a typo in this document. Get it wrong and the verifier fails to authenticate with no message
that points at the cause.

#### aggregator secrets

```toml
[storage]
url = "postgres://ccv:<password>@10.20.30.40:5432/aggregator?sslmode=require"

[[clients]]
client_id = "committee-verifier-1"
api_key = "<uuid>"
secret_key = "<64 hex chars>"
```

`api_key` must be a UUID and `secret_key` hex-encoded. You generate both; they are shared with the verifiers
allowed to submit to this aggregator.

#### aggregator config

```toml
[storage]
type = "postgres"

[server]
address = ":50051"

[healthCheck]
enabled = true
port = "8080"

[committee.destinationVerifiers]
"16015286601757825753" = "0xD5C448Fc5B81EFd3108656Ce5FF9bacF2b582bdB"

[committee.quorumConfigs."16015286601757825753"]
sourceVerifierAddress = "0xD5C448Fc5B81EFd3108656Ce5FF9bacF2b582bdB"
threshold = 1
signers = [{ address = "0x0000000000000000000000000000000000000001" }]

[[clients]]
clientId = "committee-verifier-1"
groups = ["default"]
enabled = true
```

**Do not omit `[server] address`.** Without it the aggregator binds an arbitrary high port instead of
50051, comes up healthy, and passes every readiness check, while the verifier fails every connection with
`connection refused` against the service's port 50051. Nothing in either log says the port is wrong. Confirm
with `kubectl exec <aggregator-pod> -- netstat -tln`: you should see `:::50051`.

Those verifier addresses are the CCV's **resolver**, not the implementation behind it; see
[RUNBOOK §2](../../RUNBOOK.md#2-configure-the-values). The same applies to `[committee_verifier_addresses]`
in the verifier config below.

One `[committee.quorumConfigs."<selector>"]` block per chain you verify for. `signers` lists the signing
addresses of every verifier in the committee, which is where your own verifier's address goes once you know
it, and `threshold` is how many must agree.

#### verifier secrets

```toml
[db]
url = "postgres://ccv:<password>@10.20.30.40:5432/verifier?sslmode=require"

[[aggregators]]
secret_name = "aggregator_1"
api_key = "<uuid>"
secret_key = "<64 hex chars>"
```

#### verifier config

```toml
verifier_id = "committee-verifier-1"
signer_address = "auto"
message_disablement_rules_poll_interval = "2s"
message_disablement_rules_client_timeout = "500ms"

[[aggregators]]
name = "aggregator-1"
secret_name = "aggregator_1"
address = "<deployment-name>-ccv-cell-aggregator:50051"
insecure_connection = true
max_send_msg_size_bytes = 0
max_recv_msg_size_bytes = 0

[committee_verifier_addresses]
"16015286601757825753" = "0xD5C448Fc5B81EFd3108656Ce5FF9bacF2b582bdB"

[on_ramp_addresses]
"16015286601757825753" = "0x8dcf17f298c881A547D91ca4aA3C2AD7568C6777"
```

**`address` is the in-cluster DNS name of the aggregator this listing deploys**, and you have to write it
yourself. The chart names it `<deployment-name>-ccv-cell-aggregator`, where `<deployment-name>` is what you
type in the form's Name field, so a deployment named `ccv-cell-1` gives
`ccv-cell-1-ccv-cell-aggregator:50051`. `insecure_connection = true` is correct for that hop: it stays inside
the cluster and never crosses the network.

#### verifier bootstrap config

```toml
app_config_mode = "local_app_config"
local_app_config_path = "/etc/committee-verifier/config.toml"

[server]
listen_port = 9988

[[chains]]
type = "EVM"
id = "16015286601757825753"

[Monitoring]
LogLevel = "info"

[Monitoring.Pyroscope]
Enabled = false

[Monitoring.Beholder]
Enabled = false
```

**`local_app_config_path` must be exactly `/etc/committee-verifier/config.toml`.** That is where this chart
mounts the verifier config secret, and the listing gives you no way to change it. Upstream configuration
references show other paths for other deployments; on this path that value is the only one that works.

`id` under `[[chains]]` is a chain selector and **must be quoted**. TOML integers are 64-bit signed, and a
selector such as `16015286601757825753` is larger than that, so unquoted the verifier panics with
`out of range for int64`. As a table key, `[chains.16015286601757825753]` in the EVM file below, it is fine
unquoted, because TOML bare keys are always strings.

#### verifier bootstrap secrets

With the default `postgres` keystore:

```toml
[db]
url = "postgres://ccv:<password>@10.20.30.40:5432/bootstrap?sslmode=require"

[keystore]
backend = "postgres"
password = "<keystore password>"
```

`password` encrypts the signing key at rest in the bootstrap database. **Treat it as permanent.** The key is
generated on first boot and encrypted with it; change it later and the verifier can no longer decrypt the key
it has been signing with, which means a new signing address and an on-chain committee update on every
destination chain. Store it where you store your other durable secrets.

With the KMS keystore, see the next section; there is no `[db]` and no password, and the signing address
survives a rebuild of the cell because the key lives in KMS rather than in the database.

#### verifier EVM config

```toml
[chains]
  [chains.16015286601757825753]
    finality_depth = 0

    [[chains.16015286601757825753.nodes]]
      name = "node-1"
      http_url = "https://ethereum-sepolia-rpc.publicnode.com"
      order = 1
```

One block per source chain the verifier reads, keyed by **chain selector**, not chain ID. Everything the
verifier attests for needs an entry here: a cell serving two lanes needs both chains, and the pod logs
`loaded EVM config numChains=N` at startup, which is the quickest way to confirm it read what you meant.

`http_url` takes a full endpoint including any API key, which is why this file is a secret rather than a
config value. Use endpoints that meet the Chainlink RPC node requirements: the verifier polls continuously
and public endpoints throttle, which shows up as 429s in the logs and stalled verification. List several
nodes with different `order` values for failover.

`finality_depth = 0` follows the chain's finality tag. On Ethereum that means roughly 13 to 15 minutes
before a message becomes verifiable, so a cell that looks idle after a send is usually just waiting for
finality. A positive value waits that many confirmations instead.

### Choosing where the signing key lives

There is no keystore option on the form. You choose by what you write in the **verifier bootstrap secrets**
file, and the chart never inspects it.

Encrypted in PostgreSQL, the default:

```toml
[db]
url = "postgres://ccv:<password>@10.20.30.40:5432/bootstrap?sslmode=require"

[keystore]
backend = "postgres"
password = "<keystore password>"
```

Held in Cloud KMS, which removes the bootstrap database entirely:

```toml
[keystore]
backend = "kms"

[keystore.kms]
provider = "gcp"
ecdsa_key_id = "projects/<p>/locations/<l>/keyRings/<r>/cryptoKeys/<k>/cryptoKeyVersions/1"
```

KMS keeps the private key out of your database and out of any backup of it, at the cost of a KMS dependency
on every signature and the two IAM roles described below. Either is supported; pick per your key-custody
policy.

Ignore `verifier.secrets.bootstrap.keystoreBackend` if you read the chart. That value is used only by the
chart's `externalSecret` path, and this listing uses `gcpSecretStore`, where you supply the whole file. It
has no effect here whatever it is set to.

### 3. Upload each file to Secret Manager

```bash
gcloud secrets create ccv-cell-aggregator-secrets \
  --project=<project-id> --replication-policy=automatic \
  --data-file=aggregator-secrets.toml
```

Repeat for all seven files. The names are yours to choose; keeping them parallel to the file names, as the
step-2 table lists them, is what makes the form easy to fill in without mixing two up.

Note each version resource name, which is what the form asks for:

```
projects/<project-id>/secrets/ccv-cell-aggregator-secrets/versions/latest
```

To change a file later, add a new version to the same secret; `versions/latest` picks it up on the next pod
restart.

### 4. Grant Secret Manager access

See [Step 4 in detail](#step-4-in-detail-granting-secret-manager-access) below. This is the step most often missed, and its failure mode is a pod that never starts and
logs nothing.

### 5. Provide a Gateway, and pick the route kind that matches it

Peers must reach your aggregator, so leave the route enabled unless you are exposing the endpoint some other
way. The Gateway must terminate TLS and speak HTTP/2 end to end.

The aggregator speaks gRPC, which is HTTP/2, and the listing can expose it as either Gateway API resource.
Pick with **Route kind** on the form:

| Route kind | Use when | Notes |
| --- | --- | --- |
| `GRPCRoute` | Your controller implements it: Istio, Envoy Gateway, Contour and others do | The natural fit. gRPC-aware matching |
| `HTTPRoute` | **GKE's managed Gateway**, which implements HTTPRoute only | Same traffic, matched on a path prefix. gRPC method paths are `/package.Service/Method`, so a prefix of `/` carries all of them. On GKE this also needs a `HealthCheckPolicy` and a TLS listener, both below |

Either way the aggregator Service advertises `appProtocol: kubernetes.io/h2c`, which is what tells a gateway
to speak HTTP/2 to the backend rather than downgrading to HTTP/1.1.

**On stock GKE, choose `HTTPRoute`.** Enabling the Gateway API with `--gateway-api=standard` installs
GatewayClass, Gateway, HTTPRoute, TLSRoute, ReferenceGrant and BackendTLSPolicy, but **not GRPCRoute**, and
GKE's own documentation states HTTPRoute is the only Route type its controller supports. Choosing
`GRPCRoute` there fails the deployment with:

```
no matches for kind "GRPCRoute" in version "gateway.networking.k8s.io/v1"
```

#### On GKE's managed Gateway, add a HealthCheckPolicy

GKE derives a health check from the Service port it serves. For the aggregator that port is gRPC, and the
derived check is a plain `HTTP GET /` against it, which a gRPC server never answers with 200. The backend
stays `UNHEALTHY` and every request through the Gateway returns `503`, even though the Gateway reports
`PROGRAMMED: True`, the route reports `Accepted` and `ResolvedRefs`, and the pods are `1/1`. Nothing in
`kubectl` looks wrong.

The aggregator serves `/health/ready` on its health port, 8080, so point the check there:

```yaml
apiVersion: networking.gke.io/v1
kind: HealthCheckPolicy
metadata:
  name: <deployment-name>-ccv-cell-aggregator
  namespace: <namespace>
spec:
  default:
    config:
      type: HTTP
      httpHealthCheck:
        portSpecification: USE_FIXED_PORT
        port: 8080
        requestPath: /health/ready
  targetRef:
    group: ""
    kind: Service
    name: <deployment-name>-ccv-cell-aggregator
```

Apply it after the deployment, then confirm the backend turns healthy:

```bash
gcloud compute backend-services list --filter="name~aggregator" --format="value(name)"
gcloud compute backend-services get-health <name> --global \
  --format="value(status.healthStatus[].healthState)"
```

**Checking it worked.** A plain gRPC probe is not a health check. With the aggregator scaled to zero
replicas, `curl` against this endpoint still returns `200 application/grpc`, because gRPC reports failures
in trailers under an HTTP 200. Verify the endpoint by fetching a real attestation instead:

```bash
ccip-cli show <sourceTx> --no-api --verifier grpcs://<your-host>:443 -v
```

Use `-v`. Without it a fetch failure prints only "has not been verified yet", which is indistinguishable
from a message that genuinely has no attestation yet.

**Gate on `Programmed`, not `Accepted`.** While a Gateway is `Programmed: False`, Google's load balancer
keeps serving the last configuration that did program, so an apply can appear to succeed and change
nothing, including leaving a stale certificate on the wire.

```bash
kubectl get gateway <name> -n <namespace> \
  -o jsonpath='{range .status.listeners[*]}{.name}={range .conditions[?(@.type=="Programmed")]}{.status}{end}{"\n"}{end}'
```

**Do not put a classic Ingress on the same Service.** The `cloud.google.com/backend-config` annotation a
classic Ingress needs is rejected by the Gateway controller and stops it programming entirely
(`Service has unsupported BackendConfig annotation(s)`). Pick one or the other.

Also note that Google's external load balancer speaks HTTP/2 only over TLS. A Gateway listener on port 80
carries HTTP/1.1 to the backend, which is not gRPC, so give the Gateway an HTTPS listener with a
certificate. That is the same requirement as the TLS sentence at the top of this step, and it is not
optional on this path.

**If you want `GRPCRoute` on GKE** you need the upstream Gateway API CRDs and a controller that implements
them:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl api-resources --api-group=gateway.networking.k8s.io | grep grpcroutes
```

Be aware that GKE's addon manager owns the Gateway API CRDs while the managed Gateway API is enabled, and
refuses to share them: a third-party controller's chart fails with a CRD ownership conflict until you disable
it with `--gateway-api=disabled`. That is a cluster-wide change affecting every other workload using GKE
Gateway, which is the main reason to prefer `HTTPRoute` unless you already run your own controller.

**The Gateway must be in the same namespace as the deployment**, or you must supply its namespace in the
Gateway namespace field and grant cross-namespace access with a `ReferenceGrant`. A route that cannot attach
shows `Accepted: False` in `kubectl get <kind> -n <namespace> -o yaml`.

If you would rather not run a Gateway at all, switch the route off. The endpoint still needs a stable,
internet-reachable hostname carrying gRPC over HTTP/2, because peer verifiers and the CCIP indexer connect to
it.

## Step 4 in detail: granting Secret Manager access

The accounts Marketplace creates are named `<deployment-name>-<property-path>`, lowercased and
DNS-1123-normalised, so for a deployment named `ccv-cell-1`:

```
ccv-cell-1-ccv-cell-aggregator-serviceaccount-name
ccv-cell-1-ccv-cell-verifier-serviceaccount-name
```

Those names are predictable, and an IAM binding is only a string, so **the grant does not have to wait for
the deployment**. Do it first and the cell starts cleanly.

Bind the role directly to the ServiceAccount principal. No Google service account, no annotation:

```bash
PROJECT=<project-id>
NUMBER=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')
NS=<namespace>
KSA=ccv-cell-1-ccv-cell-aggregator-serviceaccount-name

gcloud secrets add-iam-policy-binding <secret-name> \
  --project="$PROJECT" \
  --role=roles/secretmanager.secretAccessor \
  --member="principal://iam.googleapis.com/projects/$NUMBER/locations/global/workloadIdentityPools/$PROJECT.svc.id.goog/subject/ns/$NS/sa/$KSA"
```

Repeat per secret: the aggregator account needs the two aggregator secrets, the verifier account the five
verifier ones. Granting per secret keeps each component to what it needs; a project-wide
`roles/secretmanager.secretAccessor` also works but gives both pods every secret in the project.

Impersonating a Google service account, by granting it the roles and annotating the Kubernetes account with
`iam.gke.io/gcp-service-account`, also works. It is the older method, and it cannot be done ahead of the
deployment, because the annotation has to go on an account Marketplace has not created yet.

## What access the pods need, in one place

The two ServiceAccounts Marketplace creates start with no Google Cloud access at all. Grant each only what
its component uses.

| Resource | Who needs it | Role | When |
| --- | --- | --- | --- |
| The two aggregator secrets | aggregator ServiceAccount | `roles/secretmanager.secretAccessor` | always |
| The five verifier secrets | verifier ServiceAccount | `roles/secretmanager.secretAccessor` | always |
| The KMS signing key | verifier ServiceAccount | `roles/cloudkms.signerVerifier` **and** `roles/cloudkms.viewer` | only with the `kms` keystore |
| PostgreSQL | neither | none | connection strings authenticate with a username and password |

Grant each on the specific resource rather than at project level, so neither component can read anything else.

**Both KMS roles are required, and this is easy to get wrong.** `roles/cloudkms.signerVerifier` grants signing
and public-key reads but not `cloudkms.cryptoKeyVersions.get`, which the verifier calls when it loads the
key. With only that role the verifier crash-loops on:

```
failed to initialize KMS keystore: ... Permission 'cloudkms.cryptoKeyVersions.get' denied
```

`roles/cloudkms.viewer` supplies the missing permission.

```bash
gcloud kms keys add-iam-policy-binding <key> --keyring=<ring> --location=<location> \
  --project=<project-id> --role=roles/cloudkms.signerVerifier \
  --member="principal://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/<project-id>.svc.id.goog/subject/ns/<namespace>/sa/<verifier-ksa>"

gcloud kms keys add-iam-policy-binding <key> --keyring=<ring> --location=<location> \
  --project=<project-id> --role=roles/cloudkms.viewer \
  --member="principal://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/<project-id>.svc.id.goog/subject/ns/<namespace>/sa/<verifier-ksa>"
```

The key must be an asymmetric signing key with algorithm `ec-sign-secp256k1-sha256`. On Google Cloud that
algorithm is available only at **HSM** protection level; a software key is rejected at creation with
`ALGORITHM_NOT_SUPPORTED_FOR_PROTECTION_LEVEL`. Reference it in the bootstrap secret by its **CryptoKeyVersion**
resource name, ending in `/cryptoKeyVersions/<n>`:

```toml
[keystore]
backend = "kms"

[keystore.kms]
provider = "gcp"
ecdsa_key_id = "projects/<p>/locations/<l>/keyRings/<r>/cryptoKeys/<k>/cryptoKeyVersions/1"
```

With the `kms` backend the bootstrap secret needs no `[db]` and no `[keystore] password`.

## Then fill in the form

Every field, and what to put in it.

| Field | Value |
| --- | --- |
| Name | The deployment name. It prefixes everything the chart creates, including the aggregator DNS name you wrote into the verifier config in step 2 |
| Namespace | An existing namespace. Create it first with `kubectl create namespace <name>`; the deployment does not create it |
| Aggregator service account | **Leave blank** so Marketplace creates it, unless you have created one yourself and granted it access |
| Verifier service account | **Leave blank**, same reason |
| The seven Secret Manager versions | The `projects/<p>/secrets/<name>/versions/latest` strings from step 3 |
| Verifier ID | Your verifier's name. Use the same value as `verifier_id` in the verifier config file |
| Signer address | `auto` on a first deployment. The verifier generates the signing key on first boot and adopts its address, which you read from the log afterwards. Set an explicit address only when the key already exists and you want startup to fail if it does not match |
| Expose the aggregator through a GRPCRoute | On by default. Switch off only if you expose the aggregator another way |
| Route kind | `GRPCRoute` (default) or `HTTPRoute`. Pick `HTTPRoute` on stock GKE; see step 5 |
| Aggregator hostname | Required even when the GRPCRoute is off, in which case it is ignored |
| Gateway name | Required even when the GRPCRoute is off, in which case it is ignored |
| Gateway namespace, Gateway listener | Optional. Leave empty to use the deployment's namespace and all compatible listeners |

Installing from the command line rather than the console uses the underlying property names, which differ
from the display names above. Feed them to the marketplace CLI as a single-line JSON object:

```bash
mpdev install \
  --deployer=<the listing's deployer image, e.g. …/ccv-cell/deployer:<version>> \
  --parameters='<the JSON below, on one line>'
```

`mpdev` comes from
[marketplace-k8s-app-tools](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools); the deployer
image and its version are shown on the listing page.

```json
{
  "name": "ccv-cell-1",
  "namespace": "ccv",
  "ccv-cell.aggregator.secrets.app.gcpSecretStore.secretVersionResourceName": "projects/<p>/secrets/<n>/versions/latest",
  "ccv-cell.aggregator.secrets.config.gcpSecretStore.secretVersionResourceName": "...",
  "ccv-cell.verifier.secrets.app.gcpSecretStore.secretVersionResourceName": "...",
  "ccv-cell.verifier.secrets.config.gcpSecretStore.secretVersionResourceName": "...",
  "ccv-cell.verifier.secrets.bootstrapConfig.gcpSecretStore.secretVersionResourceName": "...",
  "ccv-cell.verifier.secrets.bootstrap.gcpSecretStore.secretVersionResourceName": "...",
  "ccv-cell.verifier.secrets.evm.gcpSecretStore.secretVersionResourceName": "...",
  "ccv-cell.verifier.config.verifier_id": "committee-verifier-1",
  "ccv-cell.verifier.config.signer_address": "auto",
  "grpcRoute.enabled": true,
  "grpcRoute.routeKind": "GRPCRoute",
  "grpcRoute.hostname": "ccv-aggregator.example.com",
  "grpcRoute.parentRefName": "my-gateway",
  "grpcRoute.parentRefNamespace": "",
  "grpcRoute.parentRefSectionName": ""
}
```

Omit the two `serviceAccount.name` properties entirely. Supplying either stops Marketplace provisioning that
account, and nothing else creates it.

## Early failures and what they mean

| What you see | What it is |
| --- | --- |
| Deploy succeeds, no aggregator or verifier pod appears, StatefulSet events show `serviceaccount ... not found` | A service account name was supplied on the form but no such account exists. Leave the field blank, or create the account first. |
| Pods stuck in `ContainerCreating`, `FailedMount` naming the CSI driver as unknown or unavailable | The managed Secret Manager CSI component is not enabled on the cluster. See step 0. |
| Pods stuck in `ContainerCreating`, no logs, `kubectl describe pod` shows `FailedMount` and `PermissionDenied` | The ServiceAccount has no Secret Manager access. Add the binding above; the CSI driver retries and the pods start on their own. |
| Verifier panics with `out of range for int64` | A chain selector is written as an unquoted TOML value. Quote it. |
| Aggregator exits with `committee configuration cannot be nil` | The aggregator config secret is missing its `[committee.*]` sections. |
| The aggregator answers `200 application/grpc` but nothing works | That is not a health check; gRPC errors ride in trailers under a 200. Fetch a real attestation with `ccip-cli show ... --verifier ... -v`. |
| A config change to the Gateway appears to apply but nothing changes | The Gateway is `Programmed: False` and the load balancer is still serving the last good config. Check the `Programmed` condition. |
| The cell reports `Healthy` but never attests anything | The verifier cannot reach its aggregator. The health endpoint does not cover that link. Check the verifier logs for the aggregator address it is dialling. |
| Gateway returns `503` although the route and pods look healthy | GKE's derived health check probes the gRPC port with `HTTP GET /`. Add the `HealthCheckPolicy` in step 5. |
| gRPC clients cannot connect although a browser reaches the endpoint | The Gateway listener is plain HTTP on port 80. Google's load balancer speaks HTTP/2 only over TLS; add an HTTPS listener. |
| Deploy fails with `no matches for kind "GRPCRoute"` | The cluster has no GRPCRoute CRD. Set Route kind to `HTTPRoute`, which GKE's managed Gateway serves, or install a controller that implements GRPCRoute; see step 5. |
| Route shows `Accepted: False` | The Gateway is in another namespace, or its `allowedRoutes` does not admit yours. Supply the Gateway namespace and add a `ReferenceGrant`. |
| Verifier logs `connection refused` to the aggregator on 50051, aggregator looks healthy | Only a fault if it **persists** after the aggregator is Ready; a few seconds of it at startup is the normal race while the aggregator binds. If it continues, the aggregator config has no `[server] address = ":50051"` and it bound an arbitrary port. Check with `netstat -tln` inside the pod |
| Message sent, verifier never mentions it | Either the message predates the verifier's start block (it resumes from where it left off, it does not backfill), or the source chain has not reached finality yet |
| Verifier logs an authentication failure against the aggregator | The client id or the aggregator credentials do not match across files. Check `client_id` in aggregator secrets against `clientId` in aggregator config, and `secret_name` in verifier config against verifier secrets |
| Verifier cannot find its application config | `local_app_config_path` is not `/etc/committee-verifier/config.toml` |
| Verifier cannot reach the aggregator | `[[aggregators]] address` does not match the deployed service name, which is `<deployment-name>-ccv-cell-aggregator:50051` |
| Verifier panics with `Permission 'cloudkms.cryptoKeyVersions.get' denied` | The verifier ServiceAccount has `roles/cloudkms.signerVerifier` but not `roles/cloudkms.viewer`. Grant both. |
| Verifier panics with `failed to connect to bootstrapper database` | The `bootstrap` database does not exist or is unreachable from the cluster. |

## Confirming it worked

```bash
kubectl get pods -n <namespace>
kubectl logs -n <namespace> sts/<deployment-name>-ccv-cell-verifier | grep "Using signer address"
```

Both pods reach `1/1 Running`. The verifier logs the signing address it adopted, which is the value you give
to peers and to the CCIP indexer.

From here, continue at [RUNBOOK §4](../../RUNBOOK.md#4-verify-it-worked).
