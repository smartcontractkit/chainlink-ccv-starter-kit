# GCP Marketplace deployer

Builds the deployer image Google Cloud Marketplace runs to install the `ccv-cell` chart. See
[building a deployer](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/building-deployer-helm.md).

See [PLACEHOLDERS.md](PLACEHOLDERS.md) for what is still unresolved.

| Path | What |
| --- | --- |
| `Dockerfile` | One line on top of the `deployer_helm/onbuild` base |
| `schema.yaml` | Deployment form, image declarations, cluster constraints |
| `chart/ccv-cell-mp/` | Wrapper chart taking `ccv-cell` as its only dependency |
| `build.sh` | `helm dependency update`, then `docker build` |

`ccv-cell` is used unmodified, as a subchart. The wrapper's `values.yaml` overrides only what
Marketplace forces. Consequence: every schema property is prefixed with the subchart name, so the
chart's `verifier.config.verifier_id` is `ccv-cell.verifier.config.verifier_id` in `schema.yaml`.

## Build

```shell
./build.sh gcr.io/<project>/ccv-cell/deployer:0.1.0
```

`helm dependency update` vendors `charts/ccv-cell` into `chart/ccv-cell-mp/charts/` as a tarball,
since the docker build context cannot reach outside this directory. The vendored copy is
gitignored. The dependency is `version: "*"`, so it tracks whatever is in the repo without needing
a version bump here.

The onbuild base then tars `chart/` into `/data/chart` and copies `schema.yaml` to
`/data/schema.yaml`. The tag is passed as the `TAG` build arg because `publishedVersion` in the
schema must equal the release tag.

Tag and push the track (`0.1`) alongside the version (`0.1.0`): Marketplace finds new versions of a
track by the last image carrying the track tag.

## Test

```shell
mpdev verify --deployer=gcr.io/<project>/ccv-cell/deployer:0.1.0
```

## How images get resolved

Nothing here hardcodes an image location. For schema v2 the deployer derives the repo prefix from
its own image location at deploy time, appends each name under `x-google-marketplace.images` and
the `publishedVersion` tag, then passes the result to helm as the declared properties. So a
deployer at `marketplace.gcr.io/nethermind/ccv-cell/deployer:0.1.0` yields:

```
ccv-cell.aggregator.image.registry=marketplace.gcr.io
ccv-cell.aggregator.image.repository=nethermind/ccv-cell
ccv-cell.verifier.image.repository=nethermind/ccv-cell/verifier
```

The app images must therefore exist at `<prefix>:<tag>` and `<prefix>/verifier:<tag>` in the
staging repo. Pushing them there is CI's job, not this script's.

## Deviations from the plain chart

- Digests are cleared. Marketplace parameterizes repository and tag, and the chart rejects a tag
  and a digest together.
- Service accounts are not created by the chart. Marketplace forbids it; the deployment form
  creates them and passes the names in.
- Secrets are locked to `gcpSecretStore`. `externalSecret` needs the External Secrets Operator,
  which is not on a stock GKE cluster.
- The committee, chain and RPC configuration is not in the form. It is nested maps keyed by chain
  selector, which a flat JSON-schema form cannot express. Users finish with `helm upgrade`.
