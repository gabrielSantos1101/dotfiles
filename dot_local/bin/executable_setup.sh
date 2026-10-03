#!/usr/bin/env bash
# setup.sh — restore this dotfiles repo onto a new machine.
#
# Usage:
#   ./setup.sh              # install everything that is missing
#   ./setup.sh --check      # only report what is missing, install nothing
#
# Portable by design: detects the package manager and the paths that exist
# instead of assuming Arch or Omarchy. Safe to re-run.

set -uo pipefail

check_only=0
[[ "${1:-}" == "--check" ]] && check_only=1

log()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# --- package manager ------------------------------------------------------
# Order matters: the first one that can install a package without being
# prompted for a package name wins.
detect_pm() {
  if command -v pacman >/dev/null 2>&1; then echo pacman
  elif command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v zypper >/dev/null 2>&1; then echo zypper
  elif command -v apk >/dev/null 2>&1; then echo apk
  else echo none
  fi
}

pm="$(detect_pm)"
[[ "$pm" == none ]] && die "no supported package manager found (need pacman/apt/dnf/zypper/apk)"

pm_install() {
  case "$pm" in
    pacman) sudo pacman -S --needed --noconfirm "$@" ;;
    apt)    sudo apt-get install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    zypper) sudo zypper install -y "$@" ;;
    apk)    sudo apk add "$@" ;;
  esac
}

pm_installed() {
  case "$pm" in
    pacman) pacman -Qq "$1" >/dev/null 2>&1 ;;
    apt)    dpkg -s "$1" >/dev/null 2>&1 ;;
    dnf)    rpm -q "$1" >/dev/null 2>&1 ;;
    zypper) rpm -q "$1" >/dev/null 2>&1 ;;
    apk)    apk info -e "$1" >/dev/null 2>&1 ;;
  esac
}

# Names differ per distro; keep a portable list with aliases.
# "a b" means: install "a" on most, "b" as the fallback name.
want_pkgs=(
  "zsh"
  "fzf" "zoxide" "bat" "eza" "ripgrep" "fd" "starship"
  "zellij" "tmux"
  "git" "curl"
)

log "package manager: $pm"

# --- shell ----------------------------------------------------------------
current_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
if [[ "$current_shell" == */zsh ]]; then
  log "login shell: zsh (ok)"
elif [[ $check_only -eq 1 ]]; then
  log "login shell: $current_shell (expected zsh)"
else
  command -v chsh >/dev/null 2>&1 || warn "chsh not found; set your shell manually"
  if command -v chsh >/dev/null 2>&1; then
    log "setting login shell to zsh..."
    chsh -s "$(command -v zsh)" && log "login shell: zsh" \
      || warn "chsh failed — run it manually after installing zsh"
  fi
fi

# --- report / install -----------------------------------------------------
missing=()
for p in "${want_pkgs[@]}"; do
  pm_installed "$p" || missing+=("$p")
done

log ""
if [[ ${#missing[@]} -eq 0 ]]; then
  log "packages: all present"
else
  log "packages missing (${#missing[@]}): ${missing[*]}"
  if [[ $check_only -eq 1 ]]; then
    log "run './setup.sh' (without --check) to install them"
  else
    log "installing..."
    pm_install "${missing[@]}" || die "package installation failed"
    log "packages installed"
  fi
fi

# --- services (optional, only where they exist) ---------------------------
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files sshd.service >/dev/null 2>&1 || [[ -f /usr/lib/systemd/system/sshd.service ]]; then
    if [[ $check_only -eq 1 ]]; then
      log "sshd: $(systemctl is-active sshd 2>/dev/null || echo not-active)"
    else
      sudo systemctl enable --now sshd && log "sshd: enabled" \
        || warn "could not enable sshd"
    fi
  fi
fi

# --- done -----------------------------------------------------------------
log ""
log "done. next:"
log "  chezmoi apply        # restore the dotfiles themselves"
log "  exec zsh             # start the configured shell"
