# =============================================================================
# .zprofile - Login Shell Environment Setup
# =============================================================================
# This file is sourced ONLY for login shells (runs once per login session).
# Use this for login-specific environment setup that should happen before
# interactive shell configuration.
#
# Loading order: 2nd (after .zshenv, before .zshrc)
# =============================================================================

# Homebrew environment setup (needed early for package manager access)
# Support both Apple Silicon and Intel Macs
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
