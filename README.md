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
helm-docs --chart-search-root=charts
# or
docker run --rm --volume "$PWD:/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.14.2 --chart-search-root=charts
```

Do note the version of helm-docs being used in either the [.pre-commit-config.yaml](.pre-commit-config.yaml) file or
the [CI workflow](.github/workflows/helm-docs.yml). Small version changes can cause subtle differences in the output
and fail CI!
