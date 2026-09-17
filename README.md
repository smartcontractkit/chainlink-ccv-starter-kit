# chainlink-ccv-starter-kit
Starter Kit for Chainlink Cross-Chain Verifiers (CCVs)

## Deploying a CCV Cell

See [RUNBOOK.md](RUNBOOK.md) for the operational guide to deploying the [`ccv-cell`](charts/ccv-cell) chart:
prerequisites, required values, secrets setup, deploy steps, post-deploy validation, and troubleshooting.

## Chart docs

Chart docs (`charts/*/README.md`) are generated with [helm-docs](https://github.com/norwoodj/helm-docs) and checked in CI.

The preferred way to update the docs is to simply install the pre-commit hook, then it runs automatically on commit:
```bash
pre-commit install
```

As a fallback, you can run manually via the plugin or Docker:
```bash
helm-docs --chart-search-root=charts --template-files=README.md.gotmpl
# or
docker run --rm --volume "$PWD:/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.14.2 --chart-search-root=charts --template-files=README.md.gotmpl
```

Custom content (e.g. usage notes, instructions, etc.) can be added to a chart's docs by editing its `README.md.gotmpl`
file, found at the chart's root directory.

Do note the version of helm-docs being used in either the [.pre-commit-config.yaml](.pre-commit-config.yaml) file or
the [CI workflow](.github/workflows/helm-docs.yml). Small version changes can cause subtle differences in the output
and fail CI!

## Chart releases

The [`ccv-cell` helm chart](./charts/ccv-cell) is released on tag pushes that follow the `v*` pattern. The version in
`Chart.yaml` is overridden by CI using the git tag provided.

Custom release notes can be provided by writing up a `charts/ccv-cell/changelogs/<version>.md` file before setting the
tag.

To trigger a release, simply push release tags like so:
```shell
newVersion=v9.8.7  # the version being released
git switch main && \
  git pull && \
  git tag -a -m "Release $newVersion" "$newVersion" && \
  git push origin "$newVersion"
```

## Local testing

[`local/`](local) holds a docker-compose stack with PostgreSQL, the aggregator and the verifier, for quick local
testing. Not suitable for production. See its [README](local/README.md).
