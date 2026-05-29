#!/bin/bash
# bootstrap.sh — neovim dev environment setup
# supports: arch, ubuntu/debian, rocky/rhel
# works with and without sudo

set -e

# ============================================================
#  COLORS
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # no color

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
    error "unsupported distro. exiting."
    exit 1
  fi
  info "Detected distro: $DISTRO"
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
  # $1 = question, returns 0 for yes, 1 for no
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
#  INSTALL: NEOVIM
# ============================================================
install_neovim() {
  if vim.fn 2>/dev/null || command -v nvim &>/dev/null; then
    CURRENT=$(nvim --version 2>/dev/null | head -1)
    info "nvim already installed: $CURRENT"
    if ! prompt_yes_no "reinstall/update nvim?"; then
      return
    fi
  fi

  info "installing neovim from tarball..."
  TMP=$(mktemp -d)
  curl -L --progress-bar \
    "https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz" \
    -o "$TMP/nvim.tar.gz"
  tar xf "$TMP/nvim.tar.gz" -C "$TMP"

  if [ "$HAS_SUDO" = true ]; then
    sudo rm -rf /opt/nvim
    sudo mv "$TMP/nvim-linux-x86_64" /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  else
    rm -rf "$HOME/.local/nvim"
    mv "$TMP/nvim-linux-x86_64" "$HOME/.local/nvim"
    ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  fi

  rm -rf "$TMP"
  success "neovim installed: $(nvim --version | head -1)"
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
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  # source nvm for this session
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  success "node installed: $(node --version)"
}

# ============================================================
#  INSTALL: PYTHON (system or venv)
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
    error "python3 not found and no sudo to install it. please ask your sysadmin."
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
      rocky)  sudo dnf install -y ripgrep || {
                warn "ripgrep not in default repos , installing from binary..."
                install_ripgrep_binary
              } ;;
    esac
  else
    install_ripgrep_binary
  fi
  success "ripgrep installed"
}

install_ripgrep_binary() {
  TMP=$(mktemp -d)
  # get latest version tag
  LATEST=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f 4)
  curl -L --progress-bar \
    "https://github.com/BurntSushi/ripgrep/releases/download/${LATEST}/ripgrep-${LATEST}-x86_64-unknown-linux-musl.tar.gz" \
    -o "$TMP/rg.tar.gz"
  tar xf "$TMP/rg.tar.gz" -C "$TMP"
  mv "$TMP/ripgrep-${LATEST}-x86_64-unknown-linux-musl/rg" "$HOME/.local/bin/"
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

  info "installing zoxide..."
  if [ "$HAS_SUDO" = true ] && [ "$DISTRO" = "arch" ]; then
    sudo pacman -S --noconfirm zoxide
  else
    # zoxide install script is always no-sudo friendly
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
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
  # install to ~/.local so no sudo needed
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

  info "installing stylua from binary..."
  TMP=$(mktemp -d)
  curl -L --progress-bar \
    "https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux-x86_64.zip" \
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
#  INSTALL: BASE SYSTEM DEPS (curl, unzip, git, etc)
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
        # yarn
        if ! command -v yarn &>/dev/null; then
          sudo npm install -g yarn 2>/dev/null || true
        fi
        ;;
      rocky)
        sudo dnf install -y curl unzip git make
        # enable epel for more packages
        sudo dnf install -y epel-release 2>/dev/null || true
        ;;
    esac
  else
    # check the critical ones are available
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
    warn "latex deps require sudo — skipping system packages"
    warn "you'll need texlive , zathura , and inkscape installed by your sysadmin"
  fi
}

# ============================================================
#  INSTALL: MOLTEN / JUPYTER SUPPORT
# ============================================================
install_molten() {
  info "installing molten/jupyter dependencies..."

  # system deps
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

  # python venv (no sudo needed)
  info "setting up python venv for molten at ~/.envs/neovim..."
  mkdir -p "$HOME/.envs"
  python3 -m venv "$HOME/.envs/neovim"
  # shellcheck disable=SC1091
  source "$HOME/.envs/neovim/bin/activate"
  pip install --quiet \
    pynvim jupyter_client cairosvg plotly kaleido \
    pnglatex pyperclip nbformat jupytext jupyter jupyterlab
  deactivate
  success "python venv set up at ~/.envs/neovim"

  # quarto
  info "installing quarto..."
  TMP=$(mktemp -d)
  QUARTO_VERSION="1.6.40"
  if [ "$HAS_SUDO" = true ] && [ "$DISTRO" = "ubuntu" ]; then
    curl -L --progress-bar \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
      -o "$TMP/quarto.deb"
    sudo dpkg -i "$TMP/quarto.deb"
  elif [ "$DISTRO" = "arch" ] && command -v yay &>/dev/null; then
    yay -S --noconfirm quarto-cli
  else
    # tarball fallback (no sudo)
    curl -L --progress-bar \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" \
      -o "$TMP/quarto.tar.gz"
    tar xf "$TMP/quarto.tar.gz" -C "$TMP"
    mv "$TMP/quarto-${QUARTO_VERSION}/bin/quarto" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/quarto"
  fi
  rm -rf "$TMP"
  success "quarto installed"
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

  # base
  install_base_deps
  install_neovim
  install_node
  install_python
  install_ripgrep
  install_zoxide
  install_tree_sitter
  install_stylua

  # optional: latex
  echo ""
  if prompt_yes_no "install latex support (texlive , zathura , inkscape) ?"; then
    install_latex
  else
    info "skipping latex"
  fi

  # optional: molten
  echo ""
  if prompt_yes_no "install molten/jupyter support (imagemagick , python venv , quarto) ?"; then
    install_molten
  else
    info "skipping molten"
  fi

  # nvim config
  echo ""

  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}   done!                                ${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "next steps:"
  echo "  1. source ~/.bashrc  (or open a new terminal)"
  echo "  2. clone your config to ~/.config/nvim (optional)"
  echo "  3. open nvim - lazy will auto-install plugins"
  echo "  4. run :TSUpdate inside nvim"
  echo "  5. if you installed molten , run :UpdateRemotePlugins inside nvim"
  echo ""
}

main "$@"
