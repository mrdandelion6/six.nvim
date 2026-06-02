#!/bin/bash
# bootstrap.sh — neovim dev environment setup
# supports: arch, ubuntu/debian, rocky/rhel
# works with and without sudo

set -e

# ============================================================
#  VERSIONS
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/versions.env" ]; then
  source "$SCRIPT_DIR/versions.env"
else
  echo "[warn] versions.env not found, using built-in defaults"
  NVIM_VERSION="0.11.0"
  RG_VERSION="14.1.1"
  STYLUA_VERSION="2.1.0"
  QUARTO_VERSION="1.6.40"
  ZOXIDE_VERSION="0.9.4"
fi

# ============================================================
#  COLORS
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[info]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; }

# ============================================================
#  DETECT DISTRO
# ============================================================
detect_distro() {
  if [ -f /etc/arch-release ]; then
    DISTRO="arch"
  elif [ -f /etc/debian_version ]; then
    DISTRO="ubuntu"
  elif [ -f /etc/rocky-release ] || [ -f /etc/redhat-release ]; then
    DISTRO="rocky"
  else
    error "Unsupported distro. Exiting."
    exit 1
  fi
  info "detected distro: $DISTRO"
}

# ============================================================
#  DETECT SUDO
# ============================================================
detect_sudo() {
  echo "this script may need sudo for system packages."
  if sudo -v 2>/dev/null; then
    HAS_SUDO=true
    # keep sudo alive for duration of script
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    info "sudo available"
  else
    HAS_SUDO=false
    warn "sudo failed or unavailable — installing to ~/.local/ where possible"
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

# ============================================================
#  PROMPTS
# ============================================================
prompt_yes_no() {
  while true; do
    read -rp "$1 [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "please answer y or n" ;;
    esac
  done
}

# ============================================================
#  UPDATE LOCAL SETTINGS
# ============================================================
update_local_settings() {
  local key="$1"
  local value="$2"
  local settings="$HOME/.config/nvim/.localsettings.json"

  if [ ! -f "$settings" ]; then
    warn "local settings file not found at $settings — skipping"
    return
  fi

  # use python3 to safely edit the json
  python3 -c "
import json
with open('$settings', 'r') as f:
    data = json.load(f)
data['$key'] = $value
with open('$settings', 'w') as f:
    json.dump(data, f, indent=2)
"
  success "set $key = $value in local settings"
}

# ============================================================
#  INSTALL: BASE SYSTEM DEPS
# ============================================================
install_base_deps() {
  info "installing base dependencies..."
  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)
        sudo pacman -S --noconfirm --needed curl unzip git make yarn
        ;;
      ubuntu)
        sudo apt update -y
        sudo apt install -y curl unzip git make
        if ! command -v yarn &>/dev/null; then
          sudo npm install -g yarn 2>/dev/null || true
        fi
        ;;
      rocky)
        sudo dnf install -y curl unzip git make
        sudo dnf install -y epel-release 2>/dev/null || true
        ;;
    esac
  else
    for dep in curl unzip git; do
      if ! command -v "$dep" &>/dev/null; then
        error "$dep is required but not installed and you have no sudo. please ask your sysadmin."
        exit 1
      fi
    done
    warn "skipping system dep install (no sudo) — assuming curl/unzip/git are present"
  fi
  success "base deps ready"
}

# ============================================================
#  INSTALL: NEOVIM
# ============================================================
install_neovim() {
  if command -v nvim &>/dev/null; then
    CURRENT=$(nvim --version 2>/dev/null | head -1)
    info "nvim already installed: $CURRENT"
    if ! prompt_yes_no "reinstall/update nvim?"; then
      return
    fi
  fi

  if [ "$HAS_SUDO" = true ]; then
    install_neovim_tarball
  else
    install_neovim_appimage
  fi
}

