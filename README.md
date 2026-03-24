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
  agent.yml          # Single entry point — provisions everything
roles/
  common/            # OS detection and base packages
  chrome/            # Google Chrome stable (headless)
  caddy/             # Caddy reverse proxy + HTTPS
  signal_cli/        # signal-cli + Java
  agent_config/      # SSH keys, GitHub PAT, Twilio, Google OAuth
  openclaw_config/   # openclaw.json templating + workspace pull
vendor/
  openclaw-ansible/  # Submodule: user, Node.js, pnpm, OpenClaw, firewall
media/               # Avatar assets
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
