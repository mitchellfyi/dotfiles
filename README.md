# Dotfiles

Configuration lives in `~/Dropbox/work/dotfiles` so iCloud/Time Machine stay clean while Dropbox keeps it synced. `$HOME` only holds thin loaders that source the tracked files.

## Structure

- `zsh/.zshenv` – always-loaded env vars
- `zsh/.zprofile` – login-shell setup
- `zsh/.zshrc` – interactive shell config
- `zsh/.zlogin` – post-login hook

## Aliases

### Directory Navigation
- `..` – Navigate to parent directory

### File Listing
- `ll` – List files with details (`ls -lah`)
- `la` – List all files with details (`ls -la`)
- `l` – List files (`ls -lh`)

### File Operations
- `cp` – Copy with interactive prompt (`cp -i`)
- `mv` – Move with interactive prompt (`mv -i`)
- `rm` – Remove with interactive prompt (`rm -i`)

### File Finding
- `ff` – Find files by name (usage: `ff "*.js"`)
- `fd` – Find directories by name (usage: `fd "node_modules"`)

### Development Tools

#### Cursor Editor
- `c` – Open current directory in Cursor
- `c.` – Open current directory in Cursor

#### Claude
- `claudeauto` – Run Claude with Chrome, Opus model, and bypass permissions

#### Python
- `venv` – Create Python virtual environment
- `activate` – Activate virtual environment in current directory

#### Node.js / npm
- `ni` – npm install
- `nu` – npm uninstall
- `ns` – npm start
- `nt` – npm test
- `nb` – npm run build

#### pnpm
- `pn` – pnpm
- `pni` – pnpm install
- `pna` – pnpm add
- `pnr` – pnpm run

#### PostgreSQL
- `psql-start` – Start PostgreSQL server
- `psql-stop` – Stop PostgreSQL server

### System Utilities

#### macOS Finder
- `showfiles` – Show hidden files in Finder
- `hidefiles` – Hide files in Finder

#### Process Management
- `ports` – Show listening ports

#### Disk Usage
- `duh` – Human-readable disk usage, sorted
- `dfh` – Human-readable disk space

#### Network
- `myip` – Get public IP address
- `localip` – Get local IP address

### Utility
- `cls` – Clear screen
- `h` – Show history
- `hg` – Search history (usage: `hg "search term"`)

### Configuration
- `zshrc` – Edit `.zshrc` in Cursor
- `zshenv` – Edit `.zshenv` in Cursor
- `zprofile` – Edit `.zprofile` in Cursor
- `reload` – Reload shell configuration

## Quick setup / sync script

Run the bootstrap script directly from GitHub (the timestamp busts CDN cache so you always get the latest file):

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/mitchellfyi/dotfiles/main/scripts/setup.sh?$(date +%s)")
```

What it does:

1. Installs Xcode CLT, Homebrew, `zsh`, and `git` if missing.
2. Ensures `~/Dropbox/work/dotfiles` exists, cloning or updating `git@github.com:mitchellfyi/dotfiles.git`.
3. Writes loader files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.zlogin`) that point at the absolute Dropbox path so every new terminal (regardless of working directory) sources the right config.
4. Sets `/bin/zsh` as the default login shell (if not already). After the script finishes, open a new terminal (or run `exec zsh -l`) to start using the synced config.

You can override the defaults by setting `REPO_URL` or `TARGET_DIR` before running the command, e.g.

```bash
REPO_URL="https://github.com/mitchellfyi/dotfiles.git" TARGET_DIR="$HOME/Dropbox/work/dotfiles" \
  bash <(curl -fsSL "https://raw.githubusercontent.com/mitchellfyi/dotfiles/main/scripts/setup.sh?$(date +%s)")
```

After bootstrap, edit/commit files inside `~/Dropbox/work/dotfiles` (for example `~/Dropbox/work/dotfiles/zsh/.zshrc`). The loader files in `$HOME` simply source the synced versions and should rarely change.
