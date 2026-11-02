# The Marketplace deployer base image

The GCP Marketplace deployer is not built from scratch. It is our chart and schema `COPY`'d on top of
a prebuilt base image, `deployer-base`, that lives in the publisher Artifact Registry project. That base
is built by [`gcp-marketplace-deployer-base`](../../.github/workflows/gcp-marketplace-deployer-base.yaml)
from Google's upstream `marketplace-k8s-app-tools` repository. This file records what it is and how to
update it.

Everything else about the listing is in [README.md](README.md).

## Where it is used

| File | What it does |
| --- | --- |
| [`../../.github/workflows/gcp-marketplace-deployer-base.yaml`](../../.github/workflows/gcp-marketplace-deployer-base.yaml) | Builds and pushes `deployer-base`; manual, `workflow_dispatch` only |
| [`../../.github/workflows/gcp-marketplace-release.yaml`](../../.github/workflows/gcp-marketplace-release.yaml) | Pins the base by digest in the `--build-arg DEPLOYER_BASE=…` for the `deployer` build |
| [`Dockerfile`](Dockerfile) | `ARG DEPLOYER_BASE=…` then `FROM $DEPLOYER_BASE`; the last stage only `COPY`s `/chart.tar.gz`, `/schema.yaml`, `/data-test/…` |

Because the base supplies the OS, Python, `kubectl` and Helm, **every `ccv-cell/deployer:<version>` you
publish inherits it.** Updating those components means rebuilding the base, not rebuilding the deployer
on top of the old one.

## Current pin

As of 2026‑11‑02:

| | |
| --- | --- |
| Image | `us-docker.pkg.dev/chainlink-labs-ltd-public/google-marketplace-chainlink-ccv/deployer-base` |
| Digest pinned in CI | `sha256:76810d5b97a83c8e0516904520b0d4119a746c9d49713dd0a42c56d1169c4fc3` |
| Tags pointing at it | `latest`, `20261102` |
| Built | `2026-11-02T16:19:04Z` |
| Platform | `linux/amd64` only |
| Base OS | Ubuntu 22.04 |
| `/version` | `20261102` (from the `VERSION` build arg) |

Tags are mutable (the repository has no immutable-tag policy). Pushing `20261102` again silently replaces
the digest the workflow points at. That is why the build workflow refuses to overwrite an existing build
tag; use a new tag for every rebuild. It does re-point the `latest` convenience tag on each run, but CI
never consumes that tag — it pins the digest.

## Runbook: updating the base

Use this whenever the base needs a refresh (new upstream revision, updated packages, or a routine
rebuild). The sequence is: build a new base, bump the pin, merge, then let the next `chainlink-ccv`
release pick it up.

1. **Build a new base.** Run the
   [`gcp-marketplace-deployer-base`](../../.github/workflows/gcp-marketplace-deployer-base.yaml) workflow
   from the Actions tab, or:

   ```bash
   # latest upstream release tag, for reference
   git ls-remote --tags --refs \
     https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools 'refs/tags/13.*' \
     | awk -F/ '{print $3}' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1

   gh workflow run gcp-marketplace-deployer-base.yaml \
     -f source_ref=13.0.15 \
     -f tag="$(date -u +%Y%m%d)"
   ```

   It checks out `marketplace-k8s-app-tools` at `source_ref`, builds
   `marketplace/deployer_helm_base/Dockerfile` for `linux/amd64` with `--build-arg VERSION=<tag>`, and
   pushes `deployer-base:<tag>` plus `:latest`. `source_ref` is required and has no default: it must be a
   release tag in the upstream repository (for example `13.0.15`) whose commit is on `master`. The workflow
   rejects branches and commit SHAs, and rejects a tag whose commit is not merged to `master`. The run
   summary prints the commit the tag resolved to; record that alongside the image digest. The run waits on
   the `publish-marketplace` environment for approval.

   It authenticates with the same Workload Identity provider as `gcp-marketplace-release`. If that
   provider's attribute condition is scoped to a specific workflow file, this one has to be added to it.

2. **Read the digest** from the run summary (it prints the exact `--build-arg` line to paste), or:

   ```bash
   gcloud artifacts docker images describe \
     us-docker.pkg.dev/chainlink-labs-ltd-public/google-marketplace-chainlink-ccv/deployer-base:<tag> \
     --format='value(image_summary.digest)'
   ```

