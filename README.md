<p align="center">
  <img src="media/hero-banner.jpg" width="100%" alt="Ziggy" />
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
  caddy/               # Caddy static file server + HTTPS
  signal_cli/          # signal-cli + Java
  agent_config/        # SSH keys, GitHub PAT, Twilio, Google OAuth
  openclaw_config/     # openclaw.json templating + workspace pull
vendor/
  openclaw-ansible/    # Submodule: user, Node.js, pnpm, OpenClaw, firewall
media/                 # Hero banner for README
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

---

<p align="center">
  <em>"In the event of a provisioning failure, there is a 95.6% probability<br>that something is wrong with your secrets file."</em><br><br>
  🧩<br><br>
  <sub>Theorizing that one could automate what had gone wrong in their lives,<br>Dr. Sam Beckett stepped into the Ansible accelerator — and vanished.<br>He awoke to find himself trapped in a fresh VPS, facing config files<br>that were not his own, and driven by an unknown force to put right<br>what once went wrong. And hoping each <code>ansible-playbook</code> run<br>will be the run — that takes him <code>$HOME</code>.</sub>
</p>
