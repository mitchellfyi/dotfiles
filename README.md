# Dotfiles

Configuration lives in `~/Dropbox/work/dotfiles` so iCloud/Time Machine stay clean while Dropbox keeps it synced. `$HOME` only holds thin loaders that source the tracked files.

## Structure

- `zsh/.zshenv` – always-loaded env vars
- `zsh/.zprofile` – login-shell setup
- `zsh/.zshrc` – interactive shell config
- `zsh/.zlogin` – post-login hook
- `cursor/keybindings.json` – Cursor keybinding overrides (symlinked into `~/Library/Application Support/Cursor/User/`)
- `git/.gitconfig` – global git config (symlinked to `~/.gitconfig`)
- `git/.gitignore_global` – global gitignore (symlinked to `~/.gitignore_global`)
- `mcp/copilot-mcp-config.json` – MCP servers for GitHub Copilot CLI (symlinked to `~/.copilot/mcp-config.json`)
- `scripts/setup.sh` – bootstrap script

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
- `fd` – Modern alternative to `find` (installed by Homebrew, usage: `fd pattern`)
- `rg` – ripgrep, fast recursive grep (usage: `rg pattern`)

### Development Tools

#### Cursor Editor
- `c` – Open current directory in Cursor
- `c.` – Open current directory in Cursor

#### Claude
- `claudeauto` / `cla` – Run Claude with Chrome, Opus model, max effort, and bypass permissions

#### Codex
- `codexauto` / `coa` – Run Codex with bypass approvals and extra-high reasoning effort

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

#### Docker
- `dockerprune` – Remove all unused containers, images, networks, and volumes (`docker system prune -a --volumes`)

### Configuration
- `dotfiles` – Open dotfiles directory in Cursor
- `zshrc` – Edit `.zshrc` in Cursor
- `zshenv` – Edit `.zshenv` in Cursor
- `zprofile` – Edit `.zprofile` in Cursor
- `reload` – Reload shell configuration

## Runtime Management

