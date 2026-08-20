#!/bin/bash
# latex.sh — neovim dev setup for latex
# supports: arch, ubuntu/debian, rocky/rhel
# works with and without sudo

set -e

install_latex() {
  info "installing latex dependencies..."
  if [ "$HAS_SUDO" = true ]; then
    case $DISTRO in
      arch)
        sudo pacman -S --noconfirm texlive zathura zathura-pdf-mupdf inkscape
        ;;
      ubuntu)
        sudo apt install -y texlive-full zathura zathura-pdf-poppler inkscape
        ;;
      rocky)
        sudo dnf install -y texlive zathura inkscape
        warn "zathura-pdf-mupdf may need manual install on rocky"
        ;;
    esac
    success "latex deps installed"
    update_local_settings "latex_support" "True"
  else
    warn "latex deps require sudo — skipping"
    warn "you'll need texlive, zathura, and inkscape installed by your sysadmin"
  fi
}

main() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/common.sh"

  if [[ "${1:-}" != "--from-bootstrap" ]]; then
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}       neovim latex install script      ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "ensure you have already set up nvim with boostrap.sh"
  fi

  detect_distro
  detect_sudo


  if prompt_yes_no "install latex support (texlive, zathura, inkscape)?"; then
    install_latex
  else
    info "not installing latex"
  fi
}

main "$@"
