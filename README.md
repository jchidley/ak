# ak - API Key Manager

GPG-encrypted secrets with gpg-agent caching. On Jack's machines the authoritative store and all decryption live only in the WSL distro nominated by the Windows-side `~/.config/ak/vault.conf`; Windows callers use fail-closed wrappers that name that distro explicitly.

## Quick Start

Start with read-only service inventory; this does not decrypt values:

```bash
ak list
```

For an explicitly required credential, use the consuming skill's managed launcher, which captures the selected service internally. Do not run `ak get` or `ak export` alone in an agent tool call. Initialisation, storage, rotation, installation/link replacement and GPG configuration require approval for their concrete effects; they are not automatic fixes for a missing credential.

## Commands

| Command | Description |
|---------|-------------|
| `ak init` | Select GPG key for encryption |
| `ak list` | List services (✓ = has secret) |
| `ak get <svc>` | Decrypt and print secret |
| `ak env-var <svc>` | Print the variable name for an exportable service |
| `ak set <svc>` | Store/update secret |
| `ak show <svc>` | Show service metadata |
| `ak open <svc>` | Open management URL |
| `ak export [svc]` | Print shell exports; prefer one explicit service, and never auto-load the vault |
| `ak rotate <svc>` | Show rotation info + open URL |

## Installation and shell integration

The source checkout is `~/git/ak`; install command links in the standard user path:

```bash
ln -sfn "$HOME/git/ak/bin/ak" "$HOME/.local/bin/ak"
ln -sfn "$HOME/git/ak/bin/ak-ssh-askpass" "$HOME/.local/bin/ak-ssh-askpass"
```

Source code directories do not need to be added to `PATH`. A reviewed `.envrc` may call `use_ak` with an explicit service allowlist; that same managed allowlist is imported by Windows PowerShell. Do not use no-argument/bulk loading, and do not add non-exportable credentials to an environment profile.

## Security

- Passphrase caching depends on the installed GPG agent configuration; the 20-hour example is not a verified universal setting
- `gpgconf --kill gpg-agent` clears the agent cache and affects other consumers; do not run it as routine validation
- Stored secret files are encrypted; decryption/export, logs, process arguments and consumers can still expose plaintext
- Services marked `export: false` cannot be exported, even when named explicitly
- Windows Credential Manager and Bitwarden are not fallbacks for the nominated WSL store

## Documentation

See `LLM.md` for administrative effects and implementation limits. Legacy shell bulk-load helpers, alternate-platform code and broad `ak-test` provider smoke are retained, not approved fallback/startup or success-gate recipes. The reviewed direnv allowlist can skip unavailable services; consumers must check their required value internally without logging it.
