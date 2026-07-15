# Agent Cron Registry

Ask your AI coding agent to schedule something, and it just happens — logged
in one shared table everyone on your team can see, actually running as a real
job on the machine you asked it to run on.

## What this solves

Most teams end up with scheduled jobs scattered across whatever tool was
closest at the time: one report lives in n8n, one check is a Claude routine,
one script is a cron job on someone's laptop that nobody else knows exists.
Different tool every time, and no single place to see what's actually running.

This repo gives your coding agent (Claude Code, or anything with a similar
chat + shell + hooks setup) one way to schedule anything: you ask for it in
plain English, the agent works out the schedule and the command, and it
writes the job to a shared Notion table at the same time as installing the
real cron entry. One ask, one place it shows up, nothing hidden.

## What's in here

- `scripts/setup-notion-db.sh` — one-time setup, creates the shared "Scheduled
  Jobs" table in your own Notion workspace.
- `scripts/register-job.sh` — registers a job: writes the Notion row and
  installs the cron entry, in one step.
- `scripts/list-jobs.sh` — shows everything currently scheduled.
- `scripts/hooks/block-unregistered-cron.sh` — an optional guardrail that
  stops your agent from installing a cron job that skips the registry.
- `claude-skill/schedule-job/` — the skill definition that teaches Claude
  Code how to use all of the above when you ask it to schedule something.

This is **not** a copy of any specific company's internal setup. It's the
generic version of the pattern: a shared registry + a script your agent
calls + an optional enforcement hook. You point it at your own Notion
workspace and your own machine.

## Prerequisites

- A Notion account (free tier is fine) and a Notion integration token.
- **An always-on server.** This is required, not optional — this is built to
  centralize jobs for a whole team, so it needs to run somewhere that stays
  on, not on any one person's laptop. Any cheap always-on Mac or Linux box
  works. (Windows isn't supported yet — see note below.)
- Claude Code (or another chat-driven coding agent with shell + hooks
  access) if you want the "just ask in chat" experience. The scripts also
  work fine run by hand with no agent at all.
- [GitHub CLI](https://cli.github.com) (`gh`), installed and logged in.
  Not required to run the scripts, but it means you never have to type a
  `git` command yourself — just tell your agent "clone this repo" or "check
  for updates" and it handles it, with no separate authentication setup.

**Windows note:** this only supports Mac and Linux, because it schedules
jobs with `cron`, which Windows doesn't have natively. Adding Windows would
mean a second scheduling path (Task Scheduler), not a copy-paste change, so
it's left out of this first version rather than half-built. If you're on
Windows, the cheapest fix is the same always-on Linux server this guide
already requires.

## Full setup guide

Step-by-step, plain English, written for non-developers as much as
developers: **https://agent-cron-guide-one.vercel.app**

## Quick start (if you're comfortable with the terminal)

```bash
gh repo clone earleads/agent-cron-registry   # or: git clone https://github.com/earleads/agent-cron-registry.git
cd agent-cron-registry
cp .env.example .env
# fill in NOTION_API_TOKEN in .env, then:
./scripts/setup-notion-db.sh <a-notion-page-id-you-shared-with-your-integration>
# paste the printed NOTION_REGISTRY_DB_ID into .env, then:
./scripts/register-job.sh "Say hello" "*/5 * * * *" "Every 5 minutes" "echo hello >> /tmp/hello.log"
./scripts/list-jobs.sh
```

## License

MIT — use it, fork it, adapt it for your own team.
