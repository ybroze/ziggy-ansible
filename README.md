# ziggy-ansible

Ansible playbook for provisioning the Ziggy VM (GCP). Forked from [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) with extensions for Ziggy-specific infrastructure.

## What This Provisions

**Base (from upstream openclaw-ansible):**
- Ubuntu/Debian system packages
- Node.js 22 + pnpm
- OpenClaw (release mode, systemd service)
- Docker CE (for agent sandboxes)
- UFW firewall + fail2ban

**Ziggy extensions:**
- Google Chrome Stable (headless browser for OpenClaw)
- Caddy web server (ziggy.broze.net, auto-HTTPS)
- signal-cli + Java runtime (Signal messaging provider)
- Ziggy credentials and config (GitHub, Google OAuth, Twilio, SSH keys)
- Workspace git remote (ybroze/ziggy-bot)

## Usage

From your laptop:

```bash
# 1. Clone
git clone git@github.com:ybroze/ziggy-ansible.git
cd ziggy-ansible

# 2. Set up secrets
cp vault/secrets.yml.example vault/secrets.yml
# Edit with your actual values, then encrypt:
ansible-vault encrypt vault/secrets.yml

# 3. Run
ansible-playbook playbooks/ziggy.yml --ask-become-pass --ask-vault-pass
```

## Inventory

`inventory.yml` targets the Ziggy VM at 34.30.22.217. SSH as `yuri` with sudo.

## Secrets

All secrets live in `vault/secrets.yml` (ansible-vault encrypted, git-ignored). See `vault/secrets.yml.example` for the structure.

## Signal Account

Signal registration is stateful and cannot be automated. The signal-cli data directory (`~/.local/share/signal-cli`) must be backed up and restored manually when reprovisioning.

## Pulling Upstream Updates

```bash
git remote add upstream https://github.com/openclaw/openclaw-ansible.git
git fetch upstream
git merge upstream/main
```
