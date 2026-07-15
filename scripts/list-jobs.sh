#!/bin/bash
# Show every job in the shared Scheduled Jobs registry.
#
# Usage: ./scripts/list-jobs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && { set -a; source "$SCRIPT_DIR/.env"; set +a; }

if [ -z "${NOTION_API_TOKEN:-}" ] || [ -z "${NOTION_REGISTRY_DB_ID:-}" ]; then
  echo "FATAL: NOTION_API_TOKEN and/or NOTION_REGISTRY_DB_ID not set." >&2
  exit 1
fi

RESPONSE=$(curl -s -X POST "https://api.notion.com/v1/databases/$NOTION_REGISTRY_DB_ID/query" \
  -H "Authorization: Bearer $NOTION_API_TOKEN" -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" -d '{"page_size": 100}')

echo "$RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
rows = d.get('results', [])
if not rows:
    print('No jobs registered yet. Run scripts/register-job.sh to add one.')
    sys.exit(0)

def text(prop):
    return ''.join(t.get('plain_text','') for t in prop.get('rich_text', []))

def title(prop):
    return ''.join(t.get('plain_text','') for t in prop.get('title', []))

print(f'{len(rows)} job(s) registered:\n')
for r in rows:
    p = r.get('properties', {})
    name = title(p.get('Name', {}))
    status = p.get('Status', {}).get('select', {}).get('name', '?')
    plain = text(p.get('Plain English schedule', {}))
    machine = text(p.get('Machine', {}))
    print(f'  [{status}] {name}')
    print(f'      {plain}  (on {machine})')
"
