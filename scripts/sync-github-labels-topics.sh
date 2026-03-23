#!/usr/bin/env bash
set -euo pipefail

# sync-github-labels-topics.sh
# Applies standard GitHub labels to all LegionIO repos.
# Topics were already applied 2026-03-13 (see design doc status).
# Usage:
#   ./scripts/sync-github-labels-topics.sh --labels       # apply labels only (default)
#   ./scripts/sync-github-labels-topics.sh --topics       # apply topics only
#   ./scripts/sync-github-labels-topics.sh --all          # apply both

ORG="LegionIO"
MODE="${1:---labels}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────

apply_labels_to_repo() {
  local repo="$1"
  local full_repo="${ORG}/${repo}"
  echo "  [labels] ${full_repo}"

  local labels
  labels=$(yq -o=json "${SCRIPT_DIR}/../labels.yml")
  local count
  count=$(echo "$labels" | jq length)

  for i in $(seq 0 $((count - 1))); do
    local name color desc
    name=$(echo "$labels"  | jq -r ".[$i].name")
    color=$(echo "$labels" | jq -r ".[$i].color")
    desc=$(echo "$labels"  | jq -r ".[$i].description")
    gh label create "$name" --color "$color" --description "$desc" \
      --repo "${full_repo}" --force 2>/dev/null || true
  done
}

