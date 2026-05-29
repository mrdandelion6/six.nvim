# installation

## quick start

```bash
chmod +x install/bootstrap.sh
./install/bootstrap.sh
```

supports **Arch**, **Ubuntu/Debian**, and **Rocky/RHEL**. works with and without sudo.

---

## what gets installed

### always installed
- **neovim** — with sudo: tarball to `/opt/nvim`. without sudo: appimage to `~/.local/nvim-appimage`, or built from source if glibc is too old
- **node** — via nvm, installed to `~/.nvm` (no sudo needed)
- **python3** — system install if missing (needs sudo)
- **ripgrep** — system package manager or binary to `~/.local/bin`
- **zoxide** — system package manager or binary to `~/.local/bin`
- **tree-sitter-cli** — via npm to `~/.local`
- **stylua** — binary to `/usr/local/bin` (sudo) or `~/.local/bin` (no sudo)

### optional (prompted during install)
- **latex**: texlive, zathura, inkscape — needs sudo
- **molten/jupyter**: imagemagick, luarocks, python venv at `~/.envs/neovim`, quarto

---

## versions

all binary versions are hardcoded in `install/versions.env` to avoid github API rate limits. update this file when you want newer versions:

```bash
# install/versions.env
NVIM_VERSION="0.11.0"
RG_VERSION="14.1.1"
STYLUA_VERSION="2.1.0"
QUARTO_VERSION="1.6.40"
ZOXIDE_VERSION="0.9.4"
```

check latest releases at:
- nvim: https://github.com/neovim/neovim/releases
- ripgrep: https://github.com/BurntSushi/ripgrep/releases
- stylua: https://github.com/JohnnyMorganz/StyLua/releases
- quarto: https://github.com/quarto-dev/quarto-cli/releases
- zoxide: https://github.com/ajeetdsouza/zoxide/releases

---

## no sudo notes

without sudo everything installs to `~/.local/bin`. you need to add it to PATH manually — the script does not do this permanently. add to your `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**node** is always installed via nvm regardless of sudo — it adds itself to `~/.bashrc` automatically.

**latex and imagemagick** require sudo — they will be skipped if you don't have it.

---

## rocky / rhel notes

Rocky 8 ships with glibc 2.28 which is too old to run the prebuilt nvim appimage. the script detects this automatically and prompts to build nvim from source instead (~10 minutes). you need `gcc` and `cmake` available:

```bash
gcc --version
cmake --version
```

if the source build fails on luarocks, the script retries with `USE_BUNDLED_LUAROCKS=OFF` which fixes the luarocks manifest issue on older systems.

after a source build you need `VIMRUNTIME` set — add to your nvim wrapper function in `~/.bash_local` or `~/.bashrc`:

```bash
nvim() {
    VIMRUNTIME="$HOME/.local/share/nvim/runtime" command nvim "$@"
}
```

ripgrep is not in Rocky's default repos — the script falls back to downloading the binary automatically.

---

## post install steps

after the script finishes:

```bash
# 1. reload shell
source ~/.bashrc

# 2. open nvim — lazy will auto-install all plugins on first launch
nvim

# 3. update treesitter parsers
:TSUpdate

# 4. if you installed molten
:UpdateRemotePlugins
```

mason will automatically install all LSP servers, formatters, and linters on first launch — no manual setup needed.

---

## ssh / clipboard

clipboard over SSH works via OSC 52 — no xclip or display server needed. copy from nvim goes directly to your local clipboard through the terminal. requires a terminal that supports OSC 52 (wezterm, kitty, iTerm2).

for tmux, add to `~/.tmux.conf`:
```bash
set -g set-clipboard on
set -gq allow-passthrough on  # requires tmux 3.3+
set -g default-terminal "xterm-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
```

if you're on an old tmux (< 3.3), `allow-passthrough` won't work — image.nvim is automatically disabled inside tmux to avoid errors.

also add to `~/.bashrc` on the server:
```bash
export TERM=xterm-256color
export TERM_PROGRAM=WezTerm
```
