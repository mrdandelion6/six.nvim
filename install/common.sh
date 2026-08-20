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
  FD_VERSION="10.1.0"
  FZF_VERSION="0.54.0"
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
