#!/bin/bash
# Register a scheduled job: writes it to the shared Notion table AND installs
# the real cron entry on this machine. This is the script your AI agent
# (Claude Code, or any chat-driven coding assistant) should run whenever you
# ask it to "schedule X every day at 9am" — one ask, one place it shows up,
# the job actually runs.
#
# Usage:
#   ./scripts/register-job.sh "<name>" "<cron expression>" "<plain English schedule>" "<command>"
#
# Example:
#   ./scripts/register-job.sh "Morning report" "0 8 * * *" "Every day at 8am" \
#     "cd /home/me/myproject && ./scripts/send-report.sh"
#
# Requires NOTION_API_TOKEN and NOTION_REGISTRY_DB_ID (see .env.example).
# Run scripts/setup-notion-db.sh once first if you don't have a registry DB yet.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && { set -a; source "$SCRIPT_DIR/.env"; set +a; }

NAME="${1:-}"
CRON_EXPR="${2:-}"
PLAIN_ENGLISH="${3:-}"
COMMAND="${4:-}"

if [ -z "$NAME" ] || [ -z "$CRON_EXPR" ] || [ -z "$COMMAND" ]; then
  echo "Usage: $0 \"<name>\" \"<cron expression>\" \"<plain English schedule>\" \"<command>\"" >&2
  exit 1
fi

if [ -z "${NOTION_API_TOKEN:-}" ] || [ -z "${NOTION_REGISTRY_DB_ID:-}" ]; then
  echo "FATAL: NOTION_API_TOKEN and/or NOTION_REGISTRY_DB_ID not set." >&2
  echo "Run scripts/setup-notion-db.sh once, then fill in .env." >&2
  exit 1
fi

TAG="agent-cron-registry:${NAME}"
MACHINE="$(hostname)"
REGISTERED_BY="$(whoami)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"

# --- 1. Find or create the Notion row (idempotent — re-registering updates it) ---
EXISTING=$(curl -s -X POST "https://api.notion.com/v1/databases/$NOTION_REGISTRY_DB_ID/query" \
  -H "Authorization: Bearer $NOTION_API_TOKEN" -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"filter\":{\"property\":\"Name\",\"title\":{\"equals\":\"$NAME\"}}}")

PAGE_ID=$(echo "$EXISTING" | python3 -c "
import json, sys
d = json.load(sys.stdin)
r = d.get('results', [])
print(r[0]['id'] if r else '')
")

PROPS=$(python3 -c "
import json
props = {
  'Cron expression': {'rich_text': [{'text': {'content': '''$CRON_EXPR'''}}]},
  'Plain English schedule': {'rich_text': [{'text': {'content': '''$PLAIN_ENGLISH'''}}]},
  'Command': {'rich_text': [{'text': {'content': '''$COMMAND'''}}]},
  'Machine': {'rich_text': [{'text': {'content': '''$MACHINE'''}}]},
  'Registered by': {'rich_text': [{'text': {'content': '''$REGISTERED_BY'''}}]},
  'Status': {'select': {'name': 'Active'}},
  'Last updated': {'date': {'start': '$NOW'}},
}
print(json.dumps(props))
")

if [ -z "$PAGE_ID" ]; then
  # Create — Name (title) is only settable on create
  BODY=$(python3 -c "
import json
props = json.loads('''$PROPS''')
props['Name'] = {'title': [{'text': {'content': '''$NAME'''}}]}
print(json.dumps({'parent': {'database_id': '$NOTION_REGISTRY_DB_ID'}, 'properties': props}))
")
  curl -s -X POST "https://api.notion.com/v1/pages" \
    -H "Authorization: Bearer $NOTION_API_TOKEN" -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" -d "$BODY" > /dev/null
  echo "Created registry row for '$NAME'."
else
  curl -s -X PATCH "https://api.notion.com/v1/pages/$PAGE_ID" \
    -H "Authorization: Bearer $NOTION_API_TOKEN" -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" -d "{\"properties\": $PROPS}" > /dev/null
  echo "Updated existing registry row for '$NAME'."
fi

# --- 2. Install the real cron entry, tagged so it's traceable back to the registry ---
CRON_LINE="$CRON_EXPR $COMMAND # $TAG"
EXISTING_CRONTAB=$(crontab -l 2>/dev/null || true)
FILTERED=$(echo "$EXISTING_CRONTAB" | grep -v "# $TAG" || true)
printf '%s\n%s\n' "$FILTERED" "$CRON_LINE" | grep -v '^$' | crontab -

echo "Installed cron entry on $MACHINE:"
echo "  $CRON_LINE"
echo ""
echo "Registered in Notion and running. Check the Scheduled Jobs table any time to see what's live."
