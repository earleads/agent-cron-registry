#!/bin/bash
# One-time setup: creates the "Scheduled Jobs" registry database in Notion.
#
# Usage:
#   ./scripts/setup-notion-db.sh <parent_page_id>
#
# Requires NOTION_API_TOKEN in the environment (or a .env file in the repo
# root — this script auto-sources it). <parent_page_id> is the Notion page
# your integration has been shared with (Share -> Invite -> your integration).
#
# On success, prints the new database ID. Save it as NOTION_REGISTRY_DB_ID
# in your .env — every other script in this repo reads it from there.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && { set -a; source "$SCRIPT_DIR/.env"; set +a; }

PARENT_PAGE_ID="${1:-}"

if [ -z "$PARENT_PAGE_ID" ]; then
  echo "Usage: $0 <parent_page_id>" >&2
  echo "  (the Notion page you shared your integration with)" >&2
  exit 1
fi

if [ -z "${NOTION_API_TOKEN:-}" ]; then
  echo "FATAL: NOTION_API_TOKEN not set. Copy .env.example to .env and fill it in." >&2
  exit 1
fi

RESPONSE=$(curl -s -X POST "https://api.notion.com/v1/databases" \
  -H "Authorization: Bearer $NOTION_API_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d @- <<JSON
{
  "parent": { "type": "page_id", "page_id": "$PARENT_PAGE_ID" },
  "title": [{ "type": "text", "text": { "content": "Scheduled Jobs" } }],
  "properties": {
    "Name": { "title": {} },
    "Cron expression": { "rich_text": {} },
    "Plain English schedule": { "rich_text": {} },
    "Command": { "rich_text": {} },
    "Machine": { "rich_text": {} },
    "Registered by": { "rich_text": {} },
    "Status": {
      "select": {
        "options": [
          { "name": "Active", "color": "green" },
          { "name": "Paused", "color": "yellow" }
        ]
      }
    },
    "Last updated": { "date": {} }
  }
}
JSON
)

DB_ID=$(echo "$RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'id' not in d:
    print('ERROR: ' + json.dumps(d), file=sys.stderr)
    sys.exit(1)
print(d['id'])
")

echo ""
echo "Database created."
echo "Add this to your .env:"
echo ""
echo "NOTION_REGISTRY_DB_ID=$DB_ID"
echo ""
