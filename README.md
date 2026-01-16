# ak - API Key Manager

GPG-encrypted secrets with gpg-agent caching. Cross-platform (Linux/Windows).

## Quick Start

```bash
# Initialize (select GPG key)
ak init

# Store/retrieve secrets
ak set brave
ak get brave

# Load all into environment
eval "$(ak export)"
```

## Commands

| Command | Description |
|---------|-------------|
| `ak init` | Select GPG key for encryption |
| `ak list` | List services (✓ = has secret) |
| `ak get <svc>` | Decrypt and print secret |
| `ak set <svc>` | Store/update secret |
| `ak show <svc>` | Show service metadata |
| `ak open <svc>` | Open management URL |
| `ak export` | Print export commands |
| `ak rotate <svc>` | Show rotation info + open URL |

## Shell Integration

Already in `~/.bashrc`:
```bash
export PATH="$HOME/tools/api-keys/bin:$PATH"
source "$HOME/tools/api-keys/bin/ak-functions.sh"
```

**Direnv** (in `.envrc`):
```bash
use_ak              # all keys
use_ak brave spider # specific keys
```

## Security

- Passphrase cached 20 hours after first unlock
- Lock immediately: `gpgconf --kill gpg-agent`
- No plaintext on disk

## Documentation

See `LLM.md` for complete technical reference.
