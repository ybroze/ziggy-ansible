# OpenClaw Agent — Ansible Deployment

Deploy a fully configured [OpenClaw](https://github.com/openclaw/openclaw) AI agent on a Linux VPS, with Signal messaging, web search, browser automation, and persistent workspace — all provisioned from your laptop via Ansible.

Forked from [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) with additional roles for a production-ready personal agent.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Your Laptop                                         │
│  ├── Ansible (runs playbooks)                        │
│  ├── ~/Secrets/ (credentials, never committed)       │
│  └── Signal app (talk to your agent)                 │
└──────────────────────┬──────────────────────────────┘
                       │ SSH
┌──────────────────────▼──────────────────────────────┐
│  VPS (Debian/Ubuntu)                                 │
│  ├── OpenClaw gateway (systemd, loopback-only)       │
│  ├── signal-cli (E2EE messaging)                     │
│  ├── Google Chrome (headless browser automation)     │
│  ├── Caddy (HTTPS reverse proxy / static site)       │
│  ├── Docker (agent sandbox isolation)                │
│  ├── UFW + fail2ban (firewall + intrusion prevention)│
│  └── Workspace (git-synced, your agent's memory)     │
└─────────────────────────────────────────────────────┘
```

The agent communicates via **Signal** (end-to-end encrypted) and optionally **Telegram**. It uses the **Anthropic API** for reasoning, **Brave Search** for web access, and a **headless browser** for sites that require interaction.

## What This Provisions

**Base (from upstream openclaw-ansible):**
- Debian/Ubuntu system packages
- Node.js 22 + pnpm
- OpenClaw (release mode, systemd service)
- Docker CE (agent sandbox isolation)
- UFW firewall + fail2ban

**Extension roles:**
- `chrome` — Google Chrome Stable (headless browser for OpenClaw)
- `caddy` — Caddy web server (automatic HTTPS via Let's Encrypt)
- `signal_cli` — signal-cli + Java runtime (Signal messaging provider)
- `agent_config` — credentials deployment (GitHub, Google OAuth, Twilio, SSH keys)
- `openclaw_config` — OpenClaw configuration + workspace clone from git

## Cost Estimate

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| VPS | $5–20 | Depends on provider/size. 2 vCPU / 2 GB RAM is sufficient. |
| Anthropic API | $20–100+ | Depends on usage. Claude Sonnet is cheaper; Opus for complex tasks. |
| Domain | $10–15/year | Optional but recommended for Caddy HTTPS. |
| Twilio | $1–2 + usage | Phone number ($1/mo toll-free or $1/mo local) + SMS at ~$0.0079/msg. |
| Brave Search API | Free tier | 2,000 queries/month free; paid plans available. |
| **Total** | **~$30–140/mo** | Varies with API usage. |

## Prerequisites

Before running Ansible, you need the following set up:

### 1. A Linux VPS

Any cloud provider works (GCP, DigitalOcean, Hetzner, Linode, AWS Lightsail, etc.).

**Requirements:**
- **OS:** Debian 11+ or Ubuntu 20.04+
- **Resources:** 2 vCPU, 2 GB RAM minimum (4 GB recommended)
- **Disk:** 20 GB+
- **SSH access** from your laptop with sudo privileges

**After creating the VM:**
```bash
# Verify SSH access from your laptop
ssh youruser@YOUR_SERVER_IP

# Ensure sudo works
sudo whoami  # should print: root
```

### 2. A Domain Name (Optional but Recommended)

If you want HTTPS for a web presence (privacy policy, terms of service, or future web UI):

1. Register a domain (or use a subdomain of one you own)
2. Create a DNS A record pointing to your VPS IP:
   ```
   agent.yourdomain.com → YOUR_SERVER_IP
   ```
3. Wait for DNS propagation (usually minutes, up to 48 hours)

If you skip this, remove the `caddy` role from `playbooks/ziggy.yml`.

### 3. Ansible on Your Laptop

```bash
# macOS
brew install ansible

# Ubuntu/Debian
sudo apt install ansible

# Verify
ansible --version  # 2.14+ required
```

### 4. Anthropic API Key

1. Sign up at https://console.anthropic.com/
2. Add billing (pay-as-you-go)
3. Create an API key: **Settings → API Keys → Create Key**
4. Save the key — it starts with `sk-ant-`

### 5. Brave Search API Key (Optional)

Gives the agent web search capability.

1. Sign up at https://brave.com/search/api/
2. Free tier: 2,000 queries/month
3. Create an API key from the dashboard

### 6. Twilio Account (for Signal)

Signal registration requires a phone number that can receive SMS.

1. Sign up at https://www.twilio.com/
2. Add billing (pay-as-you-go; ~$1/month for a number)
3. **Buy a phone number:**
   - Toll-free numbers are simplest — fewer regulatory hoops for receiving SMS
   - Local numbers require A2P 10DLC campaign registration (10–15 day review)
4. Note your **Account SID**, **Auth Token**, and **Phone Number**

> **Regulatory note:** Twilio may restrict *outbound* SMS until toll-free verification or 10DLC registration completes. *Inbound* SMS (needed for Signal verification) works immediately.

### 7. Google Workspace Account (Optional)

If you want your agent to have its own email and calendar:

1. Add a user in your Google Workspace admin console (e.g., `agent@yourdomain.com`)
2. Create a GCP project (or use an existing one)
3. Enable the **Gmail API** and **Calendar API**
4. Create an **OAuth 2.0 Client ID** (Desktop app type)
5. Download the credentials JSON
6. Run the OAuth consent flow to get a refresh token:

```bash
# Generate auth URL (replace with your client_id)
python3 -c "
import urllib.parse
params = urllib.parse.urlencode({
    'client_id': 'YOUR_CLIENT_ID',
    'redirect_uri': 'http://localhost',
    'response_type': 'code',
    'scope': 'https://mail.google.com/ https://www.googleapis.com/auth/calendar',
    'access_type': 'offline',
    'prompt': 'consent',
})
print(f'https://accounts.google.com/o/oauth2/v2/auth?{params}')
"
```

Open the URL, sign in as the agent, grant permissions. The browser redirects to `http://localhost?code=XXXXX` (page won't load — that's fine). Copy the `code` value and exchange it:

```bash
curl -s -X POST https://oauth2.googleapis.com/token \
  -d "code=AUTHORIZATION_CODE" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "redirect_uri=http://localhost" \
  -d "grant_type=authorization_code" | python3 -m json.tool
```

Save the resulting `refresh_token`.

### 8. Telegram Bot (Optional)

If you want Telegram as an additional messaging channel:

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. `/newbot` → choose a name and username
3. Save the bot token
4. Message your bot to start a conversation, then get your chat ID:
   ```bash
   curl -s "https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates" | python3 -m json.tool
   ```
   Look for `message.from.id` — this is your Telegram user ID for the allowlist.

## Installation

### 1. Clone This Repo

```bash
git clone git@github.com:ybroze/ziggy-ansible.git
cd ziggy-ansible
```

### 2. Configure Inventory

Edit `inventory.yml` with your VPS details:

```yaml
all:
  children:
    openclaw_servers:
      hosts:
        my-agent-vm:
          ansible_host: YOUR_SERVER_IP
          ansible_user: YOUR_SSH_USER
          ansible_become: true
  vars:
    openclaw_user: openclaw
    openclaw_home: /home/openclaw
    openclaw_install_mode: release
    tailscale_enabled: false
    caddy_domain: agent.yourdomain.com
    caddy_webroot: /var/www/agent.yourdomain.com
    signal_cli_version: "0.13.24"
    java_package: openjdk-21-jre-headless
    workspace_git_remote: "git@github.com:youruser/your-workspace-repo.git"
    signal_allow_from:
      - "+1YOURNUMBER"
```

### 3. Create Secrets File

```bash
cp secrets.example.yml ~/Secrets/agent-secrets.yml
# Edit with your actual values
```

See `secrets.example.yml` for all required and optional variables.

### 4. Run the Playbook

```bash
ansible-playbook playbooks/ziggy.yml \
  --ask-become-pass \
  --extra-vars @~/Secrets/agent-secrets.yml
```

This takes 5–15 minutes on a fresh VPS.

### 5. Post-Install: OpenClaw Onboarding

SSH into the VPS and switch to the openclaw user:

```bash
ssh youruser@YOUR_SERVER_IP
sudo -i -u openclaw
```

Run the OpenClaw onboarding wizard:

```bash
openclaw onboard --install-daemon
```

This will:
- Create the initial configuration (if not already deployed by Ansible)
- Install and start the systemd daemon
- Verify the gateway is running

### 6. Post-Install: Signal Registration

See [Signal Account Setup](#signal-account-setup) below — this is a manual, one-time process.

### 7. Verify

```bash
# Check the service
sudo systemctl status openclaw

# View logs
sudo journalctl -u openclaw -f

# Send a message via Signal to your agent's number
# You should get a response!
```

## Signal Account Setup

Signal is the recommended primary messaging channel because **Signal provides end-to-end encryption by default** — messages are encrypted on the sender's device and only decrypted on the recipient's device. Not even Signal's servers can read them. Telegram, by contrast, only offers E2EE in optional "Secret Chats" — standard messages (including all bot messages) are readable by Telegram's servers.

### Why signal-cli?

[signal-cli](https://github.com/AsamK/signal-cli) is a command-line Signal client that OpenClaw uses as a messaging provider. It registers as a standalone Signal device (not linked to a phone), using a dedicated phone number.

### Registration (Twilio-based)

On the VM, as the `openclaw` user:

```bash
# Start registration — Signal sends a verification code via SMS
signal-cli -u +1YOURTWILINUMBER register

# Retrieve the verification code from Twilio
source ~/.config/ziggy/twilio.env
curl -s -u "$TWILIO_SID:$TWILIO_AUTH_TOKEN" \
  "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_SID/Messages.json?To=$TWILIO_NUMBER&Direction=inbound&PageSize=1" \
  | python3 -c "import sys,json; msgs=json.load(sys.stdin)['messages']; print(msgs[0]['body'] if msgs else 'no messages')"

# Complete registration with the verification code
signal-cli -u +1YOURTWILINUMBER verify CODE

# Set profile
signal-cli -u +1YOURTWILINUMBER updateProfile \
  --given-name "YourAgentName" \
  --about "🤖" \
  --avatar /path/to/avatar.jpg

# Test — send yourself a message
signal-cli -u +1YOURTWILINUMBER send -m "Hello from my agent!" +1YOURNUMBER
```

### Account Data — Backup and Restore

Signal registration is **stateful and cryptographic**. The account identity is a set of encryption keys stored on disk. Losing them means re-registering, which invalidates all existing sessions and triggers "safety number changed" warnings for all contacts.

**Critical path:** `~/.local/share/signal-cli/`

**Recommended:** Enable daily disk snapshots on your VPS (available on most cloud providers). This covers signal-cli data along with everything else.

#### Manual Backup

```bash
tar czf - -C /home/openclaw/.local/share signal-cli \
  | gpg --symmetric --cipher-algo AES256 -o signal-cli-backup.tar.gz.gpg
```

#### Restore

```bash
gpg --decrypt signal-cli-backup.tar.gz.gpg \
  | tar xzf - -C /home/openclaw/.local/share/
chown -R openclaw:openclaw /home/openclaw/.local/share/signal-cli
```

### Important Constraints

- **Single-device only:** signal-cli can only be active on one machine per phone number. Running on two machines simultaneously causes key conflicts.
- **Re-registration is disruptive:** Back up the data directory instead.
- **Number changes:** If you change phone numbers, you must re-register. All contacts see a new identity.

## GitHub Account Setup

Giving your agent a GitHub identity enables version control, issue filing, and repository management.

### Setup

1. **Create a GitHub account** at https://github.com/signup (or sign in with Google using the agent's email)
2. **Generate an SSH key** on the VM:
   ```bash
   ssh-keygen -t ed25519 -C "agent@yourdomain.com" -f ~/.ssh/id_ed25519 -N ""
   ```
3. **Add the public key** to the GitHub account: Settings → SSH and GPG keys → New SSH key
4. **Create a Personal Access Token (classic)** at https://github.com/settings/tokens

**Recommended PAT scopes:**
- `repo` — full repository access
- `user` — profile read/write
- `admin:public_key` — SSH key management via API
- `admin:repo_hook` — webhook management (if needed)

### Secrets

| Variable | Description | Deployed to |
|----------|-------------|-------------|
| `agent_github_pat` | Personal Access Token (classic) | `~/.config/ziggy/github-token.txt` |
| `agent_ssh_private_key` | SSH private key | `~/.ssh/id_ed25519` |
| `agent_ssh_public_key` | SSH public key | `~/.ssh/id_ed25519.pub` |

## Secrets Management

**No secrets are stored in this repository — not even encrypted.**

All secrets are passed at runtime via `--extra-vars @<path>`. Keep your secrets file on your local machine (e.g., `~/Secrets/`), never in version control.

See `secrets.example.yml` for all variable names and structure.

Future option: integrate with 1Password CLI or similar for secret injection.

## Customization

### Disabling Optional Roles

Edit `playbooks/ziggy.yml` and remove roles you don't need:

- No web server? Remove `caddy`
- No browser automation? Remove `chrome`
- No Telegram? Remove the telegram section from `openclaw.json.j2`
- No GitHub identity? Remove the GitHub tasks from `agent_config`

### Adding Channels

OpenClaw supports multiple messaging channels. To add one, update the `channels` section in `roles/openclaw_config/templates/openclaw.json.j2` and add the relevant credentials to your secrets file.

Supported channels: Signal, Telegram, WhatsApp, Discord, Slack, IRC, Google Chat, iMessage.

### Workspace

The agent's workspace (`~/.openclaw/workspace/`) is its persistent memory and configuration. It's cloned from a private git repo you control. Key files:

- `SOUL.md` — personality, tone, behavioral rules
- `AGENTS.md` — operational instructions
- `USER.md` — information about you
- `MEMORY.md` — long-term memory (maintained by the agent)
- `HEARTBEAT.md` — periodic tasks the agent runs automatically

Create a private repo, populate these files, and set `workspace_git_remote` in your inventory.

## Pulling Upstream Updates

```bash
git remote add upstream https://github.com/openclaw/openclaw-ansible.git
git fetch upstream
git merge upstream/main
```

## Troubleshooting

### Agent doesn't respond to messages

```bash
# Check if the service is running
sudo systemctl status openclaw

# Check logs for errors
sudo journalctl -u openclaw -n 100 --no-pager

# Verify signal-cli is registered
sudo -i -u openclaw
signal-cli -u +1YOURNUMBER receive
```

### Gateway won't start

```bash
# Test manual start
sudo -i -u openclaw
openclaw gateway

# Run diagnostics
openclaw doctor
```

### Signal registration fails

- Verify the Twilio number can receive SMS (check Twilio Console → Messaging → Logs)
- Ensure you're using the correct verification code (codes expire quickly)
- If rate-limited by Signal, wait and retry after a few hours

### Ansible fails on a role

Ansible is idempotent — safe to re-run after fixing the issue:

```bash
ansible-playbook playbooks/ziggy.yml \
  --ask-become-pass \
  --extra-vars @~/Secrets/agent-secrets.yml
```

## License

Forked from [openclaw-ansible](https://github.com/openclaw/openclaw-ansible). See [LICENSE](LICENSE) for details.
