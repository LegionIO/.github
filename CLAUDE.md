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
├── scripts/
│   ├── sync-github-labels-topics.sh  # Org-wide label and topic sync (--labels, --topics, --all)
│   └── apply-labels-one-repo.sh      # Per-repo label worker (called by sync script via xargs -P 5)
├── CONTRIBUTING.md            # Org-wide contribution guide
├── PULL_REQUEST_TEMPLATE.md   # Default PR checklist
├── SECURITY.md                # Vulnerability reporting policy
├── README.md                  # This repo's own README
└── LICENSE                    # Apache-2.0
```

## Reusable Workflows

The two workflows under `.github/workflows/` are `workflow_call` targets — they run in other repos, not in this one.

### `ci.yml` — Ruby CI

Parameterized RSpec + RuboCop runner. All LegionIO gems should use this.

Inputs:
- `ruby-version` (default: `'3.4'`) — single version, used when `ruby-versions` is empty
- `ruby-versions` (default: `'["3.4", "4.0"]'`) — JSON array for matrix testing
- `run-rspec` / `run-rubocop` — booleans, both default true
- `needs-redis` / `needs-memcached` / `needs-rabbitmq` — spin up service containers

Usage in a consuming repo:
```yaml
jobs:
  ci:
    uses: LegionIO/.github/.github/workflows/ci.yml@main
    with:
      ruby-versions: '["3.4", "4.0"]'
```

### `release.yml` — Gem Release

Auto-detects version from `version.rb`, creates git tag if new, extracts changelog notes, builds gem, and publishes to both RubyGems and GitHub Packages. Triggered via `workflow_call` — the calling repo decides when to invoke it (typically on push to main).

Inputs:
- `ruby-version` (default: `'3.4'`) — Ruby version for building
- `changelog-file` (default: `'CHANGELOG.md'`) — path to changelog for release notes extraction

Required secret: `rubygems-api-key` (org-level secret `RUBYGEMS_API_KEY`)
Required permissions: `contents: write` (for git tags), `packages: write` (for GitHub Packages)

Release pipeline steps:
1. Read `version.rb` to detect current version
2. Check if `v{version}` tag exists — skip if already released
3. Extract changelog section for this version (falls back to generic note)
4. Build gem from `*.gemspec`
5. Create and push git tag
6. Create GitHub release with changelog notes and gem artifact
7. Publish to RubyGems
8. Publish to GitHub Packages

Usage in a consuming repo:
```yaml
on:
  push:
    branches: [main]
jobs:
  release:
    uses: LegionIO/.github/.github/workflows/release.yml@main
    secrets:
      rubygems-api-key: ${{ secrets.RUBYGEMS_API_KEY }}
```

Gems are published to:
- **RubyGems**: `https://rubygems.org/gems/<gem-name>`
- **GitHub Packages**: `https://rubygems.pkg.github.com/LegionIO`

## Workflow Templates

`workflow-templates/` contains starter workflows shown in the GitHub Actions "new workflow" picker for org repos. These are now superseded by the reusable `ci.yml` and `release.yml` above. New repos should use the reusable workflows, not these starters.

## Maintenance Scripts

`scripts/` contains org-wide maintenance tools for managing all LegionIO repos.

### `sync-github-labels-topics.sh`

Syncs standardized labels and topics across all active repos in the LegionIO org. Uses `gh` CLI with parallel execution (`xargs -P 5`).

```bash
./scripts/sync-github-labels-topics.sh --labels   # sync 24 labels to all repos
./scripts/sync-github-labels-topics.sh --topics    # sync topics to all repos
./scripts/sync-github-labels-topics.sh --all       # both labels and topics
```

**24 standardized labels:**
- Type: `type:bug`, `type:enhancement`, `type:docs`, `type:chore`, `type:breaking`
- Priority: `priority:critical`, `priority:high`, `priority:medium`, `priority:low`
- Area: `area:transport`, `area:crypt`, `area:data`, `area:cache`, `area:settings`, `area:logging`, `area:json`, `area:cli`, `area:api`, `area:mcp`, `area:extensions`, `area:actors`, `area:runners`
- Community: `good first issue`, `help wanted`

### `apply-labels-one-repo.sh`

Per-repo worker called by the sync script. Not intended to be run directly.

## Community Health Files

`CONTRIBUTING.md`, `SECURITY.md`, `PULL_REQUEST_TEMPLATE.md`, and `ISSUE_TEMPLATE/` are GitHub's community health file mechanism. They apply org-wide unless a specific repo overrides them.

**Key content in each:**
- `CONTRIBUTING.md`: Dev workflow (`bundle exec rspec`, `bundle exec rubocop`), commit message conventions, LEX scaffold instructions, extension category table
- `SECURITY.md`: Vuln reporting (GitHub advisories preferred, email fallback), response SLAs, security notes for Vault/transport/API components
- `PULL_REQUEST_TEMPLATE.md`: Minimal checklist (tests, rubocop, changelog)

## What Not to Change

- Do not add repo-specific logic to the reusable workflows — they serve all 300 repos
- Do not hardcode gem names in issue templates — they ask the reporter to specify
- The org profile README (`profile/README.md`) is the public face of the org — keep it current with actual architecture
- The canonical TODO tracker lives in the `docs` repo (`/Users/miverso2/rubymine/legion/docs/TODO.md`), not here

## Related

- All repos consuming `ci.yml`: Every gem in the LegionIO org with a CI workflow
- Homebrew tap: `/Users/miverso2/rubymine/legion/homebrew-tap/`
- Framework entry point: `/Users/miverso2/rubymine/legion/LegionIO/`
