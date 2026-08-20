# chainlink-ccv-starter-kit
Starterkit for the Chainlink CCV

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

Charts are released via [chart-releaser-action](https://github.com/helm/chart-releaser-action) whenever `charts/**`
changes on `main`. Bump a chart's `version` in its `Chart.yaml` to trigger a release.

## Local testing

[`local/`](local) holds a docker-compose stack with PostgreSQL, the aggregator and the verifier, for quick local
testing. Not suitable for production. See its [README](local/README.md).
