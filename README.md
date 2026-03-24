<p align="center">
  <img src="media/ziggy-avatar/square-500x500.png" width="300" alt="Ziggy" />
</p>

# Ziggy — Ansible Deployment

Ansible playbooks for provisioning Ziggy's VM. Uses [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) as a submodule for the base OpenClaw installation.

## Structure

```
playbooks/
  agent.yml          # Single entry point — provisions everything
roles/
  common/            # OS detection and base packages
  chrome/            # Google Chrome stable (headless)
  caddy/             # Caddy reverse proxy + HTTPS
  signal_cli/        # signal-cli + Java
  agent_config/      # Agent-specific templates (twilio.env, etc.)
  openclaw_config/   # openclaw.json templating
vendor/
  openclaw-ansible/  # Submodule: user, Node.js, pnpm, OpenClaw, firewall
media/               # Avatar assets
```

## Usage

```bash
# First time
git clone --recurse-submodules git@github.com:ybroze/ziggy-ansible.git
cp inventory.example.yml inventory.yml
cp secrets.example.yml secrets.yml
ansible-vault encrypt secrets.yml

# Provision
ansible-playbook playbooks/agent.yml -i inventory.yml \
  --ask-become-pass \
  --extra-vars @~/Secrets/ziggy-ansible-secrets.yml

# Update submodule
git submodule update --remote vendor/openclaw-ansible
```
