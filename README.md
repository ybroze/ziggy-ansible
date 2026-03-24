# Ziggy — Ansible Deployment

Ansible playbooks for deploying Ziggy (an [OpenClaw](https://github.com/openclaw/openclaw) agent) on a Linux VPS.

Forked from [openclaw-ansible](https://github.com/openclaw/openclaw-ansible).

## What It Does

- Provisions a `openclaw` user with SSH keys and systemd user services
- Installs Node.js, pnpm, OpenClaw (release mode via npm)
- Configures signal-cli for Signal messaging
- Sets up Google Chrome (headless) for browser automation
- Deploys Caddy as HTTPS reverse proxy / static site host
- Configures UFW + fail2ban for firewall and SSH protection
- Templates `openclaw.json` with secrets from an encrypted vault

## Usage

```bash
cp inventory.example.yml inventory.yml   # edit with your host/vars
cp secrets.example.yml secrets.yml       # edit with your secrets
ansible-vault encrypt secrets.yml
ansible-playbook playbooks/install.yml --ask-vault-pass
```

## Structure

```
playbooks/
  install.yml      # Full provisioning (first run)
  deploy.yml       # Config-only updates
  agent.yml        # Agent config + templates
roles/
  common/          # Base OS setup
  openclaw/        # User, Node.js, pnpm, OpenClaw, firewall
  openclaw_config/ # openclaw.json templating
  signal_cli/      # signal-cli + Java
  chrome/          # Google Chrome stable
  caddy/           # Caddy reverse proxy
  agent_config/    # Agent-specific templates (twilio.env, etc.)
media/             # Avatar assets
```
