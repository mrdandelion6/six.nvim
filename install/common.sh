# ============================================================
#  VERSIONS
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/versions.env" ]; then
  source "$SCRIPT_DIR/versions.env"
else
  echo "[warn] versions.env not found, using built-in defaults"
  NVIM_VERSION="0.12.6"
  RG_VERSION="14.1.1"
  STYLUA_VERSION="2.6.0"
  QUARTO_VERSION="1.6.40"
  ZOXIDE_VERSION="0.9.4"
  FD_VERSION="10.1.0"
  FZF_VERSION="0.54.0"
  TREE_SITTER_VERSION="0.27.2"
  UV_VERSION="0.13.10"
  NVM_VERSION="0.40.3"
  NVIM_VENV_PYTHON="3.14"
  NVIM_MIN="0.12.0"
  NODE_MIN_MAJOR="20"
fi

# tools only nvim uses (tree-sitter , stylua). init.lua puts this first on
# nvim's PATH , so these copies always win inside nvim
NVIM_BIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/bootstrap/bin"

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
  # already detected by bootstrap.sh , which runs latex.sh / molten.sh
  if [ -n "${DISTRO:-}" ]; then
    return
  fi

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
  export DISTRO
  info "detected distro: $DISTRO"
}

# ============================================================
#  DETECT SUDO
# ============================================================
detect_sudo() {
  # already detected by bootstrap.sh , which runs latex.sh / molten.sh
  if [ -n "${HAS_SUDO:-}" ]; then
    return
  fi

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
  export HAS_SUDO
}

# ============================================================
#  DETECT MODE
# ============================================================
# system: arch with sudo. missing core tools come from pacman
# local:  everything else. missing core tools are curled into ~/.local/bin
# pass --local or --system to choose. default is system when possible
detect_mode() {
  MODE=""
  for arg in "$@"; do
    case $arg in
      --local)  MODE="local" ;;
      --system) MODE="system" ;;
    esac
  done

  if [ "$MODE" = "system" ] && { [ "$DISTRO" != "arch" ] || [ "$HAS_SUDO" != true ]; }; then
    error "--system needs arch with sudo. use --local (or no flag) instead."
    exit 1
  fi
  if [ -z "$MODE" ]; then
    if [ "$DISTRO" = "arch" ] && [ "$HAS_SUDO" = true ]; then
      MODE="system"
    else
      MODE="local"
    fi
  fi

  if [ "$MODE" = "local" ]; then
    mkdir -p "$HOME/.local/bin"
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
  fi
  export MODE
  info "install mode: $MODE"
}

# ============================================================
#  NOTES (printed at the end of bootstrap)
# ============================================================
NOTES=()
note() {
  NOTES+=("$1")
}

