# GPG-based secret management for direnv
# Symlink to: ~/.config/direnv/lib/
#   ln -sf ~/tools/api-keys/integrations/direnv.sh ~/.config/direnv/lib/ak.sh

AK_DIR="${HOME}/tools/api-keys"
AK_BIN="${AK_DIR}/bin/ak"

# Set AK_DIRENV_VERBOSE=1 to log each loaded variable via direnv log_status
ak_log_loaded() {
    [[ "${AK_DIRENV_VERBOSE:-0}" == "1" ]] && log_status "Loaded $1"
}

# Get a secret using ak (GPG-based)
# Usage: ak_get <name>
ak_get() {
    local name="$1"
    "$AK_BIN" get "$name" 2>/dev/null
}

# Load all API keys from GPG-encrypted storage
load_api_keys() {
    local -A mappings=(
        ["anthropic"]="CLAUDE_CODE_OAUTH_TOKEN"
        ["brave"]="BRAVE_API_KEY"
        ["deepseek"]="DEEPSEEK_API_KEY"
        ["github"]="GITHUB_TOKEN"
        ["google-ai"]="GOOGLE_AI_API_KEY"
        ["google-genai"]="GOOGLE_GENAI_API_KEY"
        ["groq"]="GROQ_API_KEY"
        ["moonshot"]="MOONSHOT_API_KEY"
        ["octopus"]="OCTOPUS_API_KEY"
        ["openai"]="OPENAI_API_KEY"
        ["openrouter"]="OPENROUTER_API_KEY"
        ["deepinfra"]="DEEPINFRA_API_KEY"
        ["spider"]="SPIDER_API_KEY"
    )

    for secret_name in "${!mappings[@]}"; do
        local env_var="${mappings[$secret_name]}"
        local value

        if value=$(ak_get "$secret_name"); then
            export "$env_var=$value"
            ak_log_loaded "$env_var"
        fi
    done
}

# Helper for .envrc files
# Usage in .envrc: use_ak [key1 key2 ...] or use_ak (loads all)
use_ak() {
    if [[ ! -f "${AK_DIR}/.gpg-key-id" ]]; then
        log_error "ak not initialized. Run: ak init"
        return 1
    fi
    
    if [[ $# -eq 0 ]]; then
        # Load all keys
        load_api_keys
    else
        # Load specific keys
        for name in "$@"; do
            local value
            if value=$(ak_get "$name"); then
                # Get env var name from service yaml or default
                local env_var
                env_var=$(grep "^env_var:" "${AK_DIR}/services/${name}.yaml" 2>/dev/null | sed 's/env_var:[[:space:]]*//')
                [[ -z "$env_var" ]] && env_var="${name^^}_API_KEY"
                export "$env_var=$value"
                ak_log_loaded "$env_var"
            fi
        done
    fi
}
