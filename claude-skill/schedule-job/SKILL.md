# Skill: Schedule Job

## Purpose
Lets you ask your agent in chat to schedule something — "run my morning report
every weekday at 8am" — and have it actually happen: registered in the shared
Notion table AND installed as a real cron job, in one step. No manual crontab
editing, no separate tool per job type, no jobs nobody else on the team can see.

## When to use
Trigger phrases: "schedule X", "run this every day/week at Y", "set up a cron
for Z", "stop running X" (unregister), "what's currently scheduled" (list).

## Steps

### Step 0: Prerequisites check
Confirm `NOTION_API_TOKEN` and `NOTION_REGISTRY_DB_ID` are set (source the
repo's `.env`). If `NOTION_REGISTRY_DB_ID` is missing, tell the user to run
`scripts/setup-notion-db.sh <parent_page_id>` once first — don't guess a
database ID.

### Step 1: Turn the request into a cron expression
Convert the user's plain-English schedule ("every weekday at 8am", "every
Monday at 9", "every 15 minutes") into a standard 5-field cron expression.
Confirm your interpretation back to the user in plain English before running
anything if there's any ambiguity (e.g. "weekday" could mean Mon-Fri or every
day — ask if unclear).

### Step 2: Confirm the exact command that will run
Never guess a shell command from a vague description. If the user says
"run my morning report", find the actual script/command that does that in
their repo (grep for it, ask if you can't find it) — don't invent one.

### Step 3: Register it
```
./scripts/register-job.sh "<name>" "<cron expression>" "<plain English schedule>" "<command>"
```
This writes the row to Notion and installs the cron entry in the same step.

### Step 4: Confirm back to the user
Plain English: what got scheduled, how often, and that it's now visible in
the shared Scheduled Jobs table.

## Listing what's scheduled
```
./scripts/list-jobs.sh
```

## Unregistering a job
Remove the crontab line manually (`crontab -l`, edit, `crontab -`) and set
the row's Status to "Paused" or delete it in Notion. There's no automated
unregister script yet — do this by hand until one exists.

## Guardrails
- Never fabricate a cron expression or command — verify against the user's
  actual repo/scripts.
- Never bypass `scripts/register-job.sh` with a raw `crontab` edit — the
  PreToolUse hook (`scripts/hooks/block-unregistered-cron.sh`) blocks this
  if it's wired up, but don't rely on the hook; follow the process anyway.
