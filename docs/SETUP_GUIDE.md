# Setup guide: Agent Cron Registry

This is the plain-English version. If you're comfortable in a terminal, the
Quick Start in the README is faster — this guide is for getting it right the
first time, no assumed knowledge.

## What you're building

One shared table (in Notion) that shows every scheduled job across your
team, plus a script your AI coding agent runs whenever you ask it to
schedule something. After setup, asking your agent "run my Monday report
every Monday at 9am" results in a real job that actually runs, and a row in
a table anyone on the team can check.

## Before you start — what you need

1. **A Notion account.** Free tier works. If you don't have Notion, sign up
   at notion.so first — everything else in this guide depends on it.
2. **A machine that stays on.** Your own laptop works for testing, but jobs
   stop when it's closed or asleep. If you want jobs to keep running
   permanently, you need a machine that's always on — even a cheap $4-6/month
   virtual server is enough for this. If you don't have one yet, that's a
   separate decision — this guide works the same either way, you'll just see
   jobs pause when your laptop sleeps if that's what you're using.
3. **Claude Code installed** (or a similar chat-based coding agent), if you
   want the "just ask in chat" experience. Not required — you can run every
   script by hand instead.
4. **Fifteen minutes**, mostly spent waiting on copy-pasting IDs.

## Step 1: Get the code

Ask your coding agent to clone this repository, or run it yourself:

```
git clone https://github.com/earleads/agent-cron-registry.git
cd agent-cron-registry
```

## Step 2: Create a Notion integration (this gets you an API token)

1. Go to `notion.so/my-integrations` while logged into the Notion account you
   want to use.
2. Click "New integration". Give it any name (e.g. "Cron Registry").
3. Once created, copy the "Internal Integration Token" — this is a long
   string starting with `secret_` or `ntn_`. Keep it private, treat it like a
   password.

## Step 3: Tell Notion which page your integration can use

1. In Notion, create (or open) any page you're happy to have a new database
   live under — a "Automations" or "Team Tools" page is a sensible choice.
2. On that page, click "..." in the top right, then "Connections" (or "Add
   connections"), and select the integration you just created.
3. Copy that page's ID — it's the long string of letters and numbers at the
   end of the page's URL.

## Step 4: Set up your environment file

```
cp .env.example .env
```

Open `.env` in any text editor and paste in your integration token:

```
NOTION_API_TOKEN=your_token_from_step_2
```

Leave `NOTION_REGISTRY_DB_ID` blank for now — the next step fills it in.

## Step 5: Create the shared table

```
./scripts/setup-notion-db.sh <the-page-id-from-step-3>
```

This creates a new "Scheduled Jobs" table in Notion and prints a database
ID. Copy that ID into your `.env` file as `NOTION_REGISTRY_DB_ID`.

## Step 6: Try it

```
./scripts/register-job.sh "Say hello" "*/5 * * * *" "Every 5 minutes" "echo hello >> /tmp/hello.log"
```

Check your Notion page — a new row should appear immediately. Wait five
minutes and check `/tmp/hello.log` — it should have a line in it. Both of
those working means the whole system is wired up correctly.

Remove the test job once you've confirmed it works:

```
crontab -l | grep -v 'Say hello' | crontab -
```

(and delete or pause the row in Notion.)

## Step 7 (optional but recommended): Let your agent do this for you

If you're using Claude Code, copy the skill definition into your own
project:

```
cp -r claude-skill/schedule-job /path/to/your/project/.claude/skills/schedule-job
```

Now you can just ask your agent in chat: "schedule my morning report every
weekday at 8am" — it works out the schedule and the command, and runs
`register-job.sh` for you.

## Step 8 (optional): Add the guardrail hook

This stops your agent from quietly installing a cron job that skips the
registry — useful once more than one person is asking it to schedule things.
Add this to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "/path/to/agent-cron-registry/scripts/hooks/block-unregistered-cron.sh" }
        ]
      }
    ]
  }
}
```

## Troubleshooting

- **"NOTION_API_TOKEN not set"** — check `.env` exists (not just
  `.env.example`) and the token is pasted in with no quotes or extra spaces.
- **`setup-notion-db.sh` errors with something about "object_not_found"** —
  the integration hasn't been connected to that page yet. Redo Step 3.
- **A job shows in Notion but never runs** — check `crontab -l` on the
  machine to confirm the entry installed. Some systems need cron enabled
  separately (rare, but worth a search if it doesn't run after 10+ minutes).

## What this doesn't do (yet)

- No web dashboard — the Notion table is the only view.
- No automated way to remove a job (you edit the crontab and the Notion row
  by hand).
- Only tested against `cron`. If you're on a machine where you'd rather use
  `launchd` (macOS's native scheduler) or GitHub Actions instead, the Notion
  registry part still works the same — you'd just install the job a
  different way in Step 6 and note that in the Notion row's "Command" field.
