# AGENTS.md

Orientation for coding agents working in this repository. Written as an index: it points at the
authoritative file for each topic and deliberately does not restate it. If something here disagrees with
the file it points to, the other file wins.

## Start here

| You want to                       | Go to                                                                  |
| --------------------------------- | ---------------------------------------------------------------------- |
| Deploy or operate a CCV cell      | [RUNBOOK.md](RUNBOOK.md)                                               |
| Look up what a values key does    | [charts/ccv-cell/README.md](charts/ccv-cell/README.md#values)          |
| Run the stack locally             | [local/README.md](local/README.md)                                     |
| Change the chart itself           | the rest of this file                                                  |

**If you are deploying, stop after the runbook. Nothing below this line applies to you.**

## Layout

```
charts/ccv-cell/              the chart operators install
  values.yaml                 every configurable key, each documented inline
  values.schema.json          validation, enforced at install time
  README.md.gotmpl            hand-written wrapper around the generated docs
  README.md                   GENERATED, do not edit
  templates/{aggregator,verifier}/   K8s manifests, one dir per component
  changelogs/<version>.md     optional release notes, read by the release workflow
RUNBOOK.md                    the operator guide, ordered by deploy sequence
local/                        docker-compose stack for local testing, not production
marketplace/gcp/              GCP Marketplace wrapper chart and verification fixtures
grafana/                      example dashboard
```

## Generated files: never edit these by hand

- **`charts/*/README.md`** is produced by [helm-docs](https://github.com/norwoodj/helm-docs) from the
  `# --` comments in `values.yaml` plus `README.md.gotmpl`. Editing it directly is overwritten on the next
  commit and fails CI. To change prose, edit `README.md.gotmpl`; to change a key's description, edit the
  `# --` comment above that key.
- **The `version` field in `Chart.yaml`** is `0.0.0` in-tree and stamped by CI from the git tag.

helm-docs is pinned by digest in [`.pre-commit-config.yaml`](.pre-commit-config.yaml) and re-run as a gate
in [`.github/workflows/helm-docs.yml`](.github/workflows/helm-docs.yml). Install the hook with
`pre-commit install` and it runs automatically.

## Invariants when changing the chart

These are the rules that are not discoverable by reading the tree, in rough order of how often they are
broken.

**Adding a key to `values.yaml` means three edits, not one.** The key itself, a `# --` comment above it
(otherwise it is absent from the generated docs), and an entry in `values.schema.json`. A key missing from
the schema makes `helm template` fail, which is the single most common bug in this chart.

**Adding an integer key under a `config:` tree means a fourth edit.** The config trees are rendered to
TOML with `toToml`, which emits whole numbers as floats (`9988.0`), and the application's strict TOML
decoder rejects that for integer fields. The workaround is `ccv-cell.castInts` in
[`templates/_helpers.tpl`](charts/ccv-cell/templates/_helpers.tpl), called separately per config subtree in
`templates/{aggregator,verifier}/configmap.yaml`; find the call for your key's subtree and add the key
there. A key inside a list of objects, for example `committee.quorumConfigs[].threshold`, needs a manual
`range` + `set ... int64` instead, since `castInts` only works on flat maps. A new integer key left uncast
renders as a float, passes CI, and fails at container start.

**Most application config changes need no chart change at all.** Anything nested under a component's
`config:` key is passed through `toToml` and becomes the application's TOML config verbatim. Integer keys
(as above) and structural changes, for example exposing a new port, both need chart work.

**Schema properties at the root beginning with `x-` are ignored on purpose.** That is the escape hatch that
lets operators define YAML anchors at the top of their values file. Do not "fix" it. See RUNBOOK section 8.

**Both components are optional.** `aggregator.enabled` and `verifier.enabled` are independent; either or
both may be false. Templates must not assume a component is present.

**Do not add a free-form image override as an extension mechanism.** `image.repository` is already
overridable for registry mirrors, but new variants (for example a verifier for another chain family) should
be modelled as a schema-validated allow-list resolving to an image internally, following the pattern used
for secret backends. A free-form field lets an operator deploy an arbitrary container that simply crashes.

## Releases

Three independent pipelines. See [`.github/workflows/`](.github/workflows/).

- **Chart** (`helm-ccv-cell-release.yml`): triggered by pushing a **`v`-prefixed tag** to `main`. Publishes
  the chart as an OCI artifact. Release notes are auto-generated from the merged PRs; add
  `charts/ccv-cell/changelogs/<version>.md` before tagging only if you want hand-written prose on top.
- **Image bump** (`helm-ccv-cell-image-bump.yml`): `repository_dispatch` or `workflow_dispatch`. Updates the
  default image tags in `values.yaml` **and** `local/docker-compose.yaml`, regenerates the docs, and opens a
  PR. A label makes a newer run supersede an older un-merged one instead of stacking PRs.
- **GCP Marketplace** (`gcp-marketplace-release.yaml`): `repository_dispatch` or `workflow_dispatch`. The
  version here is **SemVer without the `v` prefix** and is validated as such, because Google matches on
  SemVer. Every artifact in a marketplace release carries the identical version, and each also receives a
  `major.minor` track tag.

## Known gaps

Stated so an agent does not assume coverage that is not there.

- **`marketplace/gcp/chart/ccv-cell-mp/` is outside the documentation and validation system.** helm-docs and
  the `helm-docs` workflow are both scoped to `--chart-search-root=charts`, so that chart has no generated
  README and no `values.schema.json`. Changes there are unvalidated.
- **There are no chart unit tests.** CI runs `helm dependency build`, `helm template` and the schema check
  only. [`helm-unittest`](https://github.com/helm-unittest/helm-unittest) is the intended direction for
  asserting rendered manifests. If you add tests, assert real template logic; do not generate a test per
  boolean flag or per field default.
