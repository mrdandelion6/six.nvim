#!/bin/bash
# bootstrap.sh — neovim dev environment setup
# supports: arch, ubuntu/debian, rocky/rhel
# works with and without sudo
#
# usage: ./install/bootstrap.sh [--system | --local]
#   --system  arch with sudo only. missing core tools come from pacman (default there)
#   --local   missing core tools are curled into ~/.local/bin (default everywhere else)
# see install/README.md for what each mode does with tools that are already installed

set -e

# ============================================================
#  INSTALL: BASE SYSTEM DEPS
# ============================================================
# always from the package manager , in both modes. without sudo they can't be
# installed , so we only check for them
install_base_deps() {
  info "installing base dependencies..."
  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)
        pacman_install curl tar gzip unzip git make base-devel python wl-clipboard xclip || exit 1
        ;;
      ubuntu)
        sudo apt update -y
        sudo apt install -y curl tar gzip unzip git make gcc python3 wl-clipboard xclip
        ;;
      rocky)
        sudo dnf install -y curl tar gzip unzip git make gcc python3
        sudo dnf install -y epel-release 2>/dev/null || true
        sudo dnf install -y wl-clipboard xclip 2>/dev/null || true
        ;;
    esac
  fi
  check_base_deps
  success "base deps ready"
}

# stop if something essential is missing , warn for the rest
check_base_deps() {
  local missing=() dep

  for dep in curl tar gzip unzip git python3; do
    command -v "$dep" &>/dev/null || missing+=("$dep")
  done
  # treesitter parsers are compiled with a c compiler
  if ! command -v cc &>/dev/null && ! command -v gcc &>/dev/null; then
    missing+=("gcc")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    error "missing required tools: ${missing[*]}"
    local pkgs="${missing[*]}"
    case $DISTRO in
      arch)   echo "  ask an admin to run: sudo pacman -S ${pkgs//python3/python}" ;;
      ubuntu) echo "  ask an admin to run: sudo apt install $pkgs" ;;
      rocky)  echo "  ask an admin to run: sudo dnf install $pkgs" ;;
    esac
    exit 1
  fi

  if ! command -v make &>/dev/null; then
    warn "make not found — plugins that build something (e.g. telescope-fzf-native) will fail"
    note "make is missing. plugins that build something (e.g. telescope-fzf-native) will fail until it's installed"
  fi
  if ! command -v wl-copy &>/dev/null && ! command -v xclip &>/dev/null; then
    warn "no wl-clipboard or xclip — the system clipboard won't work outside SSH"
    note "no wl-clipboard or xclip found. nvim can't reach the system clipboard (OSC 52 over SSH still works)"
  fi
}

# ============================================================
#  INSTALL: NEOVIM
# ============================================================
install_neovim() {
  local path have owner
  if path=$(command -v nvim); then
    have=$(tool_version nvim)
    owner=$(tool_owner "$path")
    if version_ge "$have" "$NVIM_MIN"; then
      success "nvim $have already installed ($owner)"
      return
    fi
    if [ "$owner" = "pacman" ]; then
      warn_pacman_outdated nvim "$have" "$NVIM_MIN"
      return
    fi
    warn "nvim $have at $path ($owner) is older than the minimum $NVIM_MIN — installing a newer one"
  fi

  if [ "$MODE" = "system" ]; then
    info "installing neovim with pacman..."
    pacman_install neovim || return 0
    check_winner nvim /usr/bin/nvim
    have=$(tool_version /usr/bin/nvim)
    if ! version_ge "$have" "$NVIM_MIN"; then
      warn_pacman_outdated nvim "$have" "$NVIM_MIN"
    fi
    success "neovim installed: $have"
  else
    install_neovim_appimage
    if [ -x "$HOME/.local/bin/nvim" ]; then
      check_winner nvim "$HOME/.local/bin/nvim"
    fi
  fi
}

install_neovim_appimage() {
  info "installing neovim v${NVIM_VERSION} via appimage (no sudo)..."
  TMP=$(mktemp -d)
  OLDDIR=$(pwd)

  curl --connect-timeout 10 --max-time 120 -L --progress-bar \
    "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.appimage" \
    -o "$TMP/nvim.appimage"
  chmod +x "$TMP/nvim.appimage"

  # extract instead of running directly — avoids needing FUSE
  cd "$TMP" && ./nvim.appimage --appimage-extract > /dev/null 2>&1
  cd "$OLDDIR"

  # test if the extracted binary actually runs (glibc compat check)
  if ! "$TMP/squashfs-root/usr/bin/nvim" --version &>/dev/null; then
    warn "appimage failed — likely glibc too old ($(ldd --version 2>&1 | head -1))"
    rm -rf "$TMP"

    echo ""
    if prompt_yes_no "build neovim from source instead? (requires gcc + cmake, takes ~10 mins)"; then
      install_neovim_from_source
    else
      warn "skipping neovim install — you can build manually later:"
      warn "  make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=~/.local"
    fi
    return
  fi

  rm -rf "$HOME/.local/nvim-appimage"
  mv "$TMP/squashfs-root" "$HOME/.local/nvim-appimage"
  # remove first so we never write through an existing symlink
  rm -f "$HOME/.local/bin/nvim"
  ln -s "$HOME/.local/nvim-appimage/usr/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$TMP"
  success "neovim installed: $("$HOME/.local/bin/nvim" --version | head -1)"
}

