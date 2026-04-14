# AGENTS - Project Rules

## What this repository is

Kubernetes cluster configuration (IaC) for a K3s cluster. Three Helm umbrella charts manage all workloads:

- **`helm/system/`** - infrastructure: Traefik ingress controller, External Secrets Operator
- **`helm/monitoring/`** - observability: New Relic integration bundle (nri-bundle)
- **`helm/apps/`** - applications: webhook-tester, 3proxy, RSS bot, video-dl-bot, MTProto proxy, error-pages

Shared Helm template helpers live in `helm/_shared.tpl`.

## Working in this repo

All tooling runs inside Docker. Start a shell with:

```bash
make shell
```

This mounts the repo and provides `kubectl`, `helm`, `doppler`, and `kube-linter` at pinned versions (defined in
`Dockerfile`).

> Alternatively, you need `kubectl`, `helm`, `doppler`, and `kube-linter` (and probably other tools) installed locally
> to run the Makefile targets directly.

Secrets come from Doppler. Copy `.env.example` to `.env` and set `DOPPLER_TOKEN` before running any target that needs
cluster access or secrets.

IMPORTANT: You don't need to interact with Kubernetes cluster resources directly - you should work only with files
in this repository, and applying the changes is the user's responsibility.

## Key commands

```shell
make .kube/config # generate a kube config file with cluster credentials

make helm/<chart-name>/values.yaml # generate a chart values.yaml file with secrets for the specified directory
make helm/<chart-name>/charts      # download and install Helm chart dependencies for the specified directory

make dump.<chart-name>.yaml # render the specified Helm chart into a YAML dump file
make dump                   # render all Helm charts into YAML dump files (dump.system.yaml
                            # dump.monitoring.yaml dump.apps.yaml)

make lint-system     # lint the system Helm chart
make lint-monitoring # lint the monitoring Helm chart
make lint-apps       # lint the apps Helm chart
make lint            # perform linting on all charts
```

**Installation order matters**: `system` must be installed before `monitoring` or `apps` because Traefik and External
Secrets must exist first.

## Architecture patterns

**Secret flow**:

```
Doppler
  → `values.doppler.yaml` (template)
    → `values.yaml` (generated, gitignored)
      → Helm `--values`
        → K8s Secrets via External Secrets Operator. The `values.yaml` files and `.kube/` directory are never committed.
```

**Ingress**: All HTTP(S) traffic goes through Traefik. Custom error pages are injected via a Traefik middleware that
references the `error-pages` service.

**Secret rotation**: ExternalSecret resources use a `force-sync` annotation set to the Unix epoch timestamp to trigger
re-sync without redeployment.

**Node scheduling**: Apps prefer worker nodes (`nodeSelector`) but tolerate master via pod affinity rules.

**Multi-arch**: The helper Dockerfile builds for both `linux/amd64` and `linux/arm64`.

## CI

GitHub Actions in `.github/workflows/`:
- `tests.yml` - runs on PRs/pushes: gitleaks secret scan, helm lint + kube-linter for all three charts, Docker build
- `deploy.yml` - manual trigger only; selects action (`install`/`upgrade`) and chart (`system`/`monitoring`/`apps`)

Linting skips checks for third-party chart templates (configured in `.kube-linter.yaml`).

Before modifying any `.github/workflows/*.yml` files:

1. Fetch and read the workflow syntax reference: `https://docs.github.com/api/article/body?pathname=/en/actions/reference/workflows-and-actions/workflow-syntax`
2. All workflow files use the JSON schema: `https://json.schemastore.org/github-workflow.json`

## Dependency updates

Dependency updates are automated via Renovate and Dependabot. This project uses both because Dependabot does not cover
all dependency types (e.g. custom regex patterns).

### Renovate

The Renovate configuration is located in `.github/renovate.json`, and it extends the shared configuration at
`https://raw.githubusercontent.com/iddqd-uk/.github/refs/heads/main/renovate/default.json`. Before updating it, please
check the shared config first to avoid redundant or conflicting rules.

**JSON Schema (use for validation and autocompletion)**: `https://docs.renovatebot.com/renovate-schema.json`

**Key documentation (raw Markdown from GitHub - fetch these directly)**:

| Topic                                             | URL                                                                                                       |
|---------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Config options reference                          | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/configuration-options.md           |
| Config overview (file precedence, global vs repo) | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/config-overview.md                 |
| Presets (extends, sharing config)                 | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/presets-overview.md                |
| packageRules (the main power feature)             | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/packageRules.md                    |
| Automerge                                         | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/automerge-configuration.md         |
| Self-hosted config                                | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/self-hosted-configuration.md       |
| Supported managers list                           | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/modules/manager/index.md           |
| How Renovate works                                | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/key-concepts/how-renovate-works.md |
| Noise reduction / scheduling                      | https://raw.githubusercontent.com/renovatebot/renovate/main/docs/usage/noise-reduction.md                 |

**Rendered docs (HTML, heavier)**: https://docs.renovatebot.com/configuration-options/

### Dependabot

**Config file**: `.github/dependabot.yml` - exactly one file per repo, no glob support for `directory` (use
`directories` for monorepos).

**JSON Schema**: `https://json.schemastore.org/dependabot-2.0.json`

> Note: This is community-maintained via SchemaStore, not officially published by GitHub. Mostly accurate but has
> known minor discrepancies.

**Key documentation:**

| Topic                                                  | URL                                                                                                                                       |
|--------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| Configuration options reference, Grouping updates, etc | https://docs.github.com/api/article/body?pathname=/en/code-security/reference/supply-chain-security/dependabot-options-reference          |
| Supported ecosystems                                   | https://docs.github.com/api/article/body?pathname=/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories |
| Security updates                                       | https://docs.github.com/api/article/body?pathname=/en/code-security/concepts/supply-chain-security/about-dependabot-security-updates      |

**Key behavioral notes for agents:**
- `directory` does NOT support globs - use `directories` (plural) for monorepos
- `open-pull-requests-limit` defaults to 5 for version updates, 10 for security updates; set to `0` to disable version updates
- `groups` key batches PRs; use `applies-to: security-updates` to scope to security-only
