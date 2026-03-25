<p align="center">
  <img src="media/ziggy-avatar/square-500x500.png" width="300" alt="Ziggy" />
</p>

# Ziggy — Ansible Deployment

Ansible playbooks for provisioning Ziggy's VM on a fresh Debian/Ubuntu server. Uses [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) as a submodule for the base OpenClaw installation, then layers on Ziggy-specific config: Signal, Caddy, Chrome, credentials, and workspace.

One playbook. One command. Everything from bare metal to running agent.

## What It Does

- Creates the `openclaw` system user
- Installs Node.js, pnpm, and OpenClaw
- Configures UFW firewall and fail2ban
- Installs headless Chrome, Caddy (HTTPS), and signal-cli
- Deploys API keys, OAuth tokens, SSH keys, and Twilio credentials
- Templates `openclaw.json` from your secrets file
- Clones the workspace repo and starts the gateway

## Structure

```
playbooks/
  agent.yml            # Single entry point — provisions everything
roles/
  common/              # OS detection and base packages
  chrome/              # Google Chrome stable (headless)
  caddy/               # Caddy reverse proxy + HTTPS
  signal_cli/          # signal-cli + Java
  agent_config/        # SSH keys, GitHub PAT, Twilio, Google OAuth
  openclaw_config/     # openclaw.json templating + workspace pull
vendor/
  openclaw-ansible/    # Submodule: user, Node.js, pnpm, OpenClaw, firewall
media/                 # Avatar assets
```

## Prerequisites

- A Debian or Ubuntu server (tested on Debian 12, Ubuntu 22.04+)
- SSH access with sudo
- Ansible installed on your local machine (`pip install ansible`)
- A secrets file with your API keys and credentials (see `secrets.example.yml`)

## Getting Started

```bash
# Clone with the submodule
git clone --recurse-submodules git@github.com:ybroze/ziggy-ansible.git
cd ziggy-ansible

# Set up your inventory and secrets
cp inventory.example.yml inventory.yml   # edit with your server IP
cp secrets.example.yml secrets.yml       # fill in your keys and credentials
ansible-vault encrypt secrets.yml        # encrypt before committing

# Provision
ansible-playbook playbooks/agent.yml -i inventory.yml \
  --ask-become-pass \
  --extra-vars @secrets.yml
```

## Updating

```bash
# Pull latest upstream OpenClaw role
git submodule update --remote vendor/openclaw-ansible
git add vendor/openclaw-ansible
git commit -m "Update openclaw-ansible submodule"

# Re-provision (idempotent — safe to run repeatedly)
ansible-playbook playbooks/agent.yml -i inventory.yml \
  --ask-become-pass \
  --extra-vars @secrets.yml
```

## Notes

- Signal account registration is stateful and can't be fully automated. See the `signal_cli` role for details.
- The secrets file should **never** be committed unencrypted. Use `ansible-vault` or store it outside the repo.

## Or Just Ask

You don't have to touch any of this directly. Once Ziggy is running, she has full access to her own workspace and the `openclaw` user's home directory — she can read and write files, run shell commands, manage the SQLite database, edit her own config, and commit to git.

**What she can do on the VPS:**
- Read, write, and edit any file owned by `openclaw` (workspace, config, memory, DB)
- Run shell commands as `openclaw` (install npm packages, query APIs, run scripts)
- Manage cron jobs, heartbeat tasks, and her own OpenClaw configuration
- Commit and push to git repos she has SSH access to
- Access external services (Gmail, Google Calendar, Twilio, web search, browser automation)

**What she cannot do:**
- Anything requiring `sudo` or root (no package installs via apt, no firewall changes, no systemd management)
- Modify files outside `openclaw`'s ownership (e.g., `/var/www/`, `/etc/`)
- Ansible runs — those come from your local machine

So if you want to add a contact, change a heartbeat task, tweak the database, or update workspace files — you can just message her and ask. The Ansible playbook is for provisioning and reprovisioning the server itself; day-to-day operations are conversational.

## Using the EA

Once provisioned, Ziggy functions as an executive assistant reachable via Signal (and optionally Telegram). She manages contacts, email, SMS, and calendar — all backed by a local SQLite database at `~/.config/ziggy/memory.db`.

### The Agent Definition