install_neovim_from_source() {
  if ! command -v gcc &>/dev/null; then
    error "gcc not found — cannot build from source"
    return 1
  fi
  if ! command -v cmake &>/dev/null; then
    error "cmake not found — cannot build from source"
    return 1
  fi


  local SRC_VERSION="$NVIM_VERSION"
  info "building neovim v${NVIM_VERSION} from source (this will take ~10 minutes)..."

  TMP=$(mktemp -d)
  OLDDIR=$(pwd)

  curl --connect-timeout 10 --max-time 120 -L --progress-bar \
    "https://github.com/neovim/neovim/archive/refs/tags/v${SRC_VERSION}.tar.gz" \
    -o "$TMP/nvim-src.tar.gz"

  if ! tar tzf "$TMP/nvim-src.tar.gz" &>/dev/null; then
    error "neovim source download failed or corrupted"
    rm -rf "$TMP"
    cd "$OLDDIR"
    return 1
  fi

  tar xf "$TMP/nvim-src.tar.gz" -C "$TMP"
  cd "$TMP/neovim-${SRC_VERSION}"

  info "running make... (grab a coffee)"
  # USE_BUNDLED_LUAROCKS=OFF avoids luarocks manifest issues on old systems
  if make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local" \
      USE_BUNDLED_LUAROCKS=OFF 2>&1 | grep -E "^\[|error:"; then
    info "build with USE_BUNDLED_LUAROCKS=OFF succeeded"
  else
    warn "retrying without USE_BUNDLED_LUAROCKS=OFF..."
    make clean 2>/dev/null || true
    make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local" 2>&1 \
      | grep -E "^\[|error:" || true
  fi

  make install

  cd "$OLDDIR"
  rm -rf "$TMP"

  if command -v nvim &>/dev/null; then
    success "neovim installed: $(nvim --version | head -1)"
  else
    error "build completed but nvim not found — check ~/.local/bin is on PATH"
  fi
}

# ============================================================
#  INSTALL: NODE + NPM
# ============================================================
# an existing node is never replaced , other projects may rely on its version.
# if it's too old we only say so
install_node() {
  # node from nvm isn't on PATH until nvm.sh is sourced
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh" || true
  fi

  local path have owner
  if path=$(command -v node); then
    have=$(tool_version node)
    owner=$(tool_owner "$path")
    if [ "${have%%.*}" -ge "$NODE_MIN_MAJOR" ]; then
      success "node $have already installed ($owner)"
      ensure_npm "$owner"
      return
    fi
    case $owner in
      pacman)
        warn_pacman_outdated node "$have" "$NODE_MIN_MAJOR"
        ;;
      nvm)
        warn "node $have (nvm) is older than the minimum $NODE_MIN_MAJOR"
        note "your nvm node is $have , older than the minimum $NODE_MIN_MAJOR. run: nvm install --lts && nvm alias default 'lts/*'"
        ;;
      *)
        warn "node $have at $path ($owner) is older than the minimum $NODE_MIN_MAJOR"
        note "node $have at $path ($owner) is older than the minimum $NODE_MIN_MAJOR. bootstrap leaves node alone since other projects may rely on it. upgrade it yourself , e.g. with nvm"
        ;;
    esac
    return
  fi

  if [ "$MODE" = "system" ]; then
    info "installing node with pacman..."
    pacman_install nodejs npm || return 0
  else
    info "installing node via nvm v${NVM_VERSION}..."
    curl --connect-timeout 10 --max-time 60 -o- \
      "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
    \. "$NVM_DIR/nvm.sh"
    nvm install --lts
  fi
  success "node installed: $(node --version)"
}

ensure_npm() {
  local owner="$1"
  if command -v npm &>/dev/null; then
    return
  fi
  if [ "$MODE" = "system" ] && [ "$owner" = "pacman" ]; then
    info "installing npm with pacman..."
    pacman_install npm || true
  else
    warn "node is installed but npm isn't"
    note "npm is missing. mason needs it for npm based language servers. install it the same way your node was installed"
  fi
}

