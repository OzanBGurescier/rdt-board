# RDT Task Board

A kanban board for the NYU Robotic Design Team. It's a static site on GitHub Pages, with a free Supabase database behind it.

- **Anyone with the link** can view the board.
- **Team members you create accounts for** can sign in and add, edit, move and delete tasks and columns.
- Changes show up on everyone's screen within a second, on phone or desktop.

## Files

| File | What it is |
|---|---|
| `index.html` | The whole board (layout, styles, logic). |
| `config.js` | Your Supabase URL and key, board title, and suggested labels. **The only file you edit.** |
| `schema.sql` | Creates the database tables and access rules. Run it once in Supabase. |
| `.github/workflows/keepalive.yml` | Pings the database every 3 days so the free project never pauses. |

If `config.js` has no keys, the board runs in **demo mode**: it shows sample data and saves changes only in that browser.

---

## Setup (about 20 minutes)

### 1. Create the Supabase project

1. Go to **supabase.com** and sign in with GitHub.
2. Click **New project**.
   - **Name:** `rdt-board`
   - **Database password:** click *Generate*, then save it in your password manager. The board never uses it, but you'll need it if you ever connect to the database directly.
   - **Region:** East US (North Virginia), the closest to NYC.
3. Click **Create new project** and wait about a minute for it to finish.

### 2. Create the tables and rules

