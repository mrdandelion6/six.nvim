# installation

## quick start

```bash
./install/bootstrap.sh            # picks the mode for you
./install/bootstrap.sh --local    # force local mode
./install/bootstrap.sh --system   # force system mode (arch with sudo only)
```

supports **Arch**, **Ubuntu/Debian**, and **Rocky/RHEL**. works with and without sudo. safe to run again to update , it never modifies or removes something that's already installed. at the end it prints a **notes** section with anything you should look at (outdated tools , leftover copies you can remove , PATH problems).

---

## modes

the mode only decides where **missing core tools** come from.

- **system mode** — default on arch with sudo. missing core tools are installed with pacman. meant for setting up your own arch machine.
- **local mode** — default everywhere else (ubuntu , rocky , or no sudo). missing core tools are downloaded with curl into `~/.local/bin`. no package manager commands for core tools , so it works the same on every distro and doesn't need sudo.

---

## what gets installed

### base deps — always the package manager

curl , tar , gzip , unzip , git , gcc , make , python3 , wl-clipboard , xclip.

- **with sudo** (any distro): installed with pacman / apt / dnf.
- **without sudo**: only checked. if curl , tar , gzip , unzip , git , python3 or a c compiler is missing , bootstrap lists all of them with the command an admin needs to run , then stops. a missing make or clipboard tool is only a warning.

### core tools

| tool | system mode (missing) | local mode (missing) | version check |
| --- | --- | --- | --- |
| nvim | pacman | appimage in `~/.local/nvim-appimage` , linked from `~/.local/bin` (built from source if glibc is too old) | `NVIM_MIN` |
| node + npm | pacman | nvm (pinned `NVM_VERSION`) in `~/.nvm` | `NODE_MIN_MAJOR` |
| yarn | pacman | `npm install -g yarn` if npm is user writable (nvm) | exists |
| uv , rg , fd , fzf , zoxide | pacman | pinned binary in `~/.local/bin` | exists |
| tree-sitter , stylua | pinned binary in the nvim-only bin dir | same | exact pin |

### nvim-only tools (tree-sitter , stylua)

only nvim uses these , so in **both modes** bootstrap downloads the version pinned in `versions.env` into:

```
~/.local/share/nvim/bootstrap/bin
```

`init.lua` puts that dir first on nvim's PATH , so these copies always win inside nvim no matter what else is installed (pacman , npm , `~/.local/bin` ...). your shell never sees them. bootstrap owns that dir , so if the copy there doesn't match the pin it gets replaced. any other copy on your PATH is listed in the notes as unused by nvim , safe to remove if you don't need it for anything else.

stylua is not installed through mason for the same reason (see `lua/plugins/language_support/conform.lua`). mason's stylua also used to get picked up as an LSP. if you still have one , `:MasonUninstall stylua`.

terminals opened inside nvim inherit nvim's PATH , so they see these copies too. if you want them in your normal shell , symlink them into `~/.local/bin`.

### when a tool is already installed

bootstrap never upgrades , modifies or removes an existing install. it only installs new copies , then checks which copy wins on PATH and reports what it did.

for **nvim** (older than `NVIM_MIN`):

| installed by | what bootstrap does |
| --- | --- |
| pacman | tells you which version is too old and to run `sudo pacman -Syu`. it won't upgrade a single package , partial upgrades aren't supported on arch |
| anything else (apt , dnf , npm , manual ...) | system mode: installs with pacman. local mode: installs the pinned version to `~/.local/bin` |

after installing , if the old copy still comes first on PATH (e.g. it's in `~/.local/bin`) , or pacman refuses because the old copy is in its way (a file in `/usr/bin` that pacman doesn't own) , the notes say what's blocking and the exact command to remove it. if the new copy wins , the old one is listed as safe to remove.

for **node** (older than `NODE_MIN_MAJOR`): bootstrap never installs a second node over an existing one , other projects may rely on its version.

| installed by | what bootstrap does |
| --- | --- |
| pacman | tells you to run `sudo pacman -Syu` |
| nvm | tells you to run `nvm install --lts && nvm alias default 'lts/*'` |
| anything else | tells you it's too old and leaves it alone |

for **uv , rg , fd , fzf , zoxide**: any version works , so an existing copy is always kept.

### optional (prompted during install)

these need the package manager , so they need sudo.

- **latex**: texlive , zathura , inkscape
- **molten/jupyter**: imagemagick , luarocks , python venv made with uv at `<venv_path>/neovim` (`venv_path` from `.localsettings.json` , default `~/.envs`) , quarto

if you didn't install these initially during `bootstrap.sh` , but change your mind later , you can just run their respective scripts:

```sh
./install/latex.sh
./install/molten.sh
```

but make sure you already set up the required deps before running these.

---

## versions

all versions live in `install/versions.env`. no github API calls , so no rate limits.

- `*_VERSION` — what gets downloaded when bootstrap curls a tool. it is not compared against what's already installed. for tree-sitter and stylua it is the exact version nvim uses.
- `*_MIN` — the oldest version the config works with. only `NVIM_MIN` and `NODE_MIN_MAJOR` exist , the other tools work with any version.

```bash
# install/versions.env
NVIM_VERSION="0.12.6"
STYLUA_VERSION="2.6.0"
TREE_SITTER_VERSION="0.27.2"
NVM_VERSION="0.40.3"
...
NVIM_MIN="0.12.0"
NODE_MIN_MAJOR="20"
```

to update tree-sitter or stylua , bump the pin and run bootstrap again. `pacman -Syu` doesn't touch them.

check latest releases at:
- nvim: https://github.com/neovim/neovim/releases
- ripgrep: https://github.com/BurntSushi/ripgrep/releases
- stylua: https://github.com/JohnnyMorganz/StyLua/releases
- quarto: https://github.com/quarto-dev/quarto-cli/releases
- zoxide: https://github.com/ajeetdsouza/zoxide/releases
- tree-sitter: https://github.com/tree-sitter/tree-sitter/releases
- uv: https://github.com/astral-sh/uv/releases
- nvm: https://github.com/nvm-sh/nvm/releases

---

## local mode notes

local mode installs to `~/.local/bin` , which must be on your PATH. bootstrap adds it for its own run , and tells you in the notes if your shell doesn't have it. add to your `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**node** comes from nvm in local mode , which adds itself to `~/.bashrc`.

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
