# ak - API Key Manager (LLM Reference)

GPG-encrypted secret storage with gpg-agent passphrase caching.

## Directory Structure

```
~/tools/api-keys/
├── bin/
│   ├── ak                  # Main CLI (bash)
│   ├── ak-test             # Test all API keys
│   ├── ak-functions.sh     # Shell functions: load_api_keys, aliases
│   ├── ak.ps1              # PowerShell version (uses age, legacy)
│   ├── bw-test             # Bitwarden CLI testing (uses test vault)
│   ├── bw-test-unlock      # Legacy test vault unlock
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
ak export [service]    # Print "export VAR='value'" for eval
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

### Bash/Zsh (~/.bashrc)

```bash
export PATH="$HOME/tools/api-keys/bin:$PATH"
source "$HOME/tools/api-keys/bin/ak-functions.sh"
```

Provides:
- `load_api_keys` / `load-api-keys` - Export all secrets
- `show-keys` → `ak list`
- `get-key` → `ak get`
- `set-key` → `ak set`

### Direnv (.envrc)

```bash
use_ak              # Load all keys
use_ak brave spider # Load specific keys
```

Requires symlink:
```bash
ln -sf ~/tools/api-keys/integrations/direnv.sh ~/.config/direnv/lib/ak.sh
```

### PowerShell ($PROFILE)

```powershell
$env:PATH += ";$env:USERPROFILE\tools\api-keys\bin"
$env:BRAVE_API_KEY = $(ak get brave)
```

Note: ak.ps1 uses age encryption (legacy), not GPG.

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
rsync -av ~/tools/api-keys/secrets/ target:~/tools/api-keys/secrets/
rsync -av ~/tools/api-keys/.gpg-key-id target:~/tools/api-keys/
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
- **Key**: GPG key 0118A3F9 (Jack Chidley), passphrase in Bitwarden
- **Cache**: gpg-agent caches passphrase (configurable TTL)
- **Storage**: secrets/*.gpg files, 600 permissions
- **Exposure**: Once unlocked, any user process can decrypt for cache duration

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
ak-test   # Test all API keys
bw-test   # Test Bitwarden CLI (uses test vault)
```

## Bitwarden CLI

Test vault for automation experiments: jackc@chidley.org on vault.bitwarden.eu
Password: `ak get bitwarden-test`

```bash
# Unlock test vault
export BW_PASSWORD=$(ak get bitwarden-test)
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

# Get password/field
bw get password "item-name" --session "$BW_SESSION"
bw get item "item-name" --session "$BW_SESSION" | jq -r '.fields[] | select(.name=="field") | .value'

# Lock
bw lock
```

Full docs: https://bitwarden.com/help/cli/

## Implementation Notes

- `ak` CLI is ~300 lines of bash
- YAML parsing is regex-based (no deps): `grep "^field:" | sed ...`
- Secrets stored as `echo -n "$value" | gpg --encrypt -r $KEY_ID -o file.gpg`
- Decryption: `gpg --quiet --decrypt file.gpg`