# ============================================================
#  INSTALL: YARN
# ============================================================
install_yarn() {
  if command -v yarn &>/dev/null; then
    success "yarn already installed"
    return
  fi

  if [ "$MODE" = "system" ]; then
    info "installing yarn with pacman..."
    pacman_install yarn || return 0
  elif command -v npm &>/dev/null && [ -w "$(npm prefix -g)" ]; then
    info "installing yarn with npm..."
    npm install -g yarn
  else
    warn "can't install yarn without a user writable npm (e.g. from nvm) — skipping"
    note "yarn was not installed. install it with npm once you have a user writable npm (e.g. node from nvm)"
    return
  fi
  success "yarn installed"
}

# ============================================================
#  INSTALL: SIMPLE TOOLS
# ============================================================
# for tools where any version works: if it exists , keep it. if not , pacman in
# system mode , or the pinned binary in ~/.local/bin in local mode
# $1: command , $2: pacman package , $3: function that downloads the binary
install_simple() {
  local cmd="$1" pkg="$2" fetch="$3" path
  if path=$(command -v "$cmd"); then
    success "$cmd already installed: $(describe_tool "$path")"
    return
  fi

  info "installing $cmd..."
  if [ "$MODE" = "system" ]; then
    pacman_install "$pkg" || return 0
  else
    "$fetch"
  fi
  success "$cmd installed"
}

install_fd() {
  # debian's package names it fdfind
  if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    success "fd already installed as fdfind , linked to ~/.local/bin/fd"
    return
  fi
  install_simple fd fd install_fd_binary
}

install_fd_binary() {
  TMP=$(mktemp -d)
  info "downloading fd v${FD_VERSION}..."
  URL="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/fd.tar.gz"
  if ! tar tzf "$TMP/fd.tar.gz" &>/dev/null; then
    error "fd download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  tar xf "$TMP/fd.tar.gz" -C "$TMP"
  rm -f "$HOME/.local/bin/fd"
  mv "$TMP/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/fd"
  rm -rf "$TMP"
}

install_fzf_binary() {
  TMP=$(mktemp -d)
  info "downloading fzf v${FZF_VERSION}..."
  URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
  curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/fzf.tar.gz"
  if ! tar tzf "$TMP/fzf.tar.gz" &>/dev/null; then
    error "fzf download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  tar xf "$TMP/fzf.tar.gz" -C "$TMP"
  rm -f "$HOME/.local/bin/fzf"
  mv "$TMP/fzf" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/fzf"
  rm -rf "$TMP"
}

install_ripgrep_binary() {
  TMP=$(mktemp -d)
  info "downloading ripgrep v${RG_VERSION}..."
  URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/rg.tar.gz"
  if ! tar tzf "$TMP/rg.tar.gz" &>/dev/null; then
    error "ripgrep download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  tar xf "$TMP/rg.tar.gz" -C "$TMP"
  rm -f "$HOME/.local/bin/rg"
  mv "$TMP/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/rg"
  rm -rf "$TMP"
}

install_zoxide_binary() {
  # download binary directly — avoids github API rate limit
  TMP=$(mktemp -d)
  info "downloading zoxide v${ZOXIDE_VERSION}..."
  URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/zoxide.tar.gz"
  if ! tar tzf "$TMP/zoxide.tar.gz" &>/dev/null; then
    error "zoxide download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  tar xf "$TMP/zoxide.tar.gz" -C "$TMP"
  rm -f "$HOME/.local/bin/zoxide"
  mv "$TMP/zoxide" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/zoxide"
  rm -rf "$TMP"
}