The Ansible repo provisions the server. But the agent itself — its personality, memory, and operating instructions — lives in a separate workspace repo (e.g., [`ybroze/ziggy-bot`](https://github.com/ybroze/ziggy-bot)). This is what makes the agent *yours*.

The workspace is a collection of markdown files that the agent reads on every session. Think of it as a character sheet, employee handbook, and filing cabinet rolled into one:

| File | Purpose |
|------|---------|
| **SOUL.md** | The agent's personality, values, tone, and behavioral rules. This is who they *are*. How they talk, when they push back, what they won't do. Write it like you're describing a person you want to work with. |
| **USER.md** | About you — timezone, communication style, preferences, shorthands. Helps the agent adapt to how *you* work rather than forcing you to adapt to it. |
| **IDENTITY.md** | Name, pronouns, avatar, vibe. The basics. |
| **AGENTS.md** | Operating procedures — what to do on startup, how to handle contacts, access rules, safety constraints. The employee handbook. |
| **TOOLS.md** | Notes about external tools, credentials, and conventions. Where things are and how to use them. |
| **HEARTBEAT.md** | Periodic tasks (see [Setting Up the Heartbeat](#setting-up-the-heartbeat)). |
| **LESSONS.md** | Hard-won rules from past mistakes. Things the agent should never do again. |

#### Memory

The agent wakes up fresh every session. It has no built-in recollection of yesterday. Memory is entirely file-based:

- **`MEMORY.md`** — Long-term memory. Curated, distilled, persistent. The agent reads this on startup and updates it over time. Think of it as what a good assistant would *remember* after working with you for months — your preferences, key people, ongoing projects, important decisions.

- **`memory/YYYY-MM-DD.md`** — Daily notes. Raw logs of what happened each day. Short-term memory. The agent writes these as it works and reads recent ones for context. Old daily notes fade in relevance; the important bits get promoted to `MEMORY.md`.

The pattern is human: daily notes are your scratchpad, long-term memory is what sticks. The agent maintains both, but you can read, edit, or correct either at any time.

#### Making It Yours

You can start with an empty workspace and build up over time. Tell the agent about yourself and it'll update `USER.md`. Correct its behavior and it'll update `LESSONS.md`. Describe the personality you want and it'll write `SOUL.md`. Or write these files yourself — they're just markdown.

The workspace repo is yours to version, fork, or keep private. The Ansible playbook clones it during provisioning and the agent manages it from there.

### Systems Thinking

An AI agent without persistent storage is just a chatbot — it forgets everything between sessions. The real power comes when the agent can accumulate knowledge over time.

That's what databases are for here. SQLite ships with the server so the agent can create and manage databases as needed — contacts, conversation history, email tracking, scheduling state, whatever the job requires. You don't define the schema upfront; the agent builds what it needs based on what you ask it to do.

Think of it this way: the workspace files (`MEMORY.md`, `HEARTBEAT.md`, etc.) are the agent's working notes. Databases are the structured records — the filing cabinet. Together they give the agent real continuity: it remembers who people are, what it's already done, and what it's supposed to do next.

You don't need to think about databases at all. Just tell the agent what you need tracked and it'll figure out the storage.

### Setting Up the Heartbeat

Heartbeats let the agent check things proactively — email, SMS, calendar, whatever you need — on a recurring loop. We recommend a 5-minute interval.

To set it up, just message the agent:

> _"Check my email every heartbeat. Send me a morning briefing at 8 AM with my calendar. Poll for new SMS and forward anything to me."_

She'll configure `HEARTBEAT.md` (the task list) and `openclaw.json` (the interval) herself. You can add, change, or remove heartbeat tasks the same way — just tell her what you want.

If the heartbeat file is empty or missing, heartbeats are no-ops and cost nothing.

### Talking to the Agent

Be specific. The agent does exactly what you say — no more, no less. Vague instructions produce vague results.

| ❌ Vague | ✅ Specific |
|----------|------------|
| "Check my email" | "Check ziggy@example.com for unread emails every heartbeat. Reply to real people, skip automated notifications, mark everything as read." |
| "Send me a morning update" | "Send me a calendar summary at 8:00 AM Central, once per day. If no events, say so." |
| "Remind me about the meeting" | "Remind me at 2:45 PM Central today about my 3:00 PM call with Dave." |

Timing, frequency, recipients, format, what to skip, what to include — say it explicitly. If you leave it ambiguous, the agent will either ask for clarification or make a reasonable default that might not be what you wanted.

---

<p align="center">
  <em>"In the event of a provisioning failure, there is a 95.6% probability<br>that something is wrong with your secrets file."</em><br><br>
  🧩<br><br>
  <sub>Theorizing that one could automate what had gone wrong in their life,<br>Dr. Sam Beckett stepped into the Ansible accelerator — and vanished.<br>He awoke to find himself trapped in a fresh VPS, facing config files<br>that were not his own, and driven by an unknown force to put right<br>what once went wrong. And hoping each <code>ansible-playbook</code> run<br>will be the run — that takes him <code>$HOME</code>.</sub>
</p>
