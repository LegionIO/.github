#!/usr/bin/env bash
set -euo pipefail

# Roll out the standard ci.yml to all LEX repos via GitHub Contents API.
#
# Usage:
#   scripts/rollout-ci-workflows.sh              # apply to all LEX repos
#   scripts/rollout-ci-workflows.sh lex-consul   # apply to one repo
#   scripts/rollout-ci-workflows.sh --dry-run    # show what would change
#
# Requires: gh CLI authenticated with repo write access

ORG="LegionIO"
DRY_RUN=false
TARGET_REPO=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [repo-name]"
      echo ""
      echo "Roll out standard ci.yml to LEX repos."
      echo "Run from the .github repo root."
      exit 0
      ;;
    *) TARGET_REPO="$arg" ;;
  esac
done

# The standard ci.yml content for LEX repos
STANDARD_CI='name: CI
on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '"'"'0 9 * * 1'"'"'

jobs:
  ci:
    uses: LegionIO/.github/.github/workflows/ci.yml@main

  lint:
    uses: LegionIO/.github/.github/workflows/lint-patterns.yml@main

  security:
    uses: LegionIO/.github/.github/workflows/security-scan.yml@main

  version-changelog:
    uses: LegionIO/.github/.github/workflows/version-changelog.yml@main

  dependency-review:
    uses: LegionIO/.github/.github/workflows/dependency-review.yml@main

  stale:
    if: github.event_name == '"'"'schedule'"'"'
    uses: LegionIO/.github/.github/workflows/stale.yml@main

  release:
    needs: [ci, lint]
    if: github.event_name == '"'"'push'"'"' && github.ref == '"'"'refs/heads/main'"'"'
    uses: LegionIO/.github/.github/workflows/release.yml@main
    secrets:
      rubygems-api-key: ${{ secrets.RUBYGEMS_API_KEY }}'

APPLIED=0
SKIPPED=0
FAILED=0
CUSTOM=0

rollout_repo() {
  local repo="$1"
  local api_path="repos/${ORG}/${repo}/contents/.github/workflows/ci.yml"
  local encoded
  encoded=$(printf '%s' "$STANDARD_CI" | base64)

  # Check if repo is archived
  local archived
  archived=$(gh api "repos/${ORG}/${repo}" --jq '.archived' 2>/dev/null || echo "true")
  if [ "$archived" = "true" ]; then
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  # Fetch current file
  local remote_json
  remote_json=$(gh api "$api_path" 2>/dev/null || echo "")

  if [ -n "$remote_json" ]; then
    local remote_content sha
    remote_content=$(printf '%s' "$remote_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('content',''))" 2>/dev/null || echo "")
    remote_content=$(printf '%s' "$remote_content" | base64 -d 2>/dev/null || echo "")
    sha=$(printf '%s' "$remote_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null || echo "")

    # Check if it already matches
    if [ "$remote_content" = "$STANDARD_CI" ]; then
      SKIPPED=$((SKIPPED + 1))
      return
    fi

    # Check for custom ci.yml (has inputs, services, or non-standard jobs)
    if echo "$remote_content" | grep -qE '(needs-redis|needs-rabbitmq|needs-memcached|brakeman-enabled|with:)'; then
      echo "CUSTOM   ${repo} (has custom inputs, skipping)"
      CUSTOM=$((CUSTOM + 1))
      return
    fi

    if $DRY_RUN; then
      echo "UPDATE   ${repo}"
      diff <(echo "$remote_content") <(echo "$STANDARD_CI") || true
      echo ""
      return
    fi

    if gh api --method PUT "$api_path" \
      -f message="adopt shared CI workflows" \
      -f content="$encoded" \
      -f sha="$sha" \
      --silent 2>/dev/null; then
      echo "UPDATED  ${repo}"
      APPLIED=$((APPLIED + 1))
    else
      echo "FAILED   ${repo}"
      FAILED=$((FAILED + 1))
    fi
  else
    if $DRY_RUN; then
      echo "CREATE   ${repo}"
      return
    fi

    if gh api --method PUT "$api_path" \
      -f message="add shared CI workflows" \
      -f content="$encoded" \
      --silent 2>/dev/null; then
      echo "CREATED  ${repo}"
      APPLIED=$((APPLIED + 1))
    else
      echo "FAILED   ${repo}"
      FAILED=$((FAILED + 1))
    fi
  fi

  sleep 0.3
}

if [ -n "$TARGET_REPO" ]; then
  rollout_repo "$TARGET_REPO"
else
  # Get all lex-* repos from the org
  REPOS=$(gh repo list "$ORG" --limit 400 --json name,isArchived --jq '[.[] | select(.isArchived == false) | .name | select(startswith("lex-"))] | .[]')

  TOTAL=$(echo "$REPOS" | wc -l | tr -d ' ')
  echo "Rolling out CI workflows to ${TOTAL} LEX repos"
  echo ""

  while IFS= read -r repo; do
    rollout_repo "$repo"
  done <<< "$REPOS"
fi

echo ""
if $DRY_RUN; then
  echo "Dry run complete. No changes made."
else
  echo "Applied: ${APPLIED} | Skipped (up-to-date): ${SKIPPED} | Custom (untouched): ${CUSTOM} | Failed: ${FAILED}"
fi
