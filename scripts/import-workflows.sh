#!/usr/bin/env bash
# Imports every workflow in workflows/ into n8n and publishes the live ones.
# Usage: ./scripts/import-workflows.sh            (all)
#        ./scripts/import-workflows.sh 1-intake   (one file, without .json)
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1

files=${1:-$(cd workflows && ls *.json | sed 's/\.json$//')}
for f in $files; do
  docker compose exec -T n8n n8n import:workflow --input="/workflows/$f.json"
  id=$(sed -n 's/^  "id": "\(.*\)",$/\1/p' "workflows/$f.json" | head -1)
  # 0-setup-sheet is a one-time manual run, so it stays unpublished
  case "$f" in 0-*) ;; *) docker compose exec -T n8n n8n publish:workflow --id="$id" ;; esac
done
# publish/import changes are picked up by the running instance after a restart
docker compose restart n8n >/dev/null && echo "n8n restarted"
