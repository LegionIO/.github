#!/usr/bin/env bash
set -euo pipefail
# apply-labels-one-repo.sh <repo_name>
# Applies standard labels to a single LegionIO repo.
# Called in parallel by sync-github-labels-topics.sh

ORG="LegionIO"
REPO="${1:?repo name required}"
FULL="${ORG}/${REPO}"

gh label create "type:bug"          --color "#d73a4a" --description "Something isn't working"    --repo "${FULL}" --force 2>/dev/null || true
gh label create "type:enhancement"  --color "#a2eeef" --description "New feature or improvement" --repo "${FULL}" --force 2>/dev/null || true
gh label create "type:docs"         --color "#0075ca" --description "Documentation only"          --repo "${FULL}" --force 2>/dev/null || true
gh label create "type:chore"        --color "#e4e669" --description "Maintenance, deps, CI"       --repo "${FULL}" --force 2>/dev/null || true
gh label create "type:breaking"     --color "#b60205" --description "Breaking change"             --repo "${FULL}" --force 2>/dev/null || true
gh label create "priority:critical" --color "#b60205" --description "Must fix immediately"        --repo "${FULL}" --force 2>/dev/null || true
gh label create "priority:high"     --color "#d93f0b" --description "Next up"                     --repo "${FULL}" --force 2>/dev/null || true
gh label create "priority:medium"   --color "#fbca04" --description "Normal priority"             --repo "${FULL}" --force 2>/dev/null || true
gh label create "priority:low"      --color "#0e8a16" --description "Nice to have"                --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:transport"    --color "#c5def5" --description "RabbitMQ / AMQP messaging"  --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:crypt"        --color "#c5def5" --description "Encryption, Vault, JWT"      --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:data"         --color "#c5def5" --description "Database / Sequel ORM"       --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:cache"        --color "#c5def5" --description "Redis / Memcached caching"   --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:settings"     --color "#c5def5" --description "Configuration management"    --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:logging"      --color "#c5def5" --description "Logging"                     --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:json"         --color "#c5def5" --description "JSON serialization"          --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:cli"          --color "#c5def5" --description "CLI commands"                --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:api"          --color "#c5def5" --description "REST API"                    --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:mcp"          --color "#c5def5" --description "MCP server"                  --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:extensions"   --color "#c5def5" --description "Extension system / LEX"      --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:actors"       --color "#c5def5" --description "Actor execution modes"       --repo "${FULL}" --force 2>/dev/null || true
gh label create "area:runners"      --color "#c5def5" --description "Runner functions"            --repo "${FULL}" --force 2>/dev/null || true
gh label create "good first issue"  --color "#7057ff" --description "Good for newcomers"          --repo "${FULL}" --force 2>/dev/null || true
gh label create "help wanted"       --color "#008672" --description "Extra attention needed"      --repo "${FULL}" --force 2>/dev/null || true

echo "done: ${REPO}"