install_neovim_tarball() {
  info "installing neovim v${NVIM_VERSION} from tarball..."
  TMP=$(mktemp -d)
  curl --connect-timeout 10 --max-time 120 -L --progress-bar \
    "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    -o "$TMP/nvim.tar.gz"
  tar xf "$TMP/nvim.tar.gz" -C "$TMP"
  sudo rm -rf /opt/nvim
  sudo mv "$TMP/nvim-linux-x86_64" /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$TMP"
  success "neovim installed: $(nvim --version | head -1)"
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
  ln -sf "$HOME/.local/nvim-appimage/usr/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$TMP"
  success "neovim installed: $(nvim --version | head -1)"
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
#  INSTALL: NODE (via nvm — always no-sudo)
# ============================================================
install_node() {
  if command -v node &>/dev/null; then
    success "node already installed: $(node --version)"
    return
  fi

  info "installing node via nvm..."
  curl --connect-timeout 10 --max-time 60 -o- \
    https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  success "node installed: $(node --version)"
}

# ============================================================
#  INSTALL: PYTHON
# ============================================================
install_python() {
  if command -v python3 &>/dev/null; then
    success "python3 already available: $(python3 --version)"
    return
  fi

  info "installing python3..."
  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)   sudo pacman -S --noconfirm python python-pip ;;
      ubuntu) sudo apt install -y python3 python3-pip python3-venv ;;
      rocky)  sudo dnf install -y python3 python3-pip ;;
    esac
  else
    error "python3 not found and no sudo. please ask your sysadmin."
    exit 1
  fi
  success "python3 installed"
}

# ============================================================
#  INSTALL: RIPGREP
# ============================================================
install_ripgrep() {
  if command -v rg &>/dev/null; then
    success "ripgrep already installed"
    return
  fi

  info "installing ripgrep..."
  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)   sudo pacman -S --noconfirm ripgrep ;;
      ubuntu) sudo apt install -y ripgrep ;;
      rocky)
        sudo dnf install -y ripgrep 2>/dev/null || {
          warn "ripgrep not in repos, installing from binary..."
          install_ripgrep_binary
        }
        ;;
    esac
  else
    install_ripgrep_binary
  fi
  success "ripgrep installed"
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
  mv "$TMP/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/rg"
  rm -rf "$TMP"
}

# ============================================================
#  INSTALL: ZOXIDE
# ============================================================
install_zoxide() {
  if command -v zoxide &>/dev/null; then
    success "zoxide already installed"
    return
  fi

  info "installing zoxide v${ZOXIDE_VERSION}..."
  if [ "$HAS_SUDO" = true ] && [ "$DISTRO" = "arch" ]; then
    sudo pacman -S --noconfirm zoxide
  elif [ "$HAS_SUDO" = true ] && [ "$DISTRO" = "ubuntu" ]; then
    sudo apt install -y zoxide
  else
    # download binary directly — avoids github API rate limit
    TMP=$(mktemp -d)
    URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    curl --connect-timeout 10 --max-time 60 -L --progress-bar "$URL" -o "$TMP/zoxide.tar.gz"
    if ! tar tzf "$TMP/zoxide.tar.gz" &>/dev/null; then
      error "zoxide download failed or corrupted"
      rm -rf "$TMP"
      return 1
    fi
    tar xf "$TMP/zoxide.tar.gz" -C "$TMP"
    mv "$TMP/zoxide" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/zoxide"
    rm -rf "$TMP"
  fi
  success "zoxide installed"
}

# ============================================================
#  INSTALL: TREE-SITTER CLI
# ============================================================
install_tree_sitter() {
  if command -v tree-sitter &>/dev/null; then
    success "tree-sitter-cli already installed"
    return
  fi

  info "installing tree-sitter-cli via npm..."
  npm install --prefix "$HOME/.local" tree-sitter-cli
  success "tree-sitter-cli installed"
}