Language runtimes are managed by [mise](https://mise.jdx.dev/), installed via Homebrew. The following are configured as global defaults:

| Runtime | Version |
|---------|---------|
| Node.js | LTS     |
| Ruby    | latest  |
| Python  | latest  |

mise is activated for every interactive shell via `.zshrc`. Runtimes are stored in `~/.local/share/mise/installs/` and shims are injected into `PATH` at shell startup.

The following global CLIs are installed via npm after runtimes are set up:

| CLI | Package |
|-----|---------|
| Codex CLI | `@openai/codex` |
| pnpm | `pnpm` |

Additional CLIs installed by the bootstrap script:

- **Claude Code** — installed via the official native installer (`curl -fsSL https://claude.ai/install.sh | bash`).
- **GitHub Copilot CLI** — installed as a `gh` extension (`gh extension install github/gh-copilot`). Run `gh auth login` afterwards to use it.
- **Cursor** — installed via Homebrew cask. The CLI is symlinked into `~/.local/bin/cursor` so the `c`, `dotfiles`, and `EDITOR` aliases work.

## Apps and Services Installed

GUI apps (via Homebrew cask):

- **Cursor** — primary editor.
- **Postgres.app** — PostgreSQL with menu-bar control. Data dir under `~/Library/Application Support/Postgres/var-N`.
- **Docker Desktop** — launch once to accept terms and start the daemon.

Background services (via Homebrew formula + `brew services`):

- **Redis** — auto-started at login.
- **MySQL** — auto-started at login. Run `mysql_secure_installation` once to set the root password.

Dev CLIs installed by Homebrew:

`ripgrep`, `fd`, `jq`, `bat`, `eza`, `fzf`, `tldr`, `tree`, `htop`, `wget`, `httpie`.

Shell QoL plugins:

- `zsh-autosuggestions` — ghost-completes commands from history; press → to accept.
- `zsh-syntax-highlighting` — colors invalid commands red as you type.
- `fzf` — Ctrl+R for fuzzy history search, Ctrl+T for fuzzy file search.

## MCP Servers (AI Agent Tooling)

The bootstrap registers a common set of [Model Context Protocol](https://modelcontextprotocol.io/) servers across all three AI agent CLIs (Claude Code, Codex CLI, GitHub Copilot CLI).

| MCP | URL / install | Auth |
|-----|---------------|------|
| Vercel | `https://mcp.vercel.com` | OAuth |
| Linear | `https://mcp.linear.app/mcp` | OAuth |
| Figma | `https://mcp.figma.com/mcp` | OAuth |
| Datadog | `https://mcp.datadoghq.com/api/unstable/mcp-server/mcp` | OAuth |
| GitHub | `https://api.githubcopilot.com/mcp` | PAT (Copilot CLI ships this built-in) |
| Sentry | `https://mcp.sentry.dev/mcp` | OAuth |
| DigitalOcean | `https://apps.mcp.digitalocean.com/mcp` | PAT |
| Hetzner | stdio: `uvx --from git+https://github.com/dkruyt/mcp-hetzner.git mcp-hetzner` (third-party) | `HCLOUD_TOKEN` env var |

OAuth servers prompt for sign-in on first connection — no setup needed at install time. PAT-required servers (GitHub, DigitalOcean) need a token added before they'll connect; re-add with `claude mcp add ... --header "Authorization: Bearer ..."` or edit `~/.codex/config.toml`.

**Hetzner** uses the community-built `dkruyt/mcp-hetzner` server (no official Hetzner MCP exists). Put `HCLOUD_TOKEN=...` in `~/Dropbox/work/dotfiles/.env` (gitignored) — the `.zshrc` exports it on shell startup and the MCP subprocess inherits it from the AI CLI's environment.

Storage by tool:

- **Claude Code**: `~/.claude.json` (managed via `claude mcp add/remove/list`).
- **Codex CLI**: `~/.codex/config.toml` (managed via `codex mcp add/remove/list`).
- **GitHub Copilot CLI**: `~/.copilot/mcp-config.json` — symlinked to `mcp/copilot-mcp-config.json` in this repo, so edits there sync across machines.

**Skipped MCPs:**

- **Dokku** — only a third-party Linux binary exists; no Mac build.
- **Segment** — no official server; only third-party / Pipedream wrappers.
- **Grafana** — official server is local-only and requires `GRAFANA_URL` + service-account token at install time. To add manually after configuring those env vars: `claude mcp add -s user grafana -- uvx mcp-grafana` (with `-e GRAFANA_URL=… -e GRAFANA_SERVICE_ACCOUNT_TOKEN=…`).

To add or update a runtime version:

```bash
mise use --global node@lts    # or ruby@latest, python@latest
```

## Quick setup / sync script

Run the bootstrap script directly from GitHub (the timestamp busts CDN cache so you always get the latest file):

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/mitchellfyi/dotfiles/main/scripts/setup.sh?$(date +%s)")
```

What it does:

1. Installs Xcode CLT and Homebrew if missing.
2. Installs Homebrew core packages: `zsh`, `git`, `gh`, `gnupg`, `mise`, `libyaml`.
3. Installs dev CLIs: `ripgrep`, `fd`, `jq`, `bat`, `eza`, `fzf`, `tldr`, `tree`, `htop`, `wget`, `httpie`, plus `zsh-autosuggestions` and `zsh-syntax-highlighting`.
4. Installs database formulas: `redis`, `mysql`. Starts both as `brew services`.
5. Installs casks: Cursor, Postgres.app, Docker Desktop. Symlinks Cursor's CLI into `~/.local/bin/cursor`. Runs fzf's shell-integration installer.
6. Installs language runtimes via mise: Node.js (LTS), Ruby (latest), Python (latest).
7. Installs global npm CLIs: `@openai/codex`, `@github/copilot`, and `pnpm` (plus latest `npm`).
8. Installs Claude Code via the official native installer.
9. Installs the `gh-copilot` extension for GitHub Copilot CLI.
10. Ensures `~/Dropbox/work/dotfiles` exists, cloning or updating `git@github.com:mitchellfyi/dotfiles.git`.
11. Writes loader files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.zlogin`) that point at the absolute Dropbox path so every new terminal (regardless of working directory) sources the right config.
12. Sets `/bin/zsh` as the default login shell (if not already).
13. Symlinks `cursor/keybindings.json`, `git/.gitconfig`, `git/.gitignore_global` into `$HOME` (any existing files are backed up first).
14. If `~/.ssh/id_ed25519` doesn't exist, generates a new ed25519 SSH key (using the email from `.gitconfig`) and adds it to the macOS keychain. The public key is printed at the end so you can paste it into GitHub.
15. Registers MCP servers in Claude Code and Codex CLI (Vercel, Linear, Figma, Datadog, GitHub, Sentry, DigitalOcean, Hetzner) and symlinks the GitHub Copilot CLI MCP config from `mcp/copilot-mcp-config.json`.
16. Applies macOS preferences:
    - Disable natural mouse/trackpad scrolling
    - Show hidden files and file extensions in Finder
    - Show full POSIX path in Finder title bar
    - Don't auto-rearrange Mission Control Spaces by most-recent use
    - Faster key repeat; disable press-and-hold accent menu
    - Disable autocorrect, smart quotes/dashes/periods, auto-capitalization
    - Save dialogs default to expanded view
    - Screenshots saved as PNG to `~/Screenshots/`

After the script finishes, manual follow-ups:

- Open a new terminal (or `exec zsh -l`) to load the synced config.
- Sign out and back in for the natural-scroll change to take effect.
- Restart Cursor for the keybindings symlink to take effect.
- Launch Docker Desktop once to accept terms and start the daemon.
- Run `mysql_secure_installation` to set the MySQL root password.
- Run `gh auth login` to authenticate gh-copilot.
- If a new SSH key was generated, add it to GitHub at <https://github.com/settings/ssh/new>.

You can override the defaults by setting `REPO_URL` or `TARGET_DIR` before running the command, e.g.

```bash
REPO_URL="https://github.com/mitchellfyi/dotfiles.git" TARGET_DIR="$HOME/Dropbox/work/dotfiles" \
  bash <(curl -fsSL "https://raw.githubusercontent.com/mitchellfyi/dotfiles/main/scripts/setup.sh?$(date +%s)")
```

After bootstrap, edit/commit files inside `~/Dropbox/work/dotfiles` (for example `~/Dropbox/work/dotfiles/zsh/.zshrc`). The loader files in `$HOME` simply source the synced versions and should rarely change.
