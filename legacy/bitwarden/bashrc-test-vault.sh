# Test vault management (jackc@chidley.org on vault.bitwarden.eu)
# Uses TEST_ prefix for all variables to avoid conflicts with production

bw_test_unlock() {
  if [[ -z "$BW_SESSION" ]]; then
    echo "❌ Main vault needed to get test password"
    echo "   Run: bw_unlock"
    return 1
  fi
  
  # Use the bw-test-unlock script
  if command -v bw-test-unlock &>/dev/null; then
    eval "$(bw-test-unlock | grep 'export BW_TEST_SESSION')"
  else
    echo "❌ bw-test-unlock not found in PATH"
    return 1
  fi
}

load-test-keys() {
  if [[ -z "$BW_TEST_SESSION" ]]; then
    echo "Test vault not unlocked. Unlocking..."
    bw_test_unlock || return 1
  fi
  
  # Helper to get from test vault (inline function)
  _bw_test_get() {
    local item="$1"
    local field="${2:-password}"
    
    if [[ "$field" == "password" ]]; then
      bw get password "$item" --session "$BW_TEST_SESSION" 2>/dev/null
    else
      bw get item "$item" --session "$BW_TEST_SESSION" 2>/dev/null | \
        jq -r ".fields[] | select(.name==\"$field\") | .value" 2>/dev/null
    fi
  }
  
  # Load all test keys with TEST_ prefix
  export TEST_ANTHROPIC_API_KEY=$(_bw_test_get "Anthropic" "opencode")
  export TEST_BRAVE_API_KEY=$(_bw_test_get "brave.com" "pi-agent")
  export TEST_DEEPSEEK_API_KEY=$(_bw_test_get "deepseek.com" "llm")
  export TEST_GITHUB_TOKEN=$(_bw_test_get "github.com" "repo")
  export TEST_GOOGLE_AI_API_KEY=$(_bw_test_get "Google AI" "Google")
  export TEST_GROQ_API_KEY=$(_bw_test_get "groq cloud" "pi")
  export TEST_MOONSHOT_API_KEY=$(_bw_test_get "moonshot.ai" "pi-agent")
  export TEST_OPENAI_API_KEY=$(_bw_test_get "OpenAI" "opencode")
  export TEST_SPIDER_API_KEY=$(_bw_test_get "spider.cloud" "web_to_md")
  
  echo "✓ Test keys loaded (TEST_* variables)"
}

show-test-keys() {
  echo "Test keys (from test vault):"
  local keys=(TEST_ANTHROPIC_API_KEY TEST_BRAVE_API_KEY TEST_DEEPSEEK_API_KEY \
              TEST_GITHUB_TOKEN TEST_GOOGLE_AI_API_KEY TEST_GROQ_API_KEY \
              TEST_MOONSHOT_API_KEY TEST_OPENAI_API_KEY TEST_SPIDER_API_KEY \
              BW_TEST_SESSION)
  
  for var in "${keys[@]}"; do
    local val="${!var}"
    if [[ -n "$val" && "$val" != "unset" ]]; then
      echo "  ✓ $var (${val:0:20}...)"
    else
      echo "  ✗ $var (not set)"
    fi
  done
}

clear-test-keys() {
  unset TEST_ANTHROPIC_API_KEY TEST_BRAVE_API_KEY TEST_DEEPSEEK_API_KEY \
        TEST_GITHUB_TOKEN TEST_GOOGLE_AI_API_KEY TEST_GROQ_API_KEY \
        TEST_MOONSHOT_API_KEY TEST_OPENAI_API_KEY TEST_SPIDER_API_KEY \
        BW_TEST_SESSION
  echo "✓ Test keys cleared"
}

switch-to-test() {