# ============================================================
#  INSTALL: STYLUA
# ============================================================
install_stylua() {
  if command -v stylua &>/dev/null; then
    success "stylua already installed"
    return
  fi

  info "installing stylua v${STYLUA_VERSION}..."
  TMP=$(mktemp -d)
  curl --connect-timeout 10 --max-time 60 -L --progress-bar \
    "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/stylua-linux-x86_64.zip" \
    -o "$TMP/stylua.zip"
  unzip -q "$TMP/stylua.zip" -d "$TMP"

  if [ "$HAS_SUDO" = true ]; then
    sudo mv "$TMP/stylua" /usr/local/bin/
    sudo chmod +x /usr/local/bin/stylua
  else
    mv "$TMP/stylua" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/stylua"
  fi

  rm -rf "$TMP"
  success "stylua installed"
}

# ============================================================
#  INSTALL: LATEX SUPPORT
# ============================================================
install_latex() {
  info "installing latex dependencies..."
  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)
        sudo pacman -S --noconfirm texlive zathura zathura-pdf-mupdf inkscape
        ;;
      ubuntu)
        sudo apt install -y texlive-full zathura zathura-pdf-mupdf inkscape
        ;;
      rocky)
        sudo dnf install -y texlive zathura inkscape
        warn "zathura-pdf-mupdf may need manual install on rocky"
        ;;
    esac
    success "latex deps installed"
  else
    warn "latex deps require sudo — skipping"
    warn "you'll need texlive, zathura, and inkscape installed by your sysadmin"
  fi

  update_local_settings "molten_support" "True"
}

# ============================================================
#  INSTALL: MOLTEN / JUPYTER SUPPORT
# ============================================================
install_molten() {
  info "installing molten/jupyter dependencies..."

  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)
        sudo pacman -S --noconfirm luarocks imagemagick lua51
        ;;
      ubuntu)
        sudo apt install -y luarocks imagemagick libmagick++-dev \
          libmagickwand-dev lua5.1 liblua5.1-0-dev
        ;;
      rocky)
        sudo dnf install -y luarocks ImageMagick ImageMagick-devel lua lua-devel
        ;;
    esac
  else
    warn "imagemagick/luarocks require sudo — skipping system packages"
    warn "image.nvim may not work without them"
  fi

  info "setting up python venv for molten at ~/.envs/neovim..."
  mkdir -p "$HOME/.envs"
  python3 -m venv "$HOME/.envs/neovim"
  source "$HOME/.envs/neovim/bin/activate"
  pip install --quiet \
    pynvim jupyter_client cairosvg plotly kaleido \
    pnglatex pyperclip nbformat jupytext jupyter jupyterlab
  deactivate
  success "python venv set up at ~/.envs/neovim"

  info "installing quarto v${QUARTO_VERSION}..."
  TMP=$(mktemp -d)
  if [ "$HAS_SUDO" = true ] && [ "$DISTRO" = "ubuntu" ]; then
    curl --connect-timeout 10 --max-time 120 -L --progress-bar \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
      -o "$TMP/quarto.deb"
    sudo dpkg -i "$TMP/quarto.deb"
  elif [ "$DISTRO" = "arch" ] && command -v yay &>/dev/null; then
    yay -S --noconfirm quarto-cli
  else
    curl --connect-timeout 10 --max-time 120 -L --progress-bar \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" \
      -o "$TMP/quarto.tar.gz"
    tar xf "$TMP/quarto.tar.gz" -C "$TMP"
    mv "$TMP/quarto-${QUARTO_VERSION}/bin/quarto" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/quarto"
  fi
  rm -rf "$TMP"
  success "quarto installed"

  # set .localsettings.json flag for molten_support
  update_local_settings "molten_support" "True"
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
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}   neovim bootstrap script              ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  detect_distro
  detect_sudo

  install_base_deps
  install_neovim
  install_node
  install_python
  install_ripgrep
  install_zoxide
  install_tree_sitter
  install_stylua

  echo ""
  if prompt_yes_no "install latex support (texlive, zathura, inkscape)?"; then
    install_latex
  else
    info "skipping latex"
  fi

  echo ""
  INSTALLED_MOLTEN=false
  if prompt_yes_no "install molten/jupyter support (imagemagick, python venv, quarto)?"; then
    install_molten
    INSTALLED_MOLTEN=true
  else
    info "skipping molten"
  fi

  echo ""
  clone_config

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
