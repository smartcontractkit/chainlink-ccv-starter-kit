# Local CCV Cell

A docker-compose version of the [ccv-cell](../charts/ccv-cell) chart for quick local testing: PostgreSQL, the
aggregator and the verifier, wired the same way the chart wires them.

Passwords, API keys and signing config are checked in as plaintext. This is deliberate, and it makes the stack
unsuitable for anything but local testing. You might want to regenerate them if testing the setup multiple times.

> [!CAUTION]
> The configuration provided in this docker-compose setup is not appropriate for any live environment! Use it only for
> local validation!

## Usage

```bash
docker compose up --wait
# d to detach
docker compose down        # keeps the databases in the postgres-data volume
docker compose down -v     # -v also drops them, next up starts clean
```

| Endpoint                             | What it is                      |
|--------------------------------------|---------------------------------|
| `localhost:50051`                    | Aggregator gRPC                 |
| `localhost:8080/health/{live,ready}` | Aggregator health               |
| `localhost:8100/health`              | Verifier health                 |
| `localhost:9988/health`              | Verifier bootstrap health       |
| `localhost:5432`                     | PostgreSQL, user/password `ccv` |

The verifier polls a public Sepolia RPC that rate limits aggressively. Swap `http_url` in
[config/verifier-evm.toml](config/verifier-evm.toml) for your own endpoint if you see throttling.

## Layout

`init-db.sql` creates the three databases the components expect: `aggregator`, `verifier` and `bootstrap`.
Migrations run on startup, no manual step needed.

Each file in [config/](config) is a trimmed copy of the upstream documented config it links to at the top,
pre-configured to connect to the local PostgreSQL and aggregator. The linked files at the top the source of truth and
contain further explanations of what settings you have.

| File                              | Mounted at                             | Chart equivalent             |
|-----------------------------------|----------------------------------------|------------------------------|
| `aggregator-config.toml`          | `/etc/config.toml`                     | `aggregator.config`          |
| `aggregator-secrets.toml`         | `/etc/aggregator/secrets.toml`         | `aggregator.secrets.app`     |
| `verifier-bootstrap-config.toml`  | `/etc/config.toml`                     | `verifier.bootstrap.config`  |
| `verifier-bootstrap-secrets.toml` | `/etc/bootstrap/secrets.toml`          | `verifier.secrets.bootstrap` |
| `verifier-config.toml`            | `/etc/committee-verifier/config.toml`  | `verifier.config`            |
| `verifier-app-secrets.toml`       | `/etc/committee-verifier/secrets.toml` | `verifier.secrets.app`       |
| `verifier-evm.toml`               | `/etc/evm/config.toml`                 | `verifier.evm.config`        |
