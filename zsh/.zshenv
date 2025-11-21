# =============================================================================
# .zshenv - Environment Variables (Always Loaded)
# =============================================================================
# This file is sourced for ALL zsh invocations (interactive and non-interactive).
# Use this file for environment variables that must be available everywhere,
# including scripts and non-interactive shells.
#
# Loading order: 1st (before all other zsh config files)
# =============================================================================

# Rust/Cargo environment (needed for cargo commands in scripts)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
