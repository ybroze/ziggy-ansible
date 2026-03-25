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

### Setting Up the Heartbeat

The EA's proactive behavior — checking email, polling SMS, sending morning briefings — is driven by `HEARTBEAT.md` in the workspace. This file ships with the workspace repo, but if you're starting fresh (without access to the workspace repo), you'll need to create it yourself.

In your OpenClaw workspace directory (`~/.openclaw/workspace/`), create `HEARTBEAT.md` with the periodic tasks you want the agent to perform. Each task is a markdown list item describing what to check and when. Example:

```markdown
# HEARTBEAT.md

- Check ziggy@example.com inbox for unread emails. Reply appropriately, mark as read.
- Check Twilio SMS inbox for new inbound messages. Forward new ones to the owner.
- Morning briefing (once daily, ~8 AM): fetch today's calendar events and send a summary.
```

The agent reads this file on each heartbeat cycle and executes whatever's listed. If the file is empty or missing, heartbeats are no-ops.

You'll also want to configure the heartbeat interval in `openclaw.json`:

```json
{
  "heartbeat": {
    "intervalMinutes": 30
  }
}
```

The agent tracks what it's already checked in the SQLite database (via the `state` table and `memory/heartbeat-state.json`) to avoid duplicate work across heartbeats.