get_topics_for_repo() {
  local repo="$1"
  case "$repo" in
    # Framework
    LegionIO)               echo "legionio,ruby,legion-framework,legion-core,mcp,model-context-protocol,sinatra,cli,async" ;;
    # Core libraries
    legion-transport)       echo "legionio,ruby,legion-core,rabbitmq,amqp" ;;
    legion-crypt)           echo "legionio,ruby,legion-core,vault,encryption,jwt" ;;
    legion-data)            echo "legionio,ruby,legion-core,sequel,database" ;;
    legion-cache)           echo "legionio,ruby,legion-core,redis,memcached,caching" ;;
    legion-json)            echo "legionio,ruby,legion-core,json" ;;
    legion-logging)         echo "legionio,ruby,legion-core,logging" ;;
    legion-settings)        echo "legionio,ruby,legion-core,configuration" ;;
    legion-llm)             echo "legionio,ruby,legion-core,ai,llm" ;;
    # Built-in extensions
    lex-node)               echo "legionio,ruby,legion-extension,legion-builtin,cluster,heartbeat" ;;
    lex-tasker)             echo "legionio,ruby,legion-extension,legion-builtin" ;;
    lex-conditioner)        echo "legionio,ruby,legion-extension,legion-builtin" ;;
    lex-transformer)        echo "legionio,ruby,legion-extension,legion-builtin" ;;
    lex-scheduler)          echo "legionio,ruby,legion-extension,legion-builtin,cron,scheduling" ;;
    task_pruner)            echo "legionio,ruby,legion-extension,legion-builtin" ;;
    lex-mesh)               echo "legionio,ruby,legion-extension,legion-builtin,networking" ;;
    lex-swarm)              echo "legionio,ruby,legion-extension,legion-builtin,multi-agent" ;;
    lex-swarm-github)       echo "legionio,ruby,legion-extension,legion-builtin,multi-agent" ;;
    lex-memory)             echo "legionio,ruby,legion-extension,legion-builtin,ai" ;;
    lex-emotion)            echo "legionio,ruby,legion-extension,legion-builtin,ai" ;;
    lex-identity)           echo "legionio,ruby,legion-extension,legion-builtin,identity,auth" ;;
    lex-trust)              echo "legionio,ruby,legion-extension,legion-builtin,security" ;;
    lex-governance)         echo "legionio,ruby,legion-extension,legion-builtin,governance" ;;
    lex-consent)            echo "legionio,ruby,legion-extension,legion-builtin,security" ;;
    lex-prediction)         echo "legionio,ruby,legion-extension,legion-builtin,ai" ;;
    lex-coldstart)          echo "legionio,ruby,legion-extension,legion-builtin,ai" ;;
    lex-conflict)           echo "legionio,ruby,legion-extension,legion-builtin,conflict-resolution" ;;
    lex-extinction)         echo "legionio,ruby,legion-extension,legion-builtin,governance" ;;
    lex-tick)               echo "legionio,ruby,legion-extension,legion-builtin,timing,clock" ;;
    lex-privatecore)        echo "legionio,ruby,legion-extension,legion-builtin,security" ;;
    # Service extensions
    lex-http)               echo "legionio,ruby,legion-extension,infrastructure" ;;
    lex-redis)              echo "legionio,ruby,legion-extension,datastore" ;;
    lex-memcached)          echo "legionio,ruby,legion-extension,datastore" ;;
    lex-elasticsearch)      echo "legionio,ruby,legion-extension,datastore" ;;
    lex-elastic_app_search) echo "legionio,ruby,legion-extension,datastore" ;;
    lex-influxdb)           echo "legionio,ruby,legion-extension,datastore" ;;
    lex-s3)                 echo "legionio,ruby,legion-extension,datastore" ;;
    lex-ssh)                echo "legionio,ruby,legion-extension,infrastructure" ;;
    lex-chef)               echo "legionio,ruby,legion-extension,infrastructure" ;;
    lex-slack)              echo "legionio,ruby,legion-extension,notifications" ;;
    lex-smtp)               echo "legionio,ruby,legion-extension,notifications" ;;
    lex-pushbullet)         echo "legionio,ruby,legion-extension,notifications" ;;
    lex-pushover)           echo "legionio,ruby,legion-extension,notifications" ;;
    lex-twilio)             echo "legionio,ruby,legion-extension,notifications" ;;
    lex-pagerduty)          echo "legionio,ruby,legion-extension,monitoring" ;;
    lex-ping)               echo "legionio,ruby,legion-extension,monitoring" ;;
    lex-health)             echo "legionio,ruby,legion-extension,monitoring" ;;
    lex-log)                echo "legionio,ruby,legion-extension,monitoring" ;;
    lex-todoist)            echo "legionio,ruby,legion-extension,productivity" ;;
    lex-sonos)              echo "legionio,ruby,legion-extension,productivity" ;;
    lex-github)             echo "legionio,ruby,legion-extension,infrastructure" ;;
    lex-claude)             echo "legionio,ruby,legion-extension,ai" ;;
    lex-openai)             echo "legionio,ruby,legion-extension,ai" ;;
    lex-gemini)             echo "legionio,ruby,legion-extension,ai" ;;
    # Default: all remaining repos get base topics
    *)                      echo "legionio,ruby,legion-extension" ;;
  esac
}

apply_topics_to_repo() {
  local repo="$1"
  local full_repo="${ORG}/${repo}"
  local topics
  topics=$(get_topics_for_repo "$repo")
  echo "  [topics] ${full_repo}: ${topics}"
  gh repo edit "${full_repo}" --add-topic "${topics}" 2>/dev/null || true
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

echo "Fetching repo list for ${ORG}..."
REPOS=$(gh repo list "${ORG}" --limit 400 --json name --jq '.[].name')
TOTAL=$(echo "$REPOS" | wc -l | tr -d ' ')
echo "Found ${TOTAL} repos."
echo ""

COUNT=0
while IFS= read -r repo; do
  COUNT=$((COUNT + 1))
  echo "[${COUNT}/${TOTAL}] ${repo}"

  case "$MODE" in
    --labels)
      apply_labels_to_repo "$repo"
      ;;
    --topics)
      apply_topics_to_repo "$repo"
      ;;
    --all)
      apply_labels_to_repo "$repo"
      apply_topics_to_repo "$repo"
      ;;
    *)
      echo "Unknown mode: $MODE. Use --labels, --topics, or --all"
      exit 1
      ;;
  esac

done <<< "$REPOS"

echo ""
echo "Done. Processed ${COUNT} repos."
