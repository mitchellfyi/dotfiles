# Dotfiles

Configuration lives in `~/Dropbox/work/dotfiles` so iCloud/Time Machine stay clean while Dropbox keeps it synced. `$HOME` only holds thin loaders that source the tracked files.

## Structure

- `zsh/.zshenv` – always-loaded env vars
- `zsh/.zprofile` – login-shell setup
- `zsh/.zshrc` – interactive shell config
- `zsh/.zlogin` – post-login hook

## Quick setup / sync script

Run the bootstrap script directly from GitHub:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mitchellfyi/dotfiles/main/scripts/setup.sh)
```

What it does:

1. Installs Xcode CLT, Homebrew, `zsh`, and `git` if missing.
2. Ensures `~/Dropbox/work/dotfiles` exists, cloning or updating `git@github.com:mitchellfyi/dotfiles.git`.
3. Writes loader files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.zlogin`) that point at the absolute Dropbox path so every new terminal (regardless of working directory) sources the right config.
4. Sets `/bin/zsh` as the default login shell (if not already) and reloads the config.

You can override the defaults by setting `REPO_URL` or `TARGET_DIR` before running the command, e.g.

```bash
REPO_URL="https://github.com/mitchellfyi/dotfiles.git" TARGET_DIR="$HOME/Dropbox/work/dotfiles" \
  bash <(curl -fsSL https://raw.githubusercontent.com/mitchellfyi/dotfiles/main/scripts/setup.sh)
```

After bootstrap, edit/commit files inside `~/Dropbox/work/dotfiles` (for example `~/Dropbox/work/dotfiles/zsh/.zshrc`). The loader files in `$HOME` simply source the synced versions and should rarely change.