3. **Open a PR** that updates, in one commit:

   - `--build-arg DEPLOYER_BASE=…@sha256:<new digest>` in
     [`../../.github/workflows/gcp-marketplace-release.yaml`](../../.github/workflows/gcp-marketplace-release.yaml).
   - The `ARG DEPLOYER_BASE` default in [`Dockerfile`](Dockerfile), or remove that default so a local
     build fails loudly instead of pulling a floating upstream tag.
   - The [Current pin](#current-pin) table above.

4. **Merge the PR before the next `chainlink-ccv` release PR.** The `marketplace-release` dispatch checks
   out `main` when it runs, so the digest bump has to be on `main` before the release tag is cut. Merging
   the bump on its own triggers nothing, so it is safe to land early.

5. **Verify after the release.** Once `gcp-marketplace-release` finishes for the new version, confirm the
   deployer was built after the bump:

   ```bash
   gcloud artifacts docker images describe \
     us-docker.pkg.dev/chainlink-labs-ltd-public/google-marketplace-chainlink-ccv/ccv-cell/deployer:<version> \
     --format='value(image_summary.digest)'
   ```

   The deployer digest will differ from the base digest (it is the base plus our layers), so what you are
   confirming is that the release ran after the bump.

## Why a mirror instead of `gcr.io/.../deployer_helm:latest`

- **Authentication.** The upstream repository now rejects anonymous pulls (`401`), and the release
  workflow only configures Docker auth for `us-docker.pkg.dev`. Using `gcr.io` directly would need extra
  auth wiring.
- **Reproducibility.** `latest` is rebuilt by Google whenever they choose; the last upstream rebuild seen
  was 2026‑10‑29. Pinning a digest means a published Marketplace version can be reproduced and traced to
  a specific base image.
- **Package updates.** Running the build ourselves lets `apt-get upgrade` pick up new packages on our
  schedule rather than Google's.

Note that `marketplace/gcp/Dockerfile:1` still defaults to a floating
`gcr.io/cloud-marketplace-tools/k8s/deployer_helm:latest`. A local `docker build` without the build arg
therefore uses neither the mirror nor a pinned digest.

## Publishing the updated deployer

A new base digest on its own changes nothing in the listing. You have to run
`gcp-marketplace-release` for a new version, and that version must satisfy two constraints:

- **It must be a new SemVer without the `v` prefix** (`0.16.1`, not `v0.16.1` and not `0.16.0`). Reusing a
  published version overwrites the Artifact Registry tags (they are mutable) without creating a new
  Marketplace version, and mutates what an already-released version resolves to.
- **The aggregator and verifier images must exist at that tag.** The v2 schema projects image references
  from the deployer's repository and `publishedVersion`:
  `…/ccv-cell:<version>` (aggregator) and `…/ccv-cell/verifier:<version>` (verifier). Those are published
  by `chainlink-ccv`'s release pipeline for its release tag. A base-only update therefore needs either a
  new `chainlink-ccv` patch release, or an explicit re-tag of the previous app images to the new version
  in the Marketplace repository.

The Helm chart release (`helm-ccv-cell-release.yml`) is **not** a dependency: the Marketplace workflow
packages `charts/ccv-cell` from the checkout directly and never consumes the published chart artifact or
the GitHub release.

`chainlink-ccv` dispatches `marketplace-release` automatically after it publishes the aggregator and
verifier images for a release tag. That dispatch checks out `main` **at the moment it runs**, so merge a
`deployer-base` digest bump before merging the `chainlink-ccv` release PR. If the release PR lands first,
the resulting deployer is built from the old base and the update needs another version.

## Known gaps

- The build is manual (`workflow_dispatch`); nothing runs it on a schedule or when upstream rebuilds, so
  the trigger is still a human deciding to refresh it.
- The workflow prints the digest but does not open the pin-bump PR; step 3 is still manual.
- The upstream Dockerfile is not reproducible by design: unpinned `ubuntu:22.04`, `kubectl` from
  `dl.k8s.io/release/stable.txt`, Helm from the latest GitHub release. Upstream tags are also lightweight,
  so record the commit printed by the run summary alongside the image digest.
- The base is `linux/amd64` only. The deployer is built `--platform linux/amd64`, so this is fine today,
  but it is not a multi-arch base.
