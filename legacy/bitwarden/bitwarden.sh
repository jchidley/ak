# Bitwarden helper functions for direnv
# These functions are available in .envrc files
# Requires BW_SESSION to be set (run: bw_unlock in your shell)

# Get a value from Bitwarden
# Usage: bw_get <item> <field>
#   item - Bitwarden item name
#   field - Field name (defaults to "password", can be "notes" or custom field name)
bw_get() {
  local item="$1"
  local field="${2:-password}"

  if [[ -z "$BW_SESSION" ]]; then
    log_error "BW_SESSION not set. Run: bw_unlock"
    return 1
  fi

  if [[ "$field" == "password" ]]; then
    bw get password "$item" --session "$BW_SESSION" 2>/dev/null
  elif [[ "$field" == "notes" ]]; then
    bw get notes "$item" --session "$BW_SESSION" 2>/dev/null
  else
    # Custom field - get full item and extract
    bw get item "$item" --session "$BW_SESSION" 2>/dev/null | \
      jq -r ".fields[] | select(.name==\"$field\") | .value" 2>/dev/null
  fi
}

# Load API keys from Bitwarden using explicit item/field mappings
# Exports all configured API keys as environment variables
# Optimized: fetches all items once instead of per-key (9x faster)
load_api_keys() {
  if [[ -z "$BW_SESSION" ]]; then
    return 0
  fi

  # Verify session is still valid
  local status
  status=$(bw status --session "$BW_SESSION" 2>/dev/null | jq -r '.status' 2>/dev/null)
  if [[ "$status" != "unlocked" ]]; then
    log_error "Bitwarden session expired. Run: bw_unlock"
    return 0
  fi

  # Fetch all items once (this is the slow operation ~5s)
  local all_items
  all_items=$(bw list items --session "$BW_SESSION" 2>/dev/null)
  if [[ -z "$all_items" ]]; then
    return 1
  fi

  # Extract all API keys in a single jq pass
  # Output format: ENV_VAR=value (one per line)
  local exports
  exports=$(echo "$all_items" | jq -r '
    # Define mappings: [env_var, item_pattern, field_pattern]
    [
      ["ANTHROPIC_API_KEY", "Anthropic", "opencode"],
      ["BRAVE_API_KEY", "brave.com", "pi-agent"],
      ["DEEPSEEK_API_KEY", "deepseek.com", "llm"],
      ["GITHUB_TOKEN", "github.com", "repo"],
      ["GOOGLE_AI_API_KEY", "Google AI", "Google"],
      ["GROQ_API_KEY", "groq cloud", "pi"],
      ["MOONSHOT_API_KEY", "moonshot.ai", "pi-agent"],
      ["OPENAI_API_KEY", "OpenAI", "opencode"],
      ["SPIDER_API_KEY", "spider.cloud", "web_to_md"]
    ] as $mappings |
    . as $items |

    # For each mapping, find the matching item and field
    $mappings[] | . as [$env_var, $item_pattern, $field_pattern] |
    (
      # Find item matching the pattern, then its matching field value
      [$items[] | select(.name | test($item_pattern; "i")) |
       (.fields // [])[] | select(.name | test("api[_\\- ]?key"; "i")) |
       select(.name | test($field_pattern; "i")) |
       .value] | first // empty
    ) as $value |
    select($value != null and $value != "") |
    "\($env_var)=\($value)"
  ')

  # Export each variable
  while IFS='=' read -r var val; do
    if [[ -n "$var" && -n "$val" ]]; then
      export "$var=$val"
    fi
  done <<< "$exports"
}

# Find all items with API-key-like fields in Bitwarden
# Usage: bw_find_api_keys (for discovery purposes)
bw_find_api_keys() {
  if [[ -z "$BW_SESSION" ]]; then
    echo "BW_SESSION not set. Run: bw_unlock" >&2
    return 1
  fi

  bw list items --session "$BW_SESSION" 2>/dev/null | jq -r '
    .[] | select(.fields != null) |
    select(.fields | any(.name | test("api[_\\- ]?key"; "i"))) |
    "\(.name): \([.fields[] | select(.name | test("api[_\\- ]?key"; "i")) | .name] | join(", "))"
  '
}

# Find all items with custom fields (name and value set)
# Usage: bw_find_custom_fields
bw_find_custom_fields() {
  if [[ -z "$BW_SESSION" ]]; then
    echo "BW_SESSION not set. Run: bw_unlock" >&2
    return 1
  fi

  bw list items --session "$BW_SESSION" 2>/dev/null | jq -r '
    [.[] | select(.fields != null) |
     select([.fields[] | select(.name != "" and .value != "")] | length > 0) |
     .name] | unique[]
  '
}
