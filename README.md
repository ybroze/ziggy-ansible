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

## Signal Account Setup

Signal is the primary messaging channel for this deployment. It is preferred over Telegram for all sensitive communication because **Signal provides end-to-end encryption by default** — messages are encrypted on the sender's device and only decrypted on the recipient's device. Not even Signal's servers can read them. Telegram, by contrast, only offers E2EE in optional "Secret Chats" — standard messages (including all bot messages) are readable by Telegram's servers.

### Why signal-cli?

[signal-cli](https://github.com/AsamK/signal-cli) is a command-line Signal client that OpenClaw uses as a messaging provider. It registers as a standalone Signal device (not linked to a phone), using a dedicated phone number.

### Prerequisites

- A **dedicated phone number** for the agent — not your personal number
- A way to **receive SMS** at that number for verification (e.g., Twilio)
- **Java 21+** and **signal-cli** installed (handled by the `signal_cli` Ansible role)

### Registration (Twilio-based)

The agent's Signal account is registered using a Twilio number. This is a manual, one-time process.

#### 1. Acquire a Twilio number

If not already done, purchase a phone number in the [Twilio Console](https://console.twilio.com/). Note the regulatory requirements:

- **Toll-free numbers** require toll-free verification before sending SMS
- **Local numbers** require A2P 10DLC campaign registration (10-15 day review)

Until verification/registration is complete, Twilio may block outbound SMS but **inbound SMS (for verification codes) will work**.

#### 2. Register with Signal

On the VM, as the `openclaw` user:

```bash
# Start registration — Signal sends a verification code via SMS
signal-cli -u +1YOURTWILINUMBER register

# The verification code arrives as an inbound SMS to your Twilio number.
# Retrieve it from the Twilio Console (Messaging > Logs) or via API:
source ~/.config/ziggy/twilio.env
curl -s -u "$TWILIO_SID:$TWILIO_AUTH_TOKEN" \
  "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_SID/Messages.json?To=$TWILIO_NUMBER&Direction=inbound&PageSize=1" \
  | python3 -c "import sys,json; msgs=json.load(sys.stdin)['messages']; print(msgs[0]['body'] if msgs else 'no messages')"

# Complete registration with the verification code
signal-cli -u +1YOURTWILINUMBER verify CODE
```

#### 3. Set profile

```bash
signal-cli -u +1YOURTWILINUMBER updateProfile \
  --given-name "Ziggy" \
  --about "🧩" \
  --avatar /path/to/avatar.jpg
```

#### 4. Trust and verify

Send a test message to confirm the registration works:

```bash
signal-cli -u +1YOURTWILINUMBER send -m "Hello from signal-cli" +1RECIPIENTNUMBER
```

### Account Data — Backup and Restore

Signal registration is **stateful and cryptographic**. The account identity is not a password or token — it's a set of encryption keys stored on disk. Losing them means re-registering, which:

- Invalidates all existing Signal sessions
- Triggers "safety number changed" warnings for all contacts
- Requires a new SMS verification

**Critical path:** `~/.local/share/signal-cli/`

This directory contains:
- Account identity keys (your Signal "identity")
- Pre-keys and session keys (active conversations)
- Group membership and keys
- Profile data and avatar

#### Backup

```bash
# Create an encrypted backup
tar czf - -C /home/openclaw/.local/share signal-cli \
  | gpg --symmetric --cipher-algo AES256 -o signal-cli-backup.tar.gz.gpg
```

Store the backup securely (e.g., `~/Secrets/` on your laptop, or an encrypted cloud bucket). **Do this after initial registration and periodically thereafter.**

#### Restore

```bash
# Restore from backup (on a fresh or reprovisioned VM)
gpg --decrypt signal-cli-backup.tar.gz.gpg \
  | tar xzf - -C /home/openclaw/.local/share/
chown -R openclaw:openclaw /home/openclaw/.local/share/signal-cli
```

### Important Constraints

- **Single-device only:** signal-cli can only be active on one machine per phone number at a time. Running it on two machines simultaneously causes key conflicts and message loss.
- **Re-registration is disruptive:** Only do it as a last resort. Back up the data directory instead.
- **Twilio number portability:** If you ever change Twilio numbers, you must re-register with Signal under the new number. All contacts will see a new identity.

## GitHub Account Setup

The agent has its own GitHub identity for version control, issue filing, and repository management.

### Prerequisites

- A **GitHub account** for the agent (e.g., created via "Sign in with Google" using the agent's Google Workspace email)
- An **SSH key pair** for git operations
- A **Personal Access Token (classic)** for API access

### Registration

1. Create a GitHub account at https://github.com/signup (or sign in with Google using the agent's email)
2. Set profile name and bio via API or browser

### SSH Key

Generate on the VM as the `openclaw` user:

```bash
ssh-keygen -t ed25519 -C "agent@yourdomain.com" -f ~/.ssh/id_ed25519 -N ""
```

Add the public key to the GitHub account: **Settings → SSH and GPG keys → New SSH key**

The private key is deployed by Ansible via the `agent_ssh_private_key` and `agent_ssh_public_key` secret variables.

### Personal Access Token (Classic)

Create at https://github.com/settings/tokens → **Generate new token (classic)**

Recommended scopes:
- `repo` — full repository access
- `user` — profile read/write (required for avatar, bio updates)
- `admin:org` — if the agent needs to manage organization settings
- `admin:public_key` — manage SSH keys via API
- `admin:repo_hook` — webhook management

The token is deployed by Ansible via the `agent_github_pat` secret variable to `~/.config/ziggy/github-token.txt`.

### Git Configuration

Ansible configures the global git identity:

```
git config --global user.name "AgentName"
git config --global user.email "agent@yourdomain.com"
```

### Secrets

All GitHub credentials are passed via `--extra-vars` at runtime — **never stored in any repository**.

| Variable | Description | Deployed to |
|----------|-------------|-------------|
| `agent_github_pat` | Personal Access Token (classic) | `~/.config/ziggy/github-token.txt` |
| `agent_ssh_private_key` | SSH private key | `~/.ssh/id_ed25519` |
| `agent_ssh_public_key` | SSH public key | `~/.ssh/id_ed25519.pub` |

## Pulling Upstream Updates

```bash
git remote add upstream https://github.com/openclaw/openclaw-ansible.git
git fetch upstream
git merge upstream/main
```
