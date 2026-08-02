# ak - API Key Manager shell functions
# Source this file in .bashrc or .zshrc after installing ak in ~/.local/bin.

if ! command -v ak >/dev/null 2>&1; then
    echo "ak is not installed on PATH (expected ~/.local/bin/ak)" >&2
fi

# Load all API keys into environment
load_api_keys() {
    eval "$(ak export)"
}
alias load-api-keys='load_api_keys'

# Aliases
alias show-keys='ak list'
alias get-key='ak get'
alias set-key='ak set'
