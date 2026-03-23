#!/usr/bin/env bash
set -euo pipefail
# apply-labels-one-repo.sh <repo_name>
# Applies standard labels (from labels.yml) to a single LegionIO repo.

ORG="LegionIO"
REPO="${1:?repo name required}"
FULL="${ORG}/${REPO}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LABELS=$(yq -o=json "${SCRIPT_DIR}/../labels.yml")
COUNT=$(echo "$LABELS" | jq length)

for i in $(seq 0 $((COUNT - 1))); do
  name=$(echo "$LABELS"  | jq -r ".[$i].name")
  color=$(echo "$LABELS" | jq -r ".[$i].color")
  desc=$(echo "$LABELS"  | jq -r ".[$i].description")
  gh label create "$name" --color "$color" --description "$desc" \
    --repo "${FULL}" --force 2>/dev/null || true
done

echo "done: ${REPO}"
