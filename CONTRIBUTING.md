# Contributing & Conventions

## Naming

- **Role names:** `snake_case` (Ansible convention) — e.g., `signal_cli`, `agent_config`
- **Upstream files:** retain original naming (hyphens) to avoid merge conflicts on upstream pulls
- **New files:** use `snake_case` for consistency with roles

## Secrets

Never committed to the repo — not even encrypted. Passed via `--extra-vars` at runtime.

## YAML Editing Principles

### 1. Validate after every edit

Before committing any YAML change, validate the file:

```bash
python3 -c "import yaml; yaml.safe_load(open('path/to/file.yml'))"
```

Or use `yamllint` if available. Catches indentation and syntax errors before they reach Ansible.

### 2. Never fold URLs or paths

URLs, file paths, regex patterns, and any string where whitespace is meaningful must stay on a **single line**. YAML folding (`>-`, `>`) joins lines with a space, which silently breaks these values.

```yaml
# WRONG — >- inserts a space in the URL
url: >-
  https://example.com/path/
  to/file.tar.gz
# Produces: "https://example.com/path/ to/file.tar.gz"

# RIGHT — single line, even if it exceeds 80 chars
url: "https://example.com/path/to/file.tar.gz"
```

URLs are an explicit exception to the 80-character line length guideline.

### 3. Never leave empty config keys

Omit optional keys entirely rather than leaving them blank. Blank values get interpreted unpredictably by different tools.

```ini
# WRONG — Ansible interprets empty as current directory
vault_password_file =

# RIGHT — omit the key
# (no vault_password_file line)
```

### 4. Don't use sed on YAML

YAML is whitespace-sensitive. Blind `sed` replacements don't understand structure and can silently break indentation. Use targeted edits or a YAML-aware tool. If `sed` is the only option, **validate the file afterward** (see principle 1).

### 5. Test against a real target

Ansible `--check` mode has known limitations — it can't simulate multi-step dependency chains (e.g., install a package then start its service). A real run against the actual target is the canonical test. Use `--check --diff` for previewing safe changes (file content, config), but expect false failures on service tasks that depend on prior installation steps.

## Line Length

- **Target:** 80 characters max for YAML files
- **Exceptions:** URLs, file paths, long Jinja2 expressions, JSON templates
- **Indentation:** 2 spaces (Ansible ecosystem convention)
- **Upstream files:** leave line lengths as-is to avoid merge conflicts
