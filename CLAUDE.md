# .github — LegionIO Org-Wide GitHub Configuration

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`
- **GitHub**: https://github.com/LegionIO/.github

## Purpose

This repo holds organization-wide GitHub configuration for the LegionIO org. GitHub automatically applies community health files to all repos in the org that don't define their own.

## Directory Layout

```
.github/
├── profile/
│   └── README.md              # Org profile page (github.com/LegionIO)
├── .github/
│   └── workflows/
│       ├── ci.yml             # Reusable CI workflow (RSpec + RuboCop)
│       └── release.yml        # Reusable release workflow (gem push)
├── workflow-templates/
│   ├── rubocop.yml            # Starter template for new repos
│   ├── rubocop.svg            # Badge for the rubocop template
│   ├── rspec.yml              # Starter template for new repos
│   ├── rspec.svg              # Badge for the rspec template
│   └── sourcehawk-scan.yml    # Sourcehawk starter template
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml         # Structured bug report form
│   └── feature_request.yml   # Structured feature request form
├── CONTRIBUTING.md            # Org-wide contribution guide
├── PULL_REQUEST_TEMPLATE.md   # Default PR checklist
├── SECURITY.md                # Vulnerability reporting policy
├── README.md                  # This repo's own README
├── LICENSE                    # Apache-2.0
└── docs/
    └── TODO.md                # Consolidated project tracker for the entire LegionIO ecosystem
```

## Reusable Workflows

The two workflows under `.github/workflows/` are `workflow_call` targets — they run in other repos, not in this one.

### `ci.yml` — Ruby CI

Parameterized RSpec + RuboCop runner. All LegionIO gems should use this.

Inputs:
- `ruby-version` (default: `'3.4'`) — single version
- `ruby-versions` (default: `''`) — JSON array for matrix, overrides `ruby-version`
- `run-rspec` / `run-rubocop` — booleans, both default true
- `needs-redis` / `needs-rabbitmq` — spin up service containers

Usage in a consuming repo:
```yaml
jobs:
  ci:
    uses: LegionIO/.github/.github/workflows/ci.yml@main
    with:
      ruby-version: '3.4'
```

### `release.yml` — Gem Release

Triggers on `v*` tags, builds `*.gemspec`, publishes to RubyGems.

Required secret: `rubygems-api-key` (org-level secret `RUBYGEMS_API_KEY`)

Usage in a consuming repo:
```yaml
on:
  push:
    tags: ['v*']
jobs:
  release:
    uses: LegionIO/.github/.github/workflows/release.yml@main
    secrets:
      rubygems-api-key: ${{ secrets.RUBYGEMS_API_KEY }}
```

## Workflow Templates

`workflow-templates/` contains starter workflows shown in the GitHub Actions "new workflow" picker for org repos. These are now superseded by the reusable `ci.yml` and `release.yml` above. New repos should use the reusable workflows, not these starters.

## Community Health Files

`CONTRIBUTING.md`, `SECURITY.md`, `PULL_REQUEST_TEMPLATE.md`, and `ISSUE_TEMPLATE/` are GitHub's community health file mechanism. They apply org-wide unless a specific repo overrides them.

**Key content in each:**
- `CONTRIBUTING.md`: Dev workflow (`bundle exec rspec`, `bundle exec rubocop`), commit message conventions, LEX scaffold instructions, extension category table
- `SECURITY.md`: Vuln reporting (GitHub advisories preferred, email fallback), response SLAs, security notes for Vault/transport/API components
- `PULL_REQUEST_TEMPLATE.md`: Minimal checklist (tests, rubocop, changelog)

## What Not to Change

- Do not add repo-specific logic to the reusable workflows — they serve all 66 repos
- Do not hardcode gem names in issue templates — they ask the reporter to specify
- The org profile README (`profile/README.md`) is the public face of the org — keep it current with actual architecture

## Related

- All repos consuming `ci.yml`: Every gem in the LegionIO org with a CI workflow
- Homebrew tap: `/Users/miverso2/rubymine/legion/homebrew-tap/`
- Framework entry point: `/Users/miverso2/rubymine/legion/LegionIO/`