install_uv_binary() {
  TMP=$(mktemp -d)
  info "downloading uv v${UV_VERSION}..."
  URL="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz"
  curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/uv.tar.gz"
  if ! tar tzf "$TMP/uv.tar.gz" &>/dev/null; then
    error "uv download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  tar xf "$TMP/uv.tar.gz" -C "$TMP"
  mkdir -p "$HOME/.local/bin"
  rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
  mv "$TMP/uv-x86_64-unknown-linux-musl/uv" "$TMP/uv-x86_64-unknown-linux-musl/uvx" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
  rm -rf "$TMP"
  # make it usable for the rest of this run (molten.sh needs it)
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

# ============================================================
#  INSTALL: NVIM-ONLY TOOLS (tree-sitter , stylua)
# ============================================================
# only nvim uses these , so in both modes bootstrap downloads the pinned
# version into NVIM_BIN_DIR. init.lua puts that dir first on nvim's PATH , so
# these copies always win inside nvim no matter what else is installed.
# bootstrap owns that dir , so a copy that doesn't match the pin is replaced
# $1: command , $2: pinned version , $3: function that downloads to a path
install_nvim_only_tool() {
  local cmd="$1" version="$2" fetch="$3"
  local target="$NVIM_BIN_DIR/$cmd" p

  if [ -x "$target" ] && [ "$(tool_version "$target")" = "$version" ]; then
    success "$cmd $version already in $NVIM_BIN_DIR"
  else
    info "installing $cmd v${version} to $NVIM_BIN_DIR..."
    mkdir -p "$NVIM_BIN_DIR"
    "$fetch" "$target"
    success "$cmd installed: $("$target" --version)"
  fi

  # other copies on PATH don't matter to nvim anymore
  hash -r
  for p in $(type -aP "$cmd"); do
    if [ "$(readlink -f "$p")" = "$(readlink -f "$target")" ]; then
      continue
    fi
    note "$cmd: $(describe_tool "$p") is unused by nvim , safe to remove if you don't need it for anything else: $(removal_hint "$p")"
  done
}

install_tree_sitter() {
  install_nvim_only_tool tree-sitter "$TREE_SITTER_VERSION" fetch_tree_sitter
}

fetch_tree_sitter() {
  local target="$1"
  TMP=$(mktemp -d)
  URL="https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-x64.gz"
  curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/tree-sitter.gz"
  if ! gzip -t "$TMP/tree-sitter.gz" &>/dev/null; then
    error "tree-sitter download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  # remove first so we never write through an existing symlink
  rm -f "$target"
  gunzip -c "$TMP/tree-sitter.gz" > "$target"
  chmod +x "$target"
  rm -rf "$TMP"
}

install_stylua() {
  install_nvim_only_tool stylua "$STYLUA_VERSION" fetch_stylua
}

fetch_stylua() {
  local target="$1"
  TMP=$(mktemp -d)
  curl --connect-timeout 10 --max-time 60 -L --progress-bar \
    "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/stylua-linux-x86_64.zip" \
    -o "$TMP/stylua.zip"
  if ! unzip -tq "$TMP/stylua.zip" &>/dev/null; then
    error "stylua download failed or corrupted"
    rm -rf "$TMP"
    return 1
  fi
  unzip -q "$TMP/stylua.zip" -d "$TMP"
  rm -f "$target"
  mv "$TMP/stylua" "$target"
  chmod +x "$target"
  rm -rf "$TMP"
}

# ============================================================
#  CLONE NVIM CONFIG
# ============================================================
clone_config() {
  if [ -d "$HOME/.config/nvim" ]; then
    warn "~/.config/nvim already exists — skipping clone"
    return
  fi

  read -rp "enter your nvim config git repo URL (or press enter to skip): " REPO_URL
  if [ -n "$REPO_URL" ]; then
    git clone "$REPO_URL" "$HOME/.config/nvim"
    success "nvim config cloned"
  else
    warn "skipping config clone"
  fi
}

# ============================================================
#  MAIN
# ============================================================
main() {
  local ORIG_PATH="$PATH"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/common.sh"

  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}        neovim bootstrap script         ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  detect_distro
  detect_sudo
  detect_mode "$@"

  install_base_deps
  clone_config

  install_neovim
  install_node
  install_yarn
  install_simple uv uv install_uv_binary
  install_fd
  install_simple fzf fzf install_fzf_binary
  install_simple rg ripgrep install_ripgrep_binary
  install_simple zoxide zoxide install_zoxide_binary
  install_tree_sitter
  install_stylua

  echo ""
  "$SCRIPT_DIR/latex.sh" --from-bootstrap

  echo ""
  INSTALLED_MOLTEN=false
  if "$SCRIPT_DIR/molten.sh" --from-bootstrap; then
    INSTALLED_MOLTEN=true
  else
    molten_status=$?
    if [ "$molten_status" -ne 10 ]; then
      exit "$molten_status"  # installation error
    fi
  fi

  case ":$ORIG_PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *)
      if [ "$MODE" = "local" ]; then
        note "~/.local/bin is not on your PATH. add this to your ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
      fi
      ;;
  esac
  print_notes

  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}   done!                                ${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "next steps:"
  echo "  1. source ~/.bashrc  (or open a new terminal)"
  echo "  2. open nvim — lazy will auto-install plugins"
  echo "  3. run :TSUpdate inside nvim"
  if [ "$INSTALLED_MOLTEN" = true ]; then
    echo "  4. run :UpdateRemotePlugins inside nvim for molten"
  fi
  echo ""
}

main "$@"