print_notes() {
  if [ ${#NOTES[@]} -eq 0 ]; then
    return
  fi
  echo ""
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}   notes                                ${NC}"
  echo -e "${YELLOW}========================================${NC}"
  for n in "${NOTES[@]}"; do
    echo -e "- $n"
  done
}

# ============================================================
#  VERSIONS
# ============================================================
# first x.y.z (or x.y) in `<cmd> --version` , e.g. "NVIM v0.12.6" -> 0.12.6
tool_version() {
  "$1" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# true if version $1 >= version $2
version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# ============================================================
#  WHO INSTALLED A BINARY
# ============================================================
# prints: pacman , apt , dnf , npm , nvm , cargo , bootstrap , or manual
tool_owner() {
  local path="$1" real
  real=$(readlink -f "$path" 2>/dev/null || echo "$path")

  if command -v pacman &>/dev/null && pacman -Qoq "$path" &>/dev/null; then
    echo "pacman"
  elif command -v dpkg &>/dev/null && dpkg -S "$real" &>/dev/null; then
    echo "apt"
  elif command -v rpm &>/dev/null && rpm -qf "$real" &>/dev/null; then
    echo "dnf"
  else
    case $real in
      */node_modules/*)        echo "npm" ;;
      "$HOME"/.nvm/*)          echo "nvm" ;;
      "$HOME"/.cargo/*)        echo "cargo" ;;
      "$NVIM_BIN_DIR"/*)       echo "bootstrap" ;;
      *)                       echo "manual" ;;
    esac
  fi
}

# prints a command that removes the binary at $1
removal_hint() {
  local path="$1" real owner pkg sudo_prefix=""
  real=$(readlink -f "$path" 2>/dev/null || echo "$path")
  owner=$(tool_owner "$path")
  [ -w "$(dirname "$path")" ] || sudo_prefix="sudo "

  case $owner in
    pacman) echo "sudo pacman -R $(pacman -Qoq "$path")" ;;
    apt)    echo "sudo apt remove $(dpkg -S "$real" | head -1 | cut -d: -f1)" ;;
    dnf)    echo "sudo dnf remove $(rpm -qf --qf '%{NAME}' "$real")" ;;
    npm)
      # package name is the path after the last node_modules/ (may be @scoped)
      pkg=${real##*/node_modules/}
      case $pkg in
        @*) pkg=$(echo "$pkg" | cut -d/ -f1-2) ;;
        *)  pkg=${pkg%%/*} ;;
      esac
      echo "${sudo_prefix}npm uninstall -g $pkg"
      ;;
    nvm)    echo "nvm uninstall <version>  (see nvm ls)" ;;
    cargo)  echo "cargo uninstall $(basename "$path")" ;;
    *)      echo "${sudo_prefix}rm $path" ;;
  esac
}

# describe a binary , e.g. "/usr/bin/tree-sitter (npm , 0.25.8)"
describe_tool() {
  local path="$1"
  echo "$path ($(tool_owner "$path") , $(tool_version "$path"))"
}

# after installing $1 to $2 , make sure that copy is the one on PATH. if
# something earlier on PATH still wins , say what it is and how to remove it.
# if ours wins , point out the older copies it now shadows
check_winner() {
  local cmd="$1" expected="$2" winner p
  hash -r
  winner=$(command -v "$cmd" || true)
  if [ "$(readlink -f "$winner")" != "$(readlink -f "$expected")" ]; then
    warn "$cmd: the new copy at $expected is shadowed by $(describe_tool "$winner")"
    note "$cmd: $(describe_tool "$winner") comes before the new $expected on PATH. remove it with: $(removal_hint "$winner")"
    return
  fi

  for p in $(type -aP "$cmd"); do
    if [ "$(readlink -f "$p")" = "$(readlink -f "$expected")" ]; then
      continue
    fi
    note "$cmd: $(describe_tool "$p") is no longer used , $expected comes first on PATH. safe to remove if you don't need it: $(removal_hint "$p")"
  done
}

# ============================================================
#  PACMAN
# ============================================================
# install packages with pacman , never with -y (no partial upgrades). if a file
# pacman needs already exists from another source , pacman refuses. in that case
# say what's in the way and continue with the rest of bootstrap
pacman_install() {
  local log status out
  log=$(mktemp)
  # tee so pacman's progress still shows
  sudo pacman -S --needed --noconfirm "$@" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  out=$(cat "$log")
  rm -f "$log"
  if [ "$status" -eq 0 ]; then
    return 0
  fi
  if echo "$out" | grep -q "exists in filesystem"; then
    local f
    for f in $(echo "$out" | grep -oE '/[^ ]+ exists in filesystem' | cut -d' ' -f1); do
      error "pacman can't install $* , $(describe_tool "$f") is in the way"
      note "pacman refused to install $* because $(describe_tool "$f") already exists. remove it with: $(removal_hint "$f") , then run bootstrap again"
    done
  else
    error "pacman failed to install $*"
    note "pacman failed to install $* , see the output above"
  fi
  return 1
}

# warn that a pacman package is older than what the config needs
warn_pacman_outdated() {
  local cmd="$1" have="$2" need="$3"
  warn "$cmd $have (pacman) is older than the minimum $need"
  note "$cmd $have from pacman is older than the minimum $need. run a full system upgrade: sudo pacman -Syu. bootstrap won't upgrade a single package , partial upgrades aren't supported on arch"
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
    json.dump(data, f, indent=4)
"
  success "set $key = $value in local settings"
}

# ============================================================
#  READ LOCAL SETTINGS
# ============================================================
# prints the value of a string key in .localsettings.json, or nothing if the
# file or key is missing
read_local_setting() {
  local key="$1"
  local settings="$HOME/.config/nvim/.localsettings.json"

  if [ ! -f "$settings" ]; then
    return
  fi

  python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    value = json.load(f).get(sys.argv[2])
if isinstance(value, str):
    print(value)
" "$settings" "$key"
}
