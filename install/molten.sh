#!/bin/bash
# molten.sh — neovim dev setup for jupy nbs
# supports: arch, ubuntu/debian, rocky/rhel
# works with and without sudo

set -e

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
  if ! python3 -m venv --help >/dev/null 2>&1; then
    error "Python venv support is missing. Run install/bootstrap.sh first."
    return 1
  fi
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

main() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/common.sh"

  FROM_BOOTSTRAP=true
  if [[ "${1:-}" != "--from-bootstrap" ]]; then
    FROM_BOOTSTRAP=false
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}      neovim install molten script      ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "ensure you have already set up nvim with boostrap.sh"
  fi

  if prompt_yes_no "install molten/jupyter support (imagemagick, python venv, quarto)?"; then
    install_molten
    if ! $FROM_BOOTSTRAP; then
      echo "run :UpdateRemotePlugins inside nvim for molten"
    fi
  else
    info "not installing molten"
    if $FROM_BOOTSTRAP; then
      # indicate we did not install
      return 10;
    fi
  fi
}

main "$@"
