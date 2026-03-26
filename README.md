<p align="center">
  <img src="media/hero-banner.jpg" width="100%" alt="Agent Ansible" />
</p>

# Agent Ansible

One playbook. One command. Everything from bare metal to running agent.

Ansible playbooks for provisioning an AI agent VM on a fresh Debian/Ubuntu server. Currently uses [OpenClaw](https://github.com/openclaw/openclaw-ansible) as the backend, with the architecture designed so the backend is swappable and the agent definition — the workspace — is what's portable.

## What It Does

- Creates a system user for the agent
- Installs Node.js, pnpm, and the backend (OpenClaw)
- Configures UFW firewall and fail2ban
- Installs headless Chrome, Caddy (HTTPS), and signal-cli
- Deploys API keys, SSH keys, and service credentials
- Templates backend configuration from your secrets file
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
  credentials/         # SSH keys, GitHub PAT, Twilio, Google password
  workspace/           # Workspace git clone, sync, and memory directory
  openclaw_config/     # OpenClaw backend: config templating + health check
vendor/
  openclaw-ansible/    # Submodule: user, Node.js, pnpm, OpenClaw, firewall
```

## Key Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `agent_user` | `openclaw` | System user the agent runs as |
| `agent_home` | `/home/openclaw` | Home directory |
| `agent_name` | `agent` | Used for config directory naming (`~/.config/<name>/`) |
| `agent_workspace` | `{{ agent_home }}/.openclaw/workspace` | Where the agent definition lives |
| `workspace_git_remote` | — | Git repo containing the agent's workspace files |

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
- The backend (OpenClaw) is separated from the workspace and credential roles. The workspace — the agent definition files — is what makes the agent yours and is portable across backends.

## Or Just Ask

You don't have to touch any of this directly. Once the agent is running, it has full access to its own workspace and home directory — it can read and write files, run shell commands, manage databases, edit its own config, and commit to git.

**What the agent can do on the VPS:**
- Read, write, and edit any file it owns (workspace, config, memory, DB)
- Run shell commands (install npm packages, query APIs, run scripts)
- Manage cron jobs, heartbeat tasks, and its own configuration
- Commit and push to git repos it has SSH access to
- Access external services (Gmail, Google Calendar, Twilio, web search, browser automation)

**What it cannot do:**
- Anything requiring `sudo` or root (no package installs via apt, no firewall changes, no systemd management)
- Modify files outside its ownership
- Ansible runs — those come from your local machine

The Ansible playbook is for provisioning and reprovisioning the server itself; day-to-day operations are conversational.

---

<p align="center">
  <em>"In the event of a provisioning failure, there is a 95.6% probability<br>that something is wrong with your secrets file."</em><br><br>
  🧩<br><br>
  <sub>Theorizing that one could automate what had gone wrong in their lives,<br>Dr. Sam Beckett stepped into the Ansible accelerator — and vanished.<br>He awoke to find himself trapped in a fresh VPS, facing config files<br>that were not his own, and driven by an unknown force to put right<br>what once went wrong. And hoping each <code>ansible-playbook</code> run<br>will be the run — that takes him <code>$HOME</code>.</sub>
</p>
