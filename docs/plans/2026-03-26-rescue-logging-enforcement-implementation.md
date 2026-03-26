# Implementation Plan: Rescue Block Logging Enforcement

## Phase 1: lint-patterns.yml rules (Tier 1)

### Task 1.1: Add `rescue-bare-swallow` rule

**File**: `lint-patterns.yml`

```yaml
- id: rescue-bare-swallow
  pattern: '^\s*rescue\s*$'
  message: "Bare `rescue` swallows all StandardError silently. Capture the exception (`rescue => e`) and log it via `log.error(e.message)`."
  severity: warning
  category: rescue-logging
  paths: "lib/**/*.rb"
  exclude: "spec/**"
```

### Task 1.2: Add `rescue-no-capture` rule

**File**: `lint-patterns.yml`

```yaml
- id: rescue-no-capture
  pattern: '^\s*rescue\s+[\w:]+(?:\s*,\s*[\w:]+)*\s*$'
  message: "Exception class specified but not captured. Use `rescue SomeError => e` and log via `log.error(e.message)` or `Legion::Logging.error(e.message)`."
  severity: notice
  category: rescue-logging
  paths: "lib/**/*.rb"
  exclude: "spec/**"
```

### Task 1.3: Add `rescue-logging` category to framework-conventions job

**File**: `.github/workflows/lint-patterns.yml`

Add `"rescue-logging"` to the `CATEGORIES` array in the `framework-conventions` job, OR create a dedicated `rescue-logging` job (preferred for visibility).

## Phase 2: Multi-line script (Tier 2)

### Task 2.1: Create `scripts/check-rescue-logging.rb`

A standalone Ruby script (~60-80 lines) that:

1. Reads a list of file paths from ARGV or stdin
2. For each file, scans for `rescue ... => <var>` lines
3. Collects the body lines until the next `end`, `rescue`, `ensure`, or `else` at the same indentation
4. Checks the body for at least one of the allowed logging patterns:
   - `/Legion::Logging\.(debug|info|warn|error|fatal)/`
   - `/\blog\.(debug|info|warn|error|fatal)/`
   - `/\blogger\.(debug|info|warn|error|fatal)/`
   - `/\brunner_exception\b/`
   - `/\braise\b/`
5. Skips files matching exclusion globs (`spec/**`, `legion-logging/lib/**`)
6. Outputs GitHub annotation format: `::warning file=X,line=N,title=rescue-silent-capture::...`
7. Exits with code 1 if any `error`-severity findings, 0 otherwise

### Task 2.2: Add `rescue-logging` job to lint-patterns.yml workflow

**File**: `.github/workflows/lint-patterns.yml`

New job following the same pattern as the existing three:

```yaml
rescue-logging:
  name: Rescue Logging
  runs-on: ${{ inputs.runner || 'ubuntu-latest' }}
  steps:
    - name: Checkout
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - name: Fetch rescue-logging script
      # Download check-rescue-logging.rb from LegionIO/.github
    - name: Get changed files
      # Same pattern as other jobs
    - name: Check rescue logging patterns (regex)
      # Run lint-patterns.yml rescue-logging category rules
    - name: Check rescue logging patterns (multi-line)
      # Run check-rescue-logging.rb against changed files
```

## Phase 3: Documentation

### Task 3.1: Update CLAUDE.md

Add rescue-logging convention to the `.github/CLAUDE.md` file under the lint-patterns section.

### Task 3.2: Update CONTRIBUTING.md

Add a note about the rescue-logging requirement to the org-wide contributing guide.

## File Changes Summary

| File | Action |
|------|--------|
| `lint-patterns.yml` | Add 2 rules (rescue-bare-swallow, rescue-no-capture) |
| `scripts/check-rescue-logging.rb` | Create (~60-80 lines) |
| `.github/workflows/lint-patterns.yml` | Add rescue-logging job |
| `CLAUDE.md` | Add rescue-logging section |
| `CONTRIBUTING.md` | Add rescue-logging note |

## Spec Coverage

No runtime specs needed — this is CI-only. The script should be tested manually against known good/bad files before merging.

## Dependencies

None. Uses only Ruby stdlib (ships with the runner).

## Rollout

1. Merge with `warning` severity — no CI breakage
2. Fix existing violations across repos (can be a sweep PR per repo)
3. Optionally escalate to `error` for lex-* repos after violations are fixed