1. Open `schema.sql` and scroll to **section 6** at the bottom. Put in your own login email (it's set to `ozangurescier@nyu.edu`) and add a line for each teammate:
   ```sql
   insert into public.editors (email, name) values
     ('ozangurescier@nyu.edu', 'Ozan')
     , ('alex@nyu.edu', 'Alex')
     , ('priya@nyu.edu', 'Priya')
   on conflict (email) do update set name = excluded.name;
   ```
   The `name` is what appears in the Owner dropdown and on card avatars.
2. In Supabase, open **SQL Editor** (left sidebar) and click **New query**. Paste the whole file and click **Run**.
3. You should see *Success. No rows returned*. Under **Table Editor** you'll now have three tables: `board_columns` (already holding the 5 starter columns), `tasks` and `editors`.

The file is safe to re-run later, for example after adding more editors.

### 3. Lock sign-ups and create the team's accounts

Supabase's free built-in email service only delivers to members of your own Supabase organization, at 2 emails per hour. So the board doesn't send any emails. You create the accounts yourself.

1. Go to **Authentication → Sign In / Providers**. Under *User Signups*, turn **off** "Allow new users to sign up" and save. Make sure the **Email** provider stays enabled. (The Supabase dashboard renames things sometimes; the setting is "Allow new users to sign up".)
2. Go to **Authentication → Users → Add user → Create new user**.
   - Enter the teammate's email (the same one you put in `editors`) and a temporary password.
   - Tick **Auto Confirm User**, then click **Create user**.
3. Repeat for yourself and each teammate. Send each person their temporary password. Once signed in, they can change it from their name in the top-right → **Change password**.

**Adding someone later:** create their user (step 2), then add a row in **Table Editor → editors** with the same email and their display name.
**Removing someone:** delete their row in `editors`, which makes them view-only immediately. Optionally delete their user too.

### 4. Copy the keys into `config.js`

1. In Supabase, go to **Project Settings → API Keys** (on some dashboards it's **Settings → API**, or the **Connect** button at the top).
2. Copy the **Project URL** (`https://xxxx.supabase.co`) and the **publishable** key, which may be labelled **anon public** (it starts with `sb_publishable_` or `eyJ`).
3. Paste both into `config.js`:
   ```js
   SUPABASE_URL: "https://xxxx.supabase.co",
   SUPABASE_ANON_KEY: "sb_publishable_...",
   ```

The publishable/anon key is meant to sit in public web pages. The rules from step 2 control who can write, not the key.
**Never paste the `secret` / `service_role` key anywhere in the site.** It bypasses every rule.

### 5. Publish on GitHub Pages

1. On GitHub, click **New repository**. Name it `rdt-board`, set it to **Public** (free Pages needs a public repo), and create it.
2. Click **uploading an existing file** and drag in `index.html`, `config.js`, `schema.sql` and `README.md`. Commit.
3. Add the keep-alive workflow. Hidden folders like `.github` often get dropped when you drag files, so create it by hand:
   - Click **Add file → Create new file**.
   - Type the name `.github/workflows/keepalive.yml`. The slashes create the folders.
   - Paste in the contents of `keepalive.yml` and commit.
4. Go to **Settings → Pages**. Under *Build and deployment*, choose **Deploy from a branch**, then **main** and **/ (root)**, and click **Save**.
5. After a minute or two the board is live at **https://ozanbgurescier.github.io/rdt-board/**.

To change the site later, edit the file on GitHub (pencil icon) or upload a new version. Pages redeploys on its own within about a minute.

### 6. Turn on the keep-alive

Free Supabase projects pause after about 7 days without database activity. A paused project keeps all its data and can be resumed from the dashboard. The keep-alive stops it from pausing in the first place.

1. In the repo, go to **Settings → Secrets and variables → Actions → New repository secret**, and add two secrets:
   - `SUPABASE_URL`: your Project URL
   - `SUPABASE_ANON_KEY`: the same publishable key as in `config.js`
2. Open the **Actions** tab. If GitHub asks, enable workflows.
3. Click **Supabase keep-alive → Run workflow** once. It should finish green and print `HTTP 200`.

GitHub switches off scheduled workflows in a public repo that has had no commits for 60 days, and emails you when it does. If that happens, open **Actions → Supabase keep-alive → Enable workflow**. Any commit to the repo also resets the 60-day timer.

### 7. Check it works

- [ ] Open the site in a private window. You see the board, a "View only" banner, and no Add buttons.
- [ ] Sign in. Your initials appear top-right and the Add buttons show up.
- [ ] Add a task on your laptop. Within a second it appears on your phone with the board open.
- [ ] Sign in with an account that isn't in `editors`. You see "this account isn't on the editors list" and can't edit.

---

## Backing up and exporting

**From the board** (anyone can download; restoring requires being an editor):

- **Backup → Download backup (JSON):** every column and task. This is the file to keep.
- **Backup → Download spreadsheet (CSV):** opens in Excel or Google Sheets, one row per task, for reports or review meetings.
- **Backup → Restore from backup…:** loads a JSON backup back in. Tasks with the same ID are overwritten with the backup's version, and anything missing is added back. Nothing gets deleted. Backup columns whose names match existing columns are merged into them, so restoring into a fresh project doesn't duplicate columns.

**From Supabase:** **Table Editor → tasks → Export → CSV** gives you the raw table.

Don't count on Supabase's own backups on the free plan. Download a JSON backup after big planning sessions and at least once a month, and keep it in the team drive.

---

## Everyday use

- **Move a card:** drag it. On a phone, press and hold for a moment, then drag. You can also open the card and change **Status**.
- **Take a task:** open it and click **Assign to me**.
- **Columns:** use **+ Add column** at the right end. Each column's **⋯** menu lets you rename, move left or right, or delete it (it has to be empty first).
- **Filters:** by owner (including *Unassigned*), label, and due date (overdue, next 7 or 14 days, no date), plus text search. Filters are remembered per browser.
- **Colors:** the left edge of each card shows priority (red urgent, orange high, purple medium, gray low). Due dates turn amber within 2 days and red when overdue. Cards in a column named **Done** are never marked overdue.
- **Labels:** the suggested labels come from `LABELS` in `config.js`. You can also type any new label on a card.

## Troubleshooting

| What you see | Fix |
|---|---|
| "Not saved: this account isn't on the editors list" | The email in `editors` must match the login email exactly. Check for typos and stray spaces. |
| "Can't reach the database…" | Check your internet. If that's fine, open the Supabase dashboard: if the project says *Paused*, click **Resume project** (your data is intact). Then make sure the keep-alive action is running. |
| "Wrong email or password" | Reset it under **Authentication → Users →** (user) **→ Send password recovery**. That email only reaches org members, so it's easier to delete the user and recreate them with a new temporary password. |
| Board shows demo data on the live site | `config.js` still has empty keys, or the browser cached an old copy. Hard-refresh with Ctrl/Cmd+Shift+R. |
| Changes from others don't appear live | Refresh the page. Also check that section 4 of `schema.sql` ran (it enables live updates). |

**Privacy:** the board is public read-only, so don't put passwords, personal info or sponsor-confidential details in tasks.
