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
  echo "    Installing zsh and git..."
  "$BREW_CMD" install --quiet zsh git || {
    echo "    Failed to install dependencies. Please install manually:" >&2
    echo "    $BREW_CMD install zsh git" >&2
    exit 1
  }
else
  echo "    Warning: Could not find Homebrew. Please install zsh and git manually." >&2
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

cat <<MSG
All done! Dotfiles are synced at $TARGET_DIR.
- Open a new terminal (any directory) or run \`exec zsh -l\` to load the Dropbox-backed config.
- Commit/push changes from that folder to keep other machines in sync.
MSG
