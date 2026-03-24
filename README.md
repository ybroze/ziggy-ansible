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

# 2. Create your secrets file (never committed)
cp secrets.example.yml ~/Secrets/ziggy-ansible-secrets.yml
# Edit with your actual values

# 3. Run
ansible-playbook playbooks/ziggy.yml \
  --ask-become-pass \
  --extra-vars @~/Secrets/ziggy-ansible-secrets.yml
```

## Secrets

**No secrets are stored in this repository — not even encrypted.**

All secrets are passed at runtime via `--extra-vars @<path>`. Keep your secrets file in `~/Secrets/` (or wherever you prefer) on your local machine.

See `secrets.example.yml` for the expected variable names and structure.

Future option: integrate with 1Password CLI for secret injection.

## Inventory

`inventory.yml` targets the Ziggy VM at 34.30.22.217. SSH as `yuri` with sudo.

## Signal Account

Signal registration is stateful and cannot be automated. The signal-cli data directory (`~/.local/share/signal-cli`) must be backed up and restored manually when reprovisioning.

## Pulling Upstream Updates

```bash
git remote add upstream https://github.com/openclaw/openclaw-ansible.git
git fetch upstream
git merge upstream/main
```
