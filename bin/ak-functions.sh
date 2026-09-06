# ak - API Key Manager shell functions
# Legacy convenience examples, not approved shell startup or agent automation.
# Do not source automatically; use the reviewed explicit direnv service allowlist.

if ! command -v ak >/dev/null 2>&1; then
    echo "ak is not installed on PATH (expected ~/.local/bin/ak)" >&2
fi

# Retained unsupported bulk-load helper; not an approved fallback.
load_api_keys() {
    eval "$(ak export)"
}
alias load-api-keys='load_api_keys'

# Aliases
alias show-keys='ak list'
alias get-key='ak get'
alias set-key='ak set'
