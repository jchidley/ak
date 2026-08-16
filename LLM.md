# ak - API Key Manager (LLM Reference)

GPG-encrypted secret storage with gpg-agent passphrase caching. On Jack's machines this repository is authoritative only inside the WSL distro nominated by the Windows-side `~/.config/ak/vault.conf`. Windows wrappers name that distro explicitly and do not fall back to another distro, Credential Manager, or Bitwarden.

## Directory Structure

```
~/github/ak/
├── bin/
│   ├── ak                  # Main CLI (bash)
│   ├── ak-test             # Test all API keys
│   ├── ak-functions.sh     # Legacy/convenience shell functions; do not auto-load
│   ├── ak.ps1              # Retained cross-platform code; not an approved local fallback
│   └── review-api-usage    # Monthly security review checklist
├── secrets/*.gpg           # Encrypted secrets
├── services/*.yaml         # Service metadata (URLs, env vars, notes)
├── integrations/
│   └── direnv.sh           # Direnv helper (symlinked to ~/.config/direnv/lib/ak.sh)
├── legacy/                 # Archived Bitwarden docs
└── .gpg-key-id             # Selected GPG key ID
```

## Commands

```bash
ak init                # Select GPG key, create directories
ak list                # List services with secret status
ak get <service>       # Decrypt secret to stdout
ak set <service>       # Store secret (prompts for value)
ak show <service>      # Display service YAML metadata
ak edit <service>      # Edit service YAML (creates template if missing)
ak open <service>      # Open service URL in browser
ak export [service]    # Prefer one explicit service; export:false services are rejected
ak rotate <service>    # Show metadata + open URL for rotation workflow
```

## Service YAML Format

```yaml
name: "Human-readable name"
env_var: SERVICE_API_KEY
url: "https://provider.com/api-keys"
notes: |
  Multi-line notes for rotation instructions,
  account details, etc.
last_rotated: 2026-01-16T14:16:49+01:00
export: true           # Set false for credentials that must never enter an environment
```

## Configured Services

| Service | Env Var | API Base | Auth Header |
|---------|---------|----------|-------------|
| anthropic | ANTHROPIC_API_KEY | https://api.anthropic.com/v1 | `x-api-key: $KEY` + `anthropic-version: 2023-06-01` |
| brave | BRAVE_API_KEY | https://api.search.brave.com/res/v1 | `X-Subscription-Token: $KEY` |
| deepseek | DEEPSEEK_API_KEY | https://api.deepseek.com/v1 | `Authorization: Bearer $KEY` |
| github | GITHUB_TOKEN | https://api.github.com | `Authorization: Bearer $KEY` |
| google-ai | GOOGLE_AI_API_KEY | https://generativelanguage.googleapis.com/v1 | `?key=$KEY` (query param) |
| google-genai | GOOGLE_GENAI_API_KEY | https://generativelanguage.googleapis.com/v1 | `?key=$KEY` (query param) |
| groq | GROQ_API_KEY | https://api.groq.com/openai/v1 | `Authorization: Bearer $KEY` |
| moonshot | MOONSHOT_API_KEY | https://api.moonshot.ai/v1 | `Authorization: Bearer $KEY` |
| openai | OPENAI_API_KEY | https://api.openai.com/v1 | `Authorization: Bearer $KEY` |
| spider | SPIDER_API_KEY | https://api.spider.cloud/v1 | `Authorization: Bearer $KEY` |

## Shell Integration

Link only the administrative CLI inside the nominated WSL distro:

```bash
ln -sfn "$HOME/github/ak/bin/ak" "$HOME/.local/bin/ak"
```

Do not bulk-load keys from shell profiles, `.envrc`, or direnv. Retrieve one approved low-risk service explicitly for the current task. Windows callers must use the `windows-env` `ak-get` wrapper so the configured distro is enforced. The retained PowerShell/Credential Manager and Bitwarden implementations are not approved fallbacks on this machine.

## GPG Configuration

### Key Selection

```bash
ak init  # Lists keys, prompts for selection, saves to .gpg-key-id
```

### Agent Cache (~/.gnupg/gpg-agent.conf)

```
default-cache-ttl 72000
max-cache-ttl 72000
pinentry-program /usr/bin/pinentry-gnome3
```

Reload: `gpgconf --kill gpg-agent`

### Lock Immediately

```bash
gpgconf --kill gpg-agent
```

## Cross-Machine Sync

### Export GPG Key

```bash
gpg --export-secret-keys --armor <KEY_ID> > /tmp/ak-gpg-key.asc
```

### Import on Target

```bash
gpg --import /path/to/ak-gpg-key.asc
gpg --edit-key <KEY_ID>  # trust → 5 (ultimate) → quit
```

### Sync Secrets

```bash
rsync -av ~/github/ak/secrets/ target:~/github/ak/secrets/
rsync -av ~/github/ak/.gpg-key-id target:~/github/ak/
```

## Adding New Services

```bash
ak edit myservice  # Creates template YAML
ak set myservice   # Store the secret
```

## Key Rotation Workflow

```bash
ak rotate <service>  # Shows notes, opens dashboard URL
# 1. Create new key in provider dashboard
# 2. Copy new key
ak set <service>     # Paste new key
```

## Security Model

- **Encryption**: GPG (RSA/AES-256)
- **Key**: the GPG recipient selected by `ak init`; do not document its passphrase
- **Cache**: gpg-agent caches passphrase (configurable TTL)
- **Storage**: `secrets/*.gpg` files with mode 600, only in the nominated WSL distro
- **Routing**: Windows callers explicitly name the configured distro and fail closed
- **Export control**: `export: false` prevents both bulk and explicit shell export
- **Exposure**: Once unlocked, any user process in the nominated distro can decrypt for the cache duration

## Risk Tiers (as of 2026-01-16)

**CRITICAL** (code/repo access): github (expires 2026-01-23)
**LIMITED** (capped by credit): anthropic ($0), openai ($37.86), deepseek ($49.99), moonshot ($22.75), spider ($39.01), groq ($20 limit)
**FREE**: brave (2000 queries/month), google-ai, google-genai

## Monthly Review

Run `review-api-usage` to see checklist of dashboards to audit.

## Troubleshooting

**"No GPG key configured"**
```bash
ak init
```

**Prompts every time**
```bash
gpgconf --launch gpg-agent
grep cache-ttl ~/.gnupg/gpg-agent.conf
```

**Direnv not loading**
```bash
direnv allow
ls -la ~/.config/direnv/lib/ak.sh
```

**"gpg: decryption failed: No secret key"**
```bash
gpg --list-secret-keys  # Verify key exists
cat .gpg-key-id         # Check stored key ID matches
```

## Legacy

The `legacy/` directory contains archived Bitwarden integration docs from before the GPG migration. Not actively used.

## Testing

```bash
ak-test   # Provider API smoke tests; may consume quota
```

Historical Bitwarden automation experiments are retained under `legacy/bitwarden/`; they are not active workspace credential commands.

## Implementation Notes

- `ak` CLI is ~300 lines of bash
- YAML parsing is regex-based (no deps): `grep "^field:" | sed ...`
- Secrets stored as `echo -n "$value" | gpg --encrypt -r $KEY_ID -o file.gpg`
- Decryption: `gpg --quiet --decrypt file.gpg`
