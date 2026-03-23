#!/usr/bin/env bash
set -euo pipefail

# Apply generated CODEOWNERS files to LegionIO repos via GitHub Contents API.
#
# Usage:
#   scripts/apply-codeowners.sh              # apply to all repos
#   scripts/apply-codeowners.sh legion-llm   # apply to one repo
#   scripts/apply-codeowners.sh --dry-run    # show what would change
#
# Requires: gh CLI authenticated with repo write access

ORG="LegionIO"
GENERATED_DIR="codeowners-generated"
DRY_RUN=false
TARGET_REPO=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [repo-name]"
      echo ""
      echo "Apply generated CODEOWNERS to LegionIO repos."
      echo "Run from the .github repo root."
      exit 0
      ;;
    *) TARGET_REPO="$arg" ;;
  esac
done

if [ ! -d "$GENERATED_DIR" ]; then
  echo "Error: ${GENERATED_DIR}/ not found. Run the sync-codeowners workflow first."
  exit 1
fi

APPLIED=0
SKIPPED=0
FAILED=0

apply_codeowners() {
  local repo="$1"
  local local_file="${GENERATED_DIR}/${repo}/CODEOWNERS"

  if [ ! -f "$local_file" ]; then
    echo "SKIP ${repo} — no generated CODEOWNERS"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  local new_content
  new_content=$(cat "$local_file")
  local encoded
  encoded=$(printf '%s' "$new_content" | base64)
  local api_path="repos/${ORG}/${repo}/contents/.github/CODEOWNERS"

  # Fetch current file to check if update is needed
  local remote_json
  remote_json=$(gh api "$api_path" 2>/dev/null || echo "")

  if [ -n "$remote_json" ]; then
    local remote_content
    remote_content=$(echo "$remote_json" | gh api --input - --jq '.content' /dev/stdin 2>/dev/null || \
                     printf '%s' "$remote_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('content',''))" 2>/dev/null || echo "")
    remote_content=$(printf '%s' "$remote_content" | base64 -d 2>/dev/null || echo "")
    local sha
    sha=$(printf '%s' "$remote_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null || echo "")

    if [ "$remote_content" = "$new_content" ]; then
      SKIPPED=$((SKIPPED + 1))
      return
    fi

    if $DRY_RUN; then
      echo "UPDATE ${repo}"
      diff <(echo "$remote_content") <(echo "$new_content") || true
      return
    fi

    if gh api --method PUT "$api_path" \
      -f message="update CODEOWNERS from team-config.yml" \
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
      echo "CREATE ${repo}"
      cat "$local_file"
      echo ""
      return
    fi

    if gh api --method PUT "$api_path" \
      -f message="add CODEOWNERS from team-config.yml" \
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
  apply_codeowners "$TARGET_REPO"
else
  for dir in "${GENERATED_DIR}"/*/; do
    repo=$(basename "$dir")
    apply_codeowners "$repo"
  done
fi

echo ""
if $DRY_RUN; then
  echo "Dry run complete. No changes made."
else
  echo "Applied: ${APPLIED} | Skipped (up-to-date): ${SKIPPED} | Failed: ${FAILED}"
fi
