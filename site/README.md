# site

Source for the two published guide pages. They're kept here so the pages are
never only-live: if you want to change what a guide says, edit it here rather
than trying to recover the source from the deployed page.

| Folder | Published at |
|---|---|
| `setup-guide/` | https://agent-cron-guide-one.vercel.app |
| `server-guide/` | https://agent-cron-server-guide.vercel.app |

Each is a single self-contained `index.html` with inline CSS. No build step, no
dependencies. To publish a change, deploy the folder to Vercel as a production
deployment and point the existing address at it.

Both pages share one style: every step leads with the plain-English sentence to
say to your coding agent, and the raw terminal command sits underneath a
"run it yourself" toggle. Keep that pattern for anything you add.
