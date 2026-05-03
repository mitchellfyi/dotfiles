#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:mitchellfyi/dotfiles.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/Dropbox/work/dotfiles}"
ZSH_FILES=(zshenv zprofile zshrc zlogin)

expand_path() {
  # Try perl first (most reliable), fall back to readlink or cd
  if command -v perl >/dev/null 2>&1; then
    perl -MFile::Spec -e 'print File::Spec->rel2abs($ARGV[0])' "$1"
  elif command -v readlink >/dev/null 2>&1; then
    readlink -f "$1" 2>/dev/null || echo "$1"
  else
    # Fallback: resolve relative paths manually
    if [[ "$1" != /* ]]; then
      echo "$(pwd)/$1"
    else
      echo "$1"
    fi
  fi
}

TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
TARGET_DIR="$(expand_path "$TARGET_DIR")"
DROPBOX_ROOT="$(dirname "$TARGET_DIR")"

link_with_backup() {
  # link_with_backup <src> <dst> — symlink src→dst, backing up regular file at dst
  local src="$1" dst="$2"
  if [[ -f "$src" ]]; then
    if [[ -e "$dst" && ! -L "$dst" ]]; then
      mv "$dst" "$dst.backup-$(date +%s)"
      echo "    backed up existing $dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "    linked $dst"
  fi
}

echo ">>> Ensuring dependencies..."
if ! xcode-select -p >/dev/null 2>&1; then
  echo "    Installing Xcode Command Line Tools..."
  xcode-select --install 2>/dev/null || true
  echo "    Please complete the Xcode CLT installation, then re-run this script."
  exit 1
fi

# Detect Homebrew location (Apple Silicon or Intel)
BREW_CMD=""
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  BREW_CMD="/opt/homebrew/bin/brew"
elif [[ -f "/usr/local/bin/brew" ]]; then
  BREW_CMD="/usr/local/bin/brew"
fi

if [[ -z "$BREW_CMD" ]]; then
  echo "    Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Re-detect after installation
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    BREW_CMD="/opt/homebrew/bin/brew"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    BREW_CMD="/usr/local/bin/brew"
  fi
fi

if [[ -n "$BREW_CMD" ]]; then
  echo "    Installing core packages (zsh, git, gh, gnupg)..."
  "$BREW_CMD" install --quiet zsh git gh gnupg || {
    echo "    Failed to install core dependencies." >&2
    exit 1
  }

  echo "    Installing dev CLIs..."
  "$BREW_CMD" install --quiet \
    ripgrep fd jq bat eza fzf tldr tree htop wget httpie uv \
    zsh-autosuggestions zsh-syntax-highlighting \
    || echo "    Warning: some dev CLIs failed to install" >&2

  echo "    Installing databases (redis, mysql)..."
  "$BREW_CMD" install --quiet redis mysql \
    || echo "    Warning: database install failed" >&2

  echo "    Installing casks (Cursor, Postgres.app, Docker Desktop)..."
  for cask in cursor postgres-app docker-desktop; do
    if "$BREW_CMD" list --cask "$cask" >/dev/null 2>&1; then
      continue  # already managed by brew
    fi
    if ! "$BREW_CMD" install --quiet --cask "$cask" 2>/dev/null; then
      # Fall back to adopting a pre-existing manually-installed app
      "$BREW_CMD" install --quiet --cask --adopt "$cask" 2>/dev/null \
        || echo "    Warning: cask $cask not installed via brew (may be present manually)" >&2
    fi
  done

  echo "    Linking cursor CLI into ~/.local/bin..."
  mkdir -p "$HOME/.local/bin"
  if [[ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
    ln -sf "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" "$HOME/.local/bin/cursor"
  else
    echo "    Warning: Cursor.app not found; skipping cursor CLI symlink" >&2
  fi

  echo "    Setting up fzf shell integration..."
  FZF_INSTALL="$("$BREW_CMD" --prefix)/opt/fzf/install"
  if [[ -x "$FZF_INSTALL" ]]; then
    "$FZF_INSTALL" --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null \
      || echo "    Warning: fzf shell integration setup failed" >&2
  fi

  echo "    Starting database services (redis, mysql)..."
  "$BREW_CMD" services start redis >/dev/null 2>&1 || true
  "$BREW_CMD" services start mysql >/dev/null 2>&1 || true
else
  echo "    Warning: Could not find Homebrew. Manual install required." >&2
fi

echo ">>> Installing mise and language runtimes..."
if [[ -n "$BREW_CMD" ]]; then
  "$BREW_CMD" install --quiet mise libyaml || echo "    Warning: Failed to install mise/libyaml" >&2
fi

MISE_CMD=""
for _candidate in "/opt/homebrew/bin/mise" "/usr/local/bin/mise"; do
  [[ -f "$_candidate" ]] && MISE_CMD="$_candidate" && break
done
# Pick up mise if it was already on PATH before this script ran
if [[ -z "$MISE_CMD" ]] && command -v mise >/dev/null 2>&1; then
  MISE_CMD="$(command -v mise)"
fi

if [[ -n "$MISE_CMD" ]]; then
  echo "    Configuring mise (precompiled Ruby)..."
  "$MISE_CMD" settings ruby.compile=false

  echo "    Installing node (LTS), ruby (latest), python (latest)..."
  "$MISE_CMD" use --global node@lts ruby@latest python@latest

  echo "    Installing global CLIs via npm..."
  eval "$("$MISE_CMD" env -s bash)"
  npm install -g npm@latest \
    @openai/codex \
    @github/copilot \
    pnpm
else
  echo "    Warning: mise not found — skipping runtime and CLI installation" >&2
fi

echo ">>> Installing Claude Code (native installer)..."
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash || echo "    Warning: Claude Code install failed" >&2
else
  echo "    Already installed at $(command -v claude)"
fi

echo ">>> Installing gh-copilot extension..."
if command -v gh >/dev/null 2>&1; then
  if ! gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
    gh extension install github/gh-copilot || echo "    Warning: gh-copilot install failed (try 'gh auth login' first)" >&2
  else
    echo "    Already installed"
  fi
else
  echo "    Warning: gh not on PATH; skipping gh-copilot" >&2
fi

echo ">>> Preparing Dropbox folder at $DROPBOX_ROOT"
mkdir -p "$DROPBOX_ROOT"

if [[ -d "$TARGET_DIR/.git" ]]; then
  echo ">>> Updating existing dotfiles repo at $TARGET_DIR"
  if ! git -C "$TARGET_DIR" pull --rebase --autostash; then
    echo "    Warning: Failed to update dotfiles. Continuing anyway..." >&2
  fi
else
  echo ">>> Cloning dotfiles repo into $TARGET_DIR"
  if ! git clone "$REPO_URL" "$TARGET_DIR"; then
    echo "    Error: Failed to clone dotfiles repository." >&2
    exit 1
  fi
fi

create_loader() {
  local name="$1"
  local loader="$HOME/.${name}"
  local source_path="$TARGET_DIR/zsh/.${name}"

  cat <<EOF > "$loader"
#!/usr/bin/env zsh
DOTFILES_FILE="$source_path"
if [ -f "\$DOTFILES_FILE" ]; then
  source "\$DOTFILES_FILE"
else
  echo "dotfiles ${name} not found at \$DOTFILES_FILE" >&2
fi
EOF
  chmod 644 "$loader"
  echo "    wrote $loader -> $source_path"
}

echo ">>> Writing loader files"
for file in "${ZSH_FILES[@]}"; do
  create_loader "$file"
done

if [ "$(basename "$SHELL")" != "zsh" ]; then
  echo ">>> Setting default shell to /bin/zsh (requires password)"
  chsh -s /bin/zsh "$USER"
else
  echo ">>> Default shell already zsh"
fi

echo ">>> Linking Cursor keybindings"
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_USER_DIR" ]]; then
  link_with_backup "$TARGET_DIR/cursor/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
else
  echo "    Cursor user dir missing (open Cursor once); skipping"
fi

echo ">>> Linking gitconfig and gitignore_global"
link_with_backup "$TARGET_DIR/git/.gitconfig" "$HOME/.gitconfig"
link_with_backup "$TARGET_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

echo ">>> SSH key check"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh_email="$(git config --global user.email 2>/dev/null || echo "$USER@$(hostname -s)")"
  echo "    Generating ed25519 key for $ssh_email"
  ssh-keygen -t ed25519 -C "$ssh_email" -f "$SSH_KEY" -N "" -q
  ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || true
  echo "    ----- Public key (add to GitHub: https://github.com/settings/ssh/new) -----"
  cat "$SSH_KEY.pub"
  echo "    ----- end public key -----"
else
  echo "    SSH key already exists at $SSH_KEY"
fi

echo ">>> Configuring MCP servers (Vercel, Linear, Figma, Datadog, GitHub, Sentry, DigitalOcean, Hetzner)"
# OAuth-based servers prompt for auth on first connection.
# GitHub & DigitalOcean MCPs may require a PAT — re-add with --header / env if so.
# Hetzner is third-party; it inherits HCLOUD_TOKEN from the shell environment.
# Skipped: Dokku (no Mac binary), Segment (no official server), Grafana (local only, needs URL+token).

add_mcp_claude() {
  # add_mcp_claude <name> <transport> <url>
  local name="$1" transport="$2" url="$3"
  command -v claude >/dev/null 2>&1 || return 0
  claude mcp remove "$name" >/dev/null 2>&1 || true
  claude mcp add -s user --transport "$transport" "$name" "$url" >/dev/null 2>&1 \
    || echo "    Warning: claude mcp add $name failed" >&2
}

add_mcp_claude_stdio() {
  # add_mcp_claude_stdio <name> <command> [args...]
  local name="$1"; shift
  command -v claude >/dev/null 2>&1 || return 0
  claude mcp remove "$name" >/dev/null 2>&1 || true
  claude mcp add -s user "$name" -- "$@" >/dev/null 2>&1 \
    || echo "    Warning: claude mcp add $name failed" >&2
}

write_codex_mcps() {
  # Codex's `mcp add` auto-launches an OAuth flow per server, which would chain
  # 7 browser prompts during setup. Write the TOML directly instead — auth is
  # deferred until first use (or `codex mcp login <name>`).
  local config="$HOME/.codex/config.toml"
  mkdir -p "$HOME/.codex"
  touch "$config"
  # Strip any prior dotfiles-managed block
  perl -i -ne 'print unless /^# >>> dotfiles MCP/../^# <<< dotfiles MCP/' "$config"
  cat >> "$config" <<'TOML_EOF'
# >>> dotfiles MCP servers >>>
[mcp_servers.vercel]
url = "https://mcp.vercel.com"

[mcp_servers.linear]
url = "https://mcp.linear.app/mcp"

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"

[mcp_servers.datadog]
url = "https://mcp.datadoghq.com/api/unstable/mcp-server/mcp"

[mcp_servers.github]
url = "https://api.githubcopilot.com/mcp"

[mcp_servers.sentry]
url = "https://mcp.sentry.dev/mcp"

[mcp_servers.digitalocean]
url = "https://apps.mcp.digitalocean.com/mcp"

[mcp_servers.hetzner]
command = "uvx"
args = ["--from", "git+https://github.com/dkruyt/mcp-hetzner.git", "mcp-hetzner"]
# <<< dotfiles MCP servers <<<
TOML_EOF
}

if command -v claude >/dev/null 2>&1; then
  echo "    Claude Code..."
  add_mcp_claude vercel       http https://mcp.vercel.com
  add_mcp_claude linear       http https://mcp.linear.app/mcp
  add_mcp_claude figma        http https://mcp.figma.com/mcp
  add_mcp_claude datadog      http https://mcp.datadoghq.com/api/unstable/mcp-server/mcp
  add_mcp_claude github       http https://api.githubcopilot.com/mcp
  add_mcp_claude sentry       http https://mcp.sentry.dev/mcp
  add_mcp_claude digitalocean http https://apps.mcp.digitalocean.com/mcp
  add_mcp_claude_stdio hetzner uvx --from git+https://github.com/dkruyt/mcp-hetzner.git mcp-hetzner
fi

if command -v codex >/dev/null 2>&1; then
  echo "    Codex CLI..."
  write_codex_mcps
fi

echo "    GitHub Copilot CLI..."
# Copilot CLI ships GitHub MCP built-in, so the dotfiles config covers the others only.
link_with_backup "$TARGET_DIR/mcp/copilot-mcp-config.json" "$HOME/.copilot/mcp-config.json"

echo ">>> Applying macOS preferences"
# Trackpad / Mouse
defaults write -g com.apple.swipescrolldirection -bool false       # disable natural scrolling

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true       # show hidden files
defaults write NSGlobalDomain AppleShowAllExtensions -bool true    # show file extensions
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true # full POSIX path in title

# Dock / Mission Control
defaults write com.apple.dock mru-spaces -bool false               # don't auto-rearrange Spaces

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false # disable accent menu on hold

# Text editing — disable autocorrect/smart-quotes/etc. (annoying for code)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Save dialogs default to expanded
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Screenshots — to ~/Screenshots, PNG
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"

killall Finder >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
echo "    macOS preferences applied (some changes require sign-out)"

cat <<MSG
All done! Dotfiles are synced at $TARGET_DIR.

Manual follow-ups:
  - Open a new terminal (any directory) or run \`exec zsh -l\` to load the Dropbox-backed config.
  - Sign out and back in for the natural-scroll change to take effect.
  - Restart Cursor for the keybindings symlink to take effect.
  - Launch Docker Desktop once to accept terms and start the daemon.
  - Run \`mysql_secure_installation\` to set the MySQL root password.
  - Run \`gh auth login\` to authenticate gh-copilot.
  - If a new SSH key was generated above, add it to GitHub.
  - Add HCLOUD_TOKEN=... to ~/Dropbox/work/dotfiles/.env if you plan to use the Hetzner MCP.
MSG
