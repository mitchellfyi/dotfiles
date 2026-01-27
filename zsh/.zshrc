# =============================================================================
# .zshrc - Interactive Shell Configuration
# =============================================================================
# This file is sourced for EVERY interactive shell (runs each time you open
# a terminal). Use this for aliases, functions, interactive tools, and
# anything that enhances your interactive shell experience.
#
# Loading order: 3rd (after .zshenv and .zprofile, before .zlogin)
# =============================================================================

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Set default editor to Cursor
export EDITOR='cursor --wait'

# -----------------------------------------------------------------------------
# PATH Configuration
# -----------------------------------------------------------------------------
# Note: PATH modifications are ordered by priority (earlier = higher priority)
# Only directories that exist are added to PATH for better performance and security

# Helper function to safely add directory to PATH
add_to_path() {
  local dir="$1"
  local position="${2:-append}"  # 'prepend' or 'append'
  
  if [[ -d "$dir" ]]; then
    if [[ "$position" == "prepend" ]]; then
      export PATH="$dir:$PATH"
    else
      export PATH="$PATH:$dir"
    fi
  fi
}

# Helper function to add PostgreSQL to PATH
setup_postgres_path() {
  if [[ -d "/Applications/Postgres.app/Contents/Versions" ]]; then
    local pg_version
    pg_version=$(ls -t /Applications/Postgres.app/Contents/Versions 2>/dev/null | head -1 2>/dev/null)
    if [[ -n "$pg_version" && -d "/Applications/Postgres.app/Contents/Versions/$pg_version/bin" ]]; then
      add_to_path "/Applications/Postgres.app/Contents/Versions/$pg_version/bin"
    fi
  fi
}

# Custom bin directories (highest priority - user scripts)
add_to_path "$HOME/bin" prepend

# Homebrew OpenJDK (check both Intel and Apple Silicon locations)
if [[ -d "/opt/homebrew/opt/openjdk/bin" ]]; then
  add_to_path "/opt/homebrew/opt/openjdk/bin" prepend
elif [[ -d "/usr/local/opt/openjdk/bin" ]]; then
  add_to_path "/usr/local/opt/openjdk/bin" prepend
fi

# PostgreSQL (Postgres.app) - check for latest version
setup_postgres_path

# LM Studio CLI
add_to_path "$HOME/.cache/lm-studio/bin"

# pnpm package manager
export PNPM_HOME="$HOME/.pnpm-global"
add_to_path "$PNPM_HOME"

# RVM (Ruby Version Manager) - PATH setup (initialization happens below)
add_to_path "$HOME/.rvm/bin"

# -----------------------------------------------------------------------------
# Language Version Managers
# -----------------------------------------------------------------------------

autoload -U add-zsh-hook

