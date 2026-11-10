#!/usr/bin/env bash
# Runs a scheduled workflow immediately (for testing), using its "Run now (test)" trigger.
# Usage: ./scripts/run-now.sh reminders     (workflow 2: tomorrow's reminders)
#        ./scripts/run-now.sh summary       (workflow 3: daily Telegram summary)
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1

case "${1:-}" in
  reminders) id=clinicReminders1 ;;
  summary)   id=clinicSummary001 ;;
  *) echo "usage: $0 reminders|summary" >&2; exit 1 ;;
esac
# a separate task-broker port, because the running n8n already uses the default one
docker compose exec -T -e N8N_RUNNERS_BROKER_PORT=5690 n8n n8n execute --id="$id" 2>&1 \
  | grep -E '^  "status"|"text": "|Execution error|rror:' | sed 's/\\n/\n/g' | head -40
