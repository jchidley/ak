# ak - API Key Manager shell functions
# Source this file in .bashrc or .zshrc
# Requires: gpg, ~/tools/api-keys/bin/ak

# Ensure ak is in PATH
export PATH="$HOME/tools/api-keys/bin:$PATH"

# Load all API keys into environment
load_api_keys() {
    eval "$(ak export)"
}
alias load-api-keys='load_api_keys'

# Aliases
alias show-keys='ak list'
alias get-key='ak get'
alias set-key='ak set'
