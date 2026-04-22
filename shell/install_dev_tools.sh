#!/usr/bin/env bash

set -euo pipefail

DEFAULT_PACKAGES=(
  git
  curl
  wget
  jq
  vim
  tmux
  htop
  tree
  unzip
  zip
)

usage() {
  cat <<'EOF'
Usage:
  bash shell/install_dev_tools.sh
  bash shell/install_dev_tools.sh git curl jq
  bash shell/install_dev_tools.sh --help

Description:
  Installs common development tools on macOS and Linux.
  If no packages are provided, a default toolset will be installed.

Supported package managers:
  brew, apt, dnf, yum, pacman, zypper, apk
EOF
}

log() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1
}

detect_package_manager() {
  if require_command brew; then
    echo "brew"
    return
  fi
  if require_command apt-get; then
    echo "apt"
    return
  fi
  if require_command dnf; then
    echo "dnf"
    return
  fi
  if require_command yum; then
    echo "yum"
    return
  fi
  if require_command pacman; then
    echo "pacman"
    return
  fi
  if require_command zypper; then
    echo "zypper"
    return
  fi
  if require_command apk; then
    echo "apk"
    return
  fi

  echo "unknown"
}

ensure_homebrew() {
  if require_command brew; then
    return
  fi

  log "Homebrew not found. Installing Homebrew first..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  require_command brew || die "Homebrew installation failed."
}

ensure_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    echo ""
    return
  fi

  if require_command sudo; then
    echo "sudo"
    return
  fi

  die "This script requires root privileges or sudo."
}

run_with_privilege() {
  local sudo_cmd="$1"
  shift

  if [[ -n "$sudo_cmd" ]]; then
    "$sudo_cmd" "$@"
  else
    "$@"
  fi
}

map_package_name() {
  local manager="$1"
  local package="$2"

  case "$package" in
    build-essential)
      case "$manager" in
        brew) echo "" ;;
        apt) echo "build-essential" ;;
        dnf|yum) echo "@development-tools" ;;
        pacman) echo "base-devel" ;;
        zypper) echo "pattern:devel_basis" ;;
        apk) echo "build-base" ;;
        *) echo "build-essential" ;;
      esac
      ;;
    vim)
      case "$manager" in
        apk) echo "vim" ;;
        *) echo "vim" ;;
      esac
      ;;
    *)
      echo "$package"
      ;;
  esac
}

install_with_brew() {
  local packages=("$@")
  ensure_homebrew
  log "Using Homebrew to install: ${packages[*]}"
  brew update
  brew install "${packages[@]}"
}

install_with_apt() {
  local sudo_cmd="$1"
  shift
  local packages=("$@")
  log "Using apt to install: ${packages[*]}"
  run_with_privilege "$sudo_cmd" apt-get update
  run_with_privilege "$sudo_cmd" apt-get install -y "${packages[@]}"
}

install_with_dnf() {
  local sudo_cmd="$1"
  shift
  local packages=("$@")
  log "Using dnf to install: ${packages[*]}"
  run_with_privilege "$sudo_cmd" dnf install -y "${packages[@]}"
}

install_with_yum() {
  local sudo_cmd="$1"
  shift
  local packages=("$@")
  log "Using yum to install: ${packages[*]}"
  run_with_privilege "$sudo_cmd" yum install -y "${packages[@]}"
}

install_with_pacman() {
  local sudo_cmd="$1"
  shift
  local packages=("$@")
  log "Using pacman to install: ${packages[*]}"
  run_with_privilege "$sudo_cmd" pacman -Sy --noconfirm "${packages[@]}"
}

install_with_zypper() {
  local sudo_cmd="$1"
  shift
  local packages=("$@")
  log "Using zypper to install: ${packages[*]}"
  run_with_privilege "$sudo_cmd" zypper --non-interactive install "${packages[@]}"
}

install_with_apk() {
  local sudo_cmd="$1"
  shift
  local packages=("$@")
  log "Using apk to install: ${packages[*]}"
  run_with_privilege "$sudo_cmd" apk add --no-cache "${packages[@]}"
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  local manager
  manager="$(detect_package_manager)"
  [[ "$manager" != "unknown" ]] || die "Unsupported system: no supported package manager found."

  local requested_packages=()
  if [[ "$#" -gt 0 ]]; then
    requested_packages=("$@")
  else
    requested_packages=("${DEFAULT_PACKAGES[@]}")
  fi

  local resolved_packages=()
  local pkg mapped
  for pkg in "${requested_packages[@]}"; do
    mapped="$(map_package_name "$manager" "$pkg")"
    if [[ -n "$mapped" ]]; then
      resolved_packages+=("$mapped")
    fi
  done

  if [[ "${#resolved_packages[@]}" -eq 0 ]]; then
    die "No installable packages remain after package mapping."
  fi

  log "Detected package manager: $manager"
  log "Requested packages: ${requested_packages[*]}"
  log "Resolved packages: ${resolved_packages[*]}"

  if [[ "$manager" == "brew" ]]; then
    install_with_brew "${resolved_packages[@]}"
  else
    local sudo_cmd
    sudo_cmd="$(ensure_sudo)"
    case "$manager" in
      apt)
        install_with_apt "$sudo_cmd" "${resolved_packages[@]}"
        ;;
      dnf)
        install_with_dnf "$sudo_cmd" "${resolved_packages[@]}"
        ;;
      yum)
        install_with_yum "$sudo_cmd" "${resolved_packages[@]}"
        ;;
      pacman)
        install_with_pacman "$sudo_cmd" "${resolved_packages[@]}"
        ;;
      zypper)
        install_with_zypper "$sudo_cmd" "${resolved_packages[@]}"
        ;;
      apk)
        install_with_apk "$sudo_cmd" "${resolved_packages[@]}"
        ;;
      *)
        die "Unsupported package manager: $manager"
        ;;
    esac
  fi

  log "Installation finished."
}

main "$@"
