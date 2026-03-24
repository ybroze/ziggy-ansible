# Contributing & Conventions

## Naming

- **Role names:** `snake_case` (Ansible convention) — e.g., `signal_cli`, `agent_config`
- **Upstream files:** retain original naming (hyphens) to avoid merge conflicts on upstream pulls
- **New files:** use `snake_case` for consistency with roles

## Secrets

Never committed to the repo — not even encrypted. Passed via `--extra-vars` at runtime.
