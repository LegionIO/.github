# .github

Organization-wide GitHub configuration and reusable workflow templates for the [LegionIO](https://github.com/LegionIO) gem ecosystem.

## Contents

### Community Health Files

These files apply to all repositories in the LegionIO org when repos don't define their own:

| File | Purpose |
|------|---------|
| `profile/README.md` | GitHub org profile page (displayed at github.com/LegionIO) |
| `CONTRIBUTING.md` | Contribution guide for all LegionIO repos |
| `SECURITY.md` | Vulnerability reporting policy |
| `PULL_REQUEST_TEMPLATE.md` | Default PR template |
| `ISSUE_TEMPLATE/bug_report.yml` | Structured bug report form |
| `ISSUE_TEMPLATE/feature_request.yml` | Structured feature request form |

### Reusable Workflows (`.github/workflows/`)

Callable workflows that individual repos reference via `workflow_call`:

| Workflow | Purpose |
|----------|---------|
| `ci.yml` | RSpec + RuboCop CI — Ruby 3.4 + 4.0 matrix by default, optional Redis/Memcached/RabbitMQ service containers |
| `release.yml` | Auto-detect version from `version.rb`, create git tag, extract changelog, publish gem to RubyGems + GitHub Packages |

To use the CI workflow from any LegionIO repo:

```yaml
# .github/workflows/ci.yml in your repo
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: LegionIO/.github/.github/workflows/ci.yml@main
    with:
      ruby-versions: '["3.4", "4.0"]'
      run-rspec: true
      run-rubocop: true
```

For the release workflow:

```yaml
# .github/workflows/release.yml in your repo
name: Release
on:
  push:
    branches: [main]
jobs:
  release:
    uses: LegionIO/.github/.github/workflows/release.yml@main
    secrets:
      rubygems-api-key: ${{ secrets.RUBYGEMS_API_KEY }}
```

The release workflow auto-detects version changes by reading `version.rb` — if the version has no matching git tag, it creates the tag, builds the gem, creates a GitHub release with changelog notes, and publishes to both RubyGems and GitHub Packages.

### Composite Actions (`actions/`)

| Action | Description |
|--------|-------------|
| `legion-eval` | Run LLM evaluations as a CI quality gate via `legion eval run` — inputs: evaluator, dataset, threshold (0.0-1.0), ruby-version, model |

Usage:
```yaml
- uses: LegionIO/.github/actions/legion-eval@main
  with:
    evaluator: my-evaluator
    dataset: my-dataset
    threshold: '0.9'
```

### Workflow Templates (`workflow-templates/`)

Starter workflow templates shown in the GitHub Actions "New workflow" UI for repos in the org. These are legacy starters — active repos use the reusable workflows above instead.

| Template | Description |
|----------|-------------|
| `rubocop.yml` | RuboCop with SARIF output for GitHub code scanning |
| `rspec.yml` | RSpec with Redis service |
| `sourcehawk-scan.yml` | Sourcehawk static analysis scan |

### Maintenance Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `sync-github-labels-topics.sh` | Sync 24 standardized labels and topics across all org repos (`--labels`, `--topics`, `--all`) |
| `apply-labels-one-repo.sh` | Per-repo label worker (called by sync script via `xargs -P 5`) |

## CI Workflow Reference

The `ci.yml` reusable workflow accepts these inputs:

| Input | Default | Description |
|-------|---------|-------------|
| `ruby-version` | `'3.4'` | Single Ruby version to test (used when `ruby-versions` is empty) |
| `ruby-versions` | `'["3.4", "4.0"]'` | JSON array for matrix testing |
| `run-rspec` | `true` | Whether to run RSpec |
| `run-rubocop` | `true` | Whether to run RuboCop |
| `needs-redis` | `false` | Start Redis service container |
| `needs-memcached` | `false` | Start Memcached service container (64MB, 8MB value limit) |
| `needs-rabbitmq` | `false` | Start RabbitMQ service container |

## Release Workflow Reference

The `release.yml` reusable workflow accepts these inputs:

| Input | Default | Description |
|-------|---------|-------------|
| `ruby-version` | `'3.4'` | Ruby version for building the gem |
| `changelog-file` | `'CHANGELOG.md'` | Path to changelog for release notes extraction |

Required secret: `rubygems-api-key` (org-level secret `RUBYGEMS_API_KEY`)

Required permissions: `contents: write` (for git tags), `packages: write` (for GitHub Packages)

Publishes to:
- **RubyGems**: `https://rubygems.org/gems/<gem-name>`
- **GitHub Packages**: `https://rubygems.pkg.github.com/LegionIO`

## Project Tracker

The consolidated project tracker for the entire LegionIO ecosystem lives in the `docs` repository. Canonical source: https://github.com/LegionIO/docs/blob/main/TODO.md

## License

[LICENSE](LICENSE) — Apache-2.0
