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

# OpenAI API Key (consider moving to ~/.local/bin/env for security)
export OPENAI_API_KEY=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

# -----------------------------------------------------------------------------
# PATH Configuration
# -----------------------------------------------------------------------------
# Note: PATH modifications are ordered by priority (earlier = higher priority)

# Custom bin directories (highest priority - user scripts)
export PATH="$HOME/bin:$PATH"
export PATH="$HOME:$PATH"

# Homebrew OpenJDK
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# PostgreSQL (Postgres.app)
export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/15/bin"

# LM Studio CLI
export PATH="$PATH:$HOME/.cache/lm-studio/bin"

# pnpm package manager
export PNPM_HOME="$HOME/.pnpm-global"
export PATH="$PNPM_HOME:$PATH"

# RVM (Ruby Version Manager) - PATH setup (initialization happens below)
export PATH="$PATH:$HOME/.rvm/bin"

# -----------------------------------------------------------------------------
# Language Version Managers
# -----------------------------------------------------------------------------

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
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# RVM (Ruby Version Manager) - initialization
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
  source "$HOME/.rvm/scripts/rvm"
fi

# Auto-switch Ruby version/gemset based on current directory
if command -v rvm >/dev/null 2>&1; then
  autoload -U add-zsh-hook
  load_rvm_version() {
    local ruby_file=".ruby-version"
    local gemset_file=".ruby-gemset"
    local ruby=""
    local gemset=""

    [[ -f "$ruby_file" ]] && ruby="$(<"$ruby_file")"
    [[ -f "$gemset_file" ]] && gemset="$(<"$gemset_file")"

    if [[ -n "$ruby" && -n "$gemset" ]]; then
      rvm use "${ruby}@${gemset}" --install --create >/dev/null
    elif [[ -n "$ruby" ]]; then
      rvm use "$ruby" --install >/dev/null
    elif [[ -n "$gemset" ]]; then
      rvm gemset use "$gemset" >/dev/null
    else
      rvm use default >/dev/null
    fi
  }
  add-zsh-hook chpwd load_rvm_version
  load_rvm_version
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Auto-switch Node version based on .nvmrc file in current directory
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

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
git_prompt_info() {
  local ref
  ref=$(command git symbolic-ref --short HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
  
  # Check if there are uncommitted changes
  local dirty=""
  if [[ -n $(command git status --porcelain 2> /dev/null) ]]; then
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
  mkdir -p "$1" && cd "$1"
}

# Find and kill process by name
killname() {
  if [ -z "$1" ]; then
    echo "Usage: killname <process_name>"
    return 1
  fi
  pkill -f "$1"
}

# Kill process on a specific port
killport() {
  if [ -z "$1" ]; then
    echo "Usage: killport <port_number>"
    return 1
  fi
  lsof -ti:$1 | xargs kill
}


# -----------------------------------------------------------------------------
# Local Configuration
# -----------------------------------------------------------------------------

# Source local environment configuration (if it exists)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
