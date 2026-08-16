# ak - API Key Manager

GPG-encrypted secrets with gpg-agent caching. On Jack's machines the authoritative store and all decryption live only in the WSL distro nominated by the Windows-side `~/.config/ak/vault.conf`; Windows callers use fail-closed wrappers that name that distro explicitly.

## Quick Start

```bash
# Initialize (select GPG key)
ak init

# Store/retrieve secrets
ak set brave
ak get brave

# Retrieve only the service required by the current task
export BRAVE_API_KEY=$(ak get brave)
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
| `ak export [svc]` | Print shell exports; prefer one explicit service, and never auto-load the vault |
| `ak rotate <svc>` | Show rotation info + open URL |

## Installation and shell integration

The source checkout is `~/github/ak`; install command links in the standard user path:

```bash
ln -sfn "$HOME/github/ak/bin/ak" "$HOME/.local/bin/ak"
ln -sfn "$HOME/github/ak/bin/ak-ssh-askpass" "$HOME/.local/bin/ak-ssh-askpass"
```

Source code directories do not need to be added to `PATH`. Do not source bulk-loading helpers from shell profiles or `.envrc`; retrieve one approved low-risk service explicitly when required.

## Security

- Passphrase cached 20 hours after first unlock
- Lock immediately: `gpgconf --kill gpg-agent`
- No plaintext on disk
- Services marked `export: false` cannot be exported, even when named explicitly
- Windows Credential Manager and Bitwarden are not fallbacks for the nominated WSL store

## Documentation

See `LLM.md` for complete technical reference.