# Conda (Python environment manager)
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Pyenv (Python version manager)
if [[ -d "$HOME/.pyenv" ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  add_to_path "$PYENV_ROOT/bin" prepend
  
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path 2>/dev/null)" || true
    eval "$(pyenv init - 2>/dev/null)" || true
    eval "$(pyenv virtualenv-init - 2>/dev/null)" || true
  fi
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  \. "$NVM_DIR/nvm.sh"  # This loads nvm
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Auto-switch Node version based on .nvmrc file in current directory
if command -v nvm >/dev/null 2>&1; then
  load-nvmrc() {
    local node_version nvmrc_path nvmrc_node_version
    
    # Check if nvm is available
    if ! command -v nvm >/dev/null 2>&1; then
      return
    fi
    
    node_version="$(nvm version 2>/dev/null)"
    nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"

    if [[ -n "$nvmrc_path" && -f "$nvmrc_path" ]]; then
      nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")" 2>/dev/null)

      if [[ "$nvmrc_node_version" == "N/A" ]]; then
        nvm install >/dev/null 2>&1
      elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
        nvm use >/dev/null 2>&1
      fi
    elif [[ "$node_version" != "$(nvm version default 2>/dev/null)" ]]; then
      nvm use default >/dev/null 2>&1
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

# Keep RVM-managed paths ahead of other tools to avoid warnings
ensure_rvm_path_priority() {
  local dir
  local -a rvm_dirs=()
  local -a other_dirs=()
  local -A seen=()
  local -a parts=(${(s/:/)PATH})

  for dir in "${parts[@]}"; do
    case $dir in
      $HOME/.rvm/gems/*/bin|$HOME/.rvm/rubies/*/bin|$HOME/.rvm/bin)
        if [[ -z ${seen[$dir]} ]]; then
          rvm_dirs+="$dir"
          seen[$dir]=1
        fi
        ;;
      *)
        other_dirs+="$dir"
        ;;
    esac
  done

  if (( ${#rvm_dirs[@]} == 0 )); then
    return
  fi

  local -a reordered_path
  reordered_path=("${rvm_dirs[@]}" "${other_dirs[@]}")
  PATH="${(j/:/)reordered_path}"
  export PATH
}

# RVM (Ruby Version Manager) - initialization
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
  source "$HOME/.rvm/scripts/rvm"
  ensure_rvm_path_priority
  rvm use default >/dev/null 2>&1 || true
  ensure_rvm_path_priority
fi

# Auto-switch Ruby version/gemset based on current directory
if command -v rvm >/dev/null 2>&1; then
  load_rvm_version() {
    local ruby_file=".ruby-version"
    local gemset_file=".ruby-gemset"
    local ruby=""
    local gemset=""

    [[ -f "$ruby_file" ]] && ruby="$(<"$ruby_file")"
    [[ -f "$gemset_file" ]] && gemset="$(<"$gemset_file")"

    ensure_rvm_path_priority

    if [[ -n "$ruby" && -n "$gemset" ]]; then
      rvm use "${ruby}@${gemset}" --install --create >/dev/null
    elif [[ -n "$ruby" ]]; then
      rvm use "$ruby" --install >/dev/null
    elif [[ -n "$gemset" ]]; then
      rvm gemset use "$gemset" >/dev/null
    else
      rvm use default >/dev/null
    fi

    ensure_rvm_path_priority
  }
  add-zsh-hook chpwd load_rvm_version
  load_rvm_version
fi

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------

# Directory Navigation
alias '..'='cd ..'

# Enhanced ls with colors and details
alias ll='ls -lah'
alias la='ls -la'
alias l='ls -lh'

# Quick file operations (interactive - prompts before overwrite)
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Find files
alias ff='find . -type f -name'  # Usage: ff "*.js"
alias fd='find . -type d -name'  # Usage: fd "node_modules"

# Development Tools
# Cursor shortcuts
alias c='cursor .'  # Open current directory in Cursor
alias c.='cursor .'

# Claude shortcuts
alias claudeauto='claude --chrome --dangerously-skip-permissions --model opus --permission-mode bypassPermissions'

# Python virtual environments
alias venv='python3 -m venv .venv'
alias activate='source .venv/bin/activate'

# Node/npm shortcuts
alias ni='npm install'
alias nu='npm uninstall'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# pnpm shortcuts
alias pn='pnpm'
alias pni='pnpm install'
alias pna='pnpm add'
alias pnr='pnpm run'

# PostgreSQL shortcuts (Postgres.app)
alias psql-start='pg_ctl -D /usr/local/var/postgres start'
alias psql-stop='pg_ctl -D /usr/local/var/postgres stop'

# System Utilities
# macOS specific
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

# Process management
alias ports='lsof -i -P -n | grep LISTEN'  # Show listening ports

# Disk usage
alias duh='du -sh * | sort -h'  # Human-readable disk usage, sorted
alias dfh='df -h'  # Human-readable disk space

# Network
alias myip='curl -s https://api.ipify.org'  # Get public IP
alias localip='ipconfig getifaddr en0'  # Get local IP

# Utility aliases
alias cls='clear'
alias h='history'
alias hg='history | grep'

# Quick edit zsh config files
alias zshrc='cursor ~/.zshrc'
alias zshenv='cursor ~/.zshenv'
alias zprofile='cursor ~/.zprofile'

# Reload shell configuration with confirmation
alias reload='source ~/.zshrc && echo "✓ Shell configuration reloaded"'

# -----------------------------------------------------------------------------
# Prompt Configuration
# -----------------------------------------------------------------------------

# Git prompt function - shows branch name and status
# Optimized to avoid slow git status checks
git_prompt_info() {
  local ref dirty
  
  # Fast check: are we in a git repo?
  if ! command git rev-parse --git-dir >/dev/null 2>&1; then
    return 0
  fi
  
  ref=$(command git symbolic-ref --short HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
  
  # Check for uncommitted changes (faster than full status)
  if command git diff --quiet --ignore-submodules HEAD 2>/dev/null; then
    dirty=""
  else
    dirty="*"
  fi
  
  echo " %F{cyan}git:(%f%F{green}${ref}%f%F{cyan})%f%F{red}${dirty}%f"
}

# Set up colored prompt
autoload -U colors && colors
setopt PROMPT_SUBST

PROMPT='%F{blue}%n%f%F{yellow}@%f%F{magenta}%m%f %F{green}%~%f$(git_prompt_info) %F{yellow}%#%f '

# -----------------------------------------------------------------------------
# Custom Functions
# -----------------------------------------------------------------------------

# Create directory and cd into it
mkcd() {
  if [[ -z "$1" ]]; then
    echo "Usage: mkcd <directory>" >&2
    return 1
  fi
  
  mkdir -p "$1" && cd "$1" || return 1
}

# Find and kill process by name
killname() {
  if [[ -z "$1" ]]; then
    echo "Usage: killname <process_name>" >&2
    return 1
  fi
  
  if ! pkill -f "$1" 2>/dev/null; then
    echo "No process found matching '$1'" >&2
    return 1
  fi
}

# Kill process on a specific port
killport() {
  if [[ -z "$1" ]]; then
    echo "Usage: killport <port_number>" >&2
    return 1
  fi
  
  local pids
  pids=$(lsof -ti:$1 2>/dev/null)
  
  if [[ -z "$pids" ]]; then
    echo "No process found on port $1" >&2
    return 1
  fi
  
  echo "$pids" | xargs kill
}


# -----------------------------------------------------------------------------
# Local Configuration
# -----------------------------------------------------------------------------

# Load environment variables from .env file in dotfiles directory (if it exists)
# This file should contain sensitive variables and is gitignored
# Detect dotfiles directory from current file location
DOTFILES_DIR="$(cd "$(dirname "${(%):-%x}")/.." 2>/dev/null && pwd)"
if [[ -n "$DOTFILES_DIR" && -f "$DOTFILES_DIR/.env" ]]; then
  set -a  # Automatically export all variables
  source "$DOTFILES_DIR/.env" 2>/dev/null || true
  set +a  # Stop automatically exporting
fi
unset DOTFILES_DIR  # Clean up variable

# Source local environment configuration (if it exists)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
