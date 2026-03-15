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
| `ci.yml` | RSpec + RuboCop CI — accepts matrix of Ruby versions, optional Redis/RabbitMQ service containers |
| `release.yml` | Build and publish gem to RubyGems on `v*` tags |

To use a reusable workflow from any LegionIO repo:

```yaml
# .github/workflows/ci.yml in your repo
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: LegionIO/.github/.github/workflows/ci.yml@main
    with:
      ruby-version: '3.4'
      run-rspec: true
      run-rubocop: true
```

For the release workflow:

```yaml
# .github/workflows/release.yml in your repo
name: Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    uses: LegionIO/.github/.github/workflows/release.yml@main
    secrets:
      rubygems-api-key: ${{ secrets.RUBYGEMS_API_KEY }}
```

### Workflow Templates (`workflow-templates/`)

Starter workflow templates shown in the GitHub Actions "New workflow" UI for repos in the org. These are legacy starters — active repos use the reusable workflows above instead.

| Template | Description |
|----------|-------------|
| `rubocop.yml` | RuboCop with SARIF output for GitHub code scanning |
| `rspec.yml` | RSpec with Redis service |
| `sourcehawk-scan.yml` | Sourcehawk static analysis scan |

## CI Workflow Reference

The `ci.yml` reusable workflow accepts these inputs:

| Input | Default | Description |
|-------|---------|-------------|
| `ruby-version` | `'3.4'` | Single Ruby version to test |
| `ruby-versions` | `''` | JSON array for matrix (overrides `ruby-version`) |
| `run-rspec` | `true` | Whether to run RSpec |
| `run-rubocop` | `true` | Whether to run RuboCop |
| `needs-redis` | `false` | Start Redis service container |
| `needs-rabbitmq` | `false` | Start RabbitMQ service container |

## Project Tracker

The consolidated project tracker for the entire LegionIO ecosystem lives in the `docs` repository. Canonical source: https://github.com/LegionIO/docs/blob/main/TODO.md

## License

[LICENSE](LICENSE) — Apache-2.0