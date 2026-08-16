# GPG-based secret management for direnv
# Symlink to: ~/.config/direnv/lib/ak.sh
#   ln -sf ~/github/ak/integrations/direnv.sh ~/.config/direnv/lib/ak.sh

AK_INTEGRATION_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
AK_DIR="${AK_DIR:-$(dirname -- "$(dirname -- "$AK_INTEGRATION_PATH")")}"
AK_BIN="${AK_BIN:-$(command -v ak 2>/dev/null || printf '%s/bin/ak' "$AK_DIR")}"

# Set AK_DIRENV_VERBOSE=1 to log each loaded variable via direnv log_status
ak_log_loaded() {
    if [[ "${AK_DIRENV_VERBOSE:-0}" == "1" ]]; then
        log_status "Loaded $1"
    fi
    return 0
}

# Get a secret using ak (GPG-based)
# Usage: ak_get <name>
ak_get() {
    local name="$1"
    "$AK_BIN" get "$name" 2>/dev/null
}

# Helper for explicit .envrc allowlists.
# Usage: use_ak github brave ...
# No-argument loading is deliberately rejected: the .envrc is the reviewed
# export profile, and service metadata can mark credentials export: false.
use_ak() {
    if [[ ! -f "${AK_DIR}/.gpg-key-id" ]]; then
        log_error "ak not initialized. Run: ak init"
        return 1
    fi
    if [[ $# -eq 0 ]]; then
        log_error "use_ak requires an explicit service allowlist"
        return 1
    fi

    local name env_var value
    for name in "$@"; do
        if ! env_var=$("$AK_BIN" env-var "$name" 2>/dev/null); then
            log_error "ak service is missing, invalid, or non-exportable: $name"
            return 1
        fi
        if ! value=$(ak_get "$name"); then
            log_status "ak secret unavailable; skipped: $name"
            continue
        fi
        export "$env_var=$value"
        ak_log_loaded "$env_var"
    done
}
