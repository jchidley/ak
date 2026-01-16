bw_unlock() {
  local skip_reload=false
  if [[ "$1" == "--no-reload" ]] || [[ "$1" == "-n" ]]; then
    skip_reload=true
  fi

  # Check if already unlocked with a valid session
  local status
  status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null)
  
  if [[ "$status" == "unlocked" ]] && [[ -n "$BW_SESSION" ]]; then
    if [[ "$skip_reload" == true ]]; then
      echo "Bitwarden is already unlocked."
      return 0
    fi
    echo "Bitwarden already unlocked. Reloading direnv..."
    direnv reload
    return 0
  fi
  
  # Try to unlock
  local session
  session=$(bw unlock --raw)
  
  if [[ -n "$session" ]]; then
    export BW_SESSION="$session"
    echo "Bitwarden unlocked. Reloading direnv for current directory..."
    # direnv reload only affects the current directory's .envrc
    # If you're in ~, it loads ~/.envrc; project dirs need their own reload
    direnv reload
    if [[ "$PWD" == "$HOME" ]]; then
      echo "Tip: cd to project directories to reload their .envrc files"
    fi
  else
    echo "Failed to unlock Bitwarden"
  fi
}

bw_lock() {
  bw lock
  unset BW_SESSION
  direnv reload
}

# Source Bitwarden helper functions (shared with direnv)
# These are in ~/.config/direnv/lib/bitwarden.sh - single source of truth
if [ -f "$HOME/.config/direnv/lib/bitwarden.sh" ]; then
  source "$HOME/.config/direnv/lib/bitwarden.sh"
fi

# Manual API key loading functions
# Security: Keys are NOT auto-loaded. Load only when needed, clear when done.
# See: ~/API_KEY_SECURITY_PLAN.md

load-anthropic() {
  echo "⚠️  Loading ANTHROPIC_API_KEY"
  echo "   Consider using load-anthropic-limited for LLM sessions"
  export ANTHROPIC_API_KEY=$(bw_get "Anthropic" "opencode")
}

load-anthropic-limited() {
  echo "Loading spending-limited Anthropic key for tool use"
  export ANTHROPIC_API_KEY=$(bw_get "Anthropic" "claude-code")
}

load-brave() {
  echo "Loading BRAVE_API_KEY (low risk - free tier)"
  export BRAVE_API_KEY=$(bw_get "brave.com" "pi-agent")
}

load-deepseek() {
  echo "⚠️  Loading DEEPSEEK_API_KEY"
  export DEEPSEEK_API_KEY=$(bw_get "deepseek.com" "llm")
}

load-deepseek-limited() {
  echo "Loading spending-limited DeepSeek key for tool use"
  export DEEPSEEK_API_KEY=$(bw_get "deepseek.com" "tool-limited")
}

load-github() {
  echo "Loading GitHub read-only token"
  echo "For write access, use: load-github-repo <reponame>"
  export GITHUB_TOKEN=$(bw_get "github.com" "readonly")
}

load-github-full() {
  echo "⚠️  Loading FULL ACCESS GitHub token"
  echo "   This key has access to ALL your repositories"
  echo "   Consider using load-github-readonly or load-github-repo instead"
  read -p "Are you sure? (yes/no): " confirm
  if [[ "$confirm" == "yes" ]]; then
    export GITHUB_TOKEN=$(bw_get "github.com" "repo")
  else
    echo "Cancelled"
    return 1
  fi
}

load-github-repo() {
  local repo="$1"
  if [[ -z "$repo" ]]; then
    echo "Usage: load-github-repo <reponame>"
    return 1
  fi
  echo "Loading GitHub token for repo: $repo"
  export GITHUB_TOKEN=$(bw_get "github.com" "repo-${repo}")
}

load-google() {
  echo "⚠️  Loading GOOGLE_AI_API_KEY"
  export GOOGLE_AI_API_KEY=$(bw_get "Google AI" "Google")
}

load-google-limited() {
  echo "Loading quota-limited Google AI key for tool use"
  export GOOGLE_AI_API_KEY=$(bw_get "Google AI" "tool-limited")
}

load-groq() {
  echo "Loading GROQ_API_KEY (medium risk)"
  export GROQ_API_KEY=$(bw_get "groq cloud" "pi")
}

load-moonshot() {
  echo "⚠️  Loading MOONSHOT_API_KEY"
  export MOONSHOT_API_KEY=$(bw_get "moonshot.ai" "pi-agent")
}

load-moonshot-limited() {
  echo "Loading Moonshot key for tool use"
  export MOONSHOT_API_KEY=$(bw_get "moonshot.ai" "tool-limited")
}

load-openai() {
  echo "⚠️  Loading OPENAI_API_KEY"
  export OPENAI_API_KEY=$(bw_get "OpenAI" "opencode")
}

load-openai-limited() {
  echo "Loading spending-limited OpenAI key for tool use"
  export OPENAI_API_KEY=$(bw_get "OpenAI" "tool-limited")
}

load-spider() {
  echo "Loading SPIDER_API_KEY (low risk - quota limited)"
  export SPIDER_API_KEY=$(bw_get "spider.cloud" "web_to_md")
}

# Convenience: Load multiple low-risk keys
load-safe-keys() {
  load-brave
  load-spider
}

# Clear all keys from environment
clear-keys() {
  unset ANTHROPIC_API_KEY BRAVE_API_KEY DEEPSEEK_API_KEY GITHUB_TOKEN \
        GOOGLE_AI_API_KEY GROQ_API_KEY MOONSHOT_API_KEY OPENAI_API_KEY \
        SPIDER_API_KEY BW_SESSION
  echo "✓ All API keys cleared from environment"
}

# Show which keys are currently loaded
show-keys() {
  echo "Currently loaded keys:"
  local keys=(ANTHROPIC_API_KEY BRAVE_API_KEY DEEPSEEK_API_KEY GITHUB_TOKEN \
              GOOGLE_AI_API_KEY GROQ_API_KEY MOONSHOT_API_KEY OPENAI_API_KEY \
              SPIDER_API_KEY BW_SESSION)
  
  for var in "${keys[@]}"; do
    local val="${!var}"
    if [[ -n "$val" && "$val" != "unset" ]]; then
      echo "  ✓ $var (${val:0:20}...)"
    else
      echo "  ✗ $var (not set)"
    fi
  done
