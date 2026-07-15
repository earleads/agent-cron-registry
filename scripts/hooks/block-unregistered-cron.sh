#!/bin/bash
# PreToolUse guard for Claude Code (or any agent harness with the same hook
# shape) — blocks a raw `crontab -e` or a piped `crontab -` write that isn't
# tagged as coming from register-job.sh. This is what makes registration
# non-optional: your agent physically cannot install an untracked cron job.
#
# Register in .claude/settings.json under hooks.PreToolUse (matcher: Bash).
# See docs/SETUP_GUIDE.md for the exact config snippet.
#
# Fires only when the command touches `crontab`. Everything else exits 0 fast.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)

echo "$CMD" | grep -q 'crontab' || exit 0

# Interactive edits bypass the registry entirely — always block, point at the script.
if echo "$CMD" | grep -Eq 'crontab\s+-e'; then
  cat >&2 <<'MSG'
BLOCKED: direct `crontab -e` skips the shared registry.
Use scripts/register-job.sh instead — it writes the job to Notion AND
installs the cron entry in one step, so it's visible to everyone, not
just this machine.
MSG
  exit 2
fi

# A write via `crontab -` (piping a new crontab in) must carry the
# register-job.sh tag on every new line, or we can't prove it's tracked.
if echo "$CMD" | grep -Eq 'crontab\s+-\s*$|crontab\s+-\s*<'; then
  if ! echo "$CMD" | grep -q '# agent-cron-registry:'; then
    cat >&2 <<'MSG'
BLOCKED: writing to crontab without the registry tag.
Every job must go through scripts/register-job.sh so it lands in the
shared Notion table — that's the whole point of this system (one place
to see everything scheduled, instead of jobs scattered across tools with
no visibility). If you're scripting this directly, tag the line with
"# agent-cron-registry:<job name>" and make sure that name has a
matching row in the registry.
MSG
    exit 2
  fi
fi

exit 0
