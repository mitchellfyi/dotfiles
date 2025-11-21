#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:mitchellfyi/dotfiles.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/Dropbox/work/dotfiles}"
ZSH_FILES=(zshenv zprofile zshrc zlogin)

expand_path() {
  perl -MFile::Spec -e 'print File::Spec->rel2abs($ARGV[0])' "$1"
}

TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
TARGET_DIR="$(expand_path "$TARGET_DIR")"
DROPBOX_ROOT="$(dirname "$TARGET_DIR")"

echo ">>> Ensuring dependencies..."
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install 2>/dev/null || true
fi
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew install --quiet zsh git

echo ">>> Preparing Dropbox folder at $DROPBOX_ROOT"
mkdir -p "$DROPBOX_ROOT"

if [ -d "$TARGET_DIR/.git" ]; then
  echo ">>> Updating existing dotfiles repo at $TARGET_DIR"
  git -C "$TARGET_DIR" pull --rebase --autostash
else
  echo ">>> Cloning dotfiles repo into $TARGET_DIR"
  git clone "$REPO_URL" "$TARGET_DIR"
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

echo ">>> Reloading ~/.zshrc"
source "$HOME/.zshrc"

cat <<MSG
All done! Dotfiles are synced from $TARGET_DIR.
Open a new terminal (any directory) and zsh will pick up the Dropbox-backed config.
Commit/push changes from that folder to share them across machines.
MSG
