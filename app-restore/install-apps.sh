#!/usr/bin/env bash
#
# One-shot app restore for elementary OS 8 (Ubuntu 24.04 "noble").
# Reinstalls the apps captured from Linux Mint 22.3 in a single run:
#   APT (standard + third-party repos) · Flatpak (Flathub) · Snap
#
# USAGE (on the new elementary install, with internet):
#     cd app-restore
#     ./install-apps.sh
#
#   Run it as your NORMAL user (NOT with sudo) -- it calls sudo itself where
#   needed and installs Flatpaks correctly. It is safe to re-run; already
#   installed items are skipped.
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'; C_END=$'\033[0m'
step(){ printf '\n%s==> %s%s\n' "$C_INFO" "$*" "$C_END"; }
ok(){   printf '%s[ok]%s %s\n' "$C_OK" "$C_END" "$*"; }
warn(){ printf '%s[skip]%s %s\n' "$C_WARN" "$C_END" "$*"; }
FAILED=()
try(){ if "$@"; then return 0; else warn "failed: $*"; FAILED+=("$*"); return 1; fi; }

# ---- preflight -----------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  echo "Please run WITHOUT sudo (the script elevates individual steps itself)." >&2
  exit 1
fi
command -v sudo >/dev/null || { echo "sudo is required." >&2; exit 1; }
echo "This will install your apps on $(. /etc/os-release; echo "$PRETTY_NAME")."
echo "Priming sudo (enter your password once):"
sudo -v || { echo "sudo failed." >&2; exit 1; }
# keep sudo alive for the whole run
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT

# ---- make sure base helpers exist ---------------------------------------
step "Ensuring base helpers (curl, wget, gnupg, ca-certificates)"
try sudo apt-get update
try sudo apt-get install -y curl wget gnupg ca-certificates apt-transport-https

# ---- third-party APT repos (reproduced from the old machine) -------------
step "Installing third-party APT repo definitions"
sudo install -d -m 0755 /usr/share/keyrings /etc/apt/keyrings
# keyrings: 1password + claude -> /usr/share/keyrings ; ulauncher -> /etc/apt/keyrings
sudo cp -f "$HERE"/keyrings/1password-archive-keyring.gpg /usr/share/keyrings/ 2>/dev/null && ok "1password keyring"   || warn "1password keyring missing"
sudo cp -f "$HERE"/keyrings/claude-desktop.gpg            /usr/share/keyrings/ 2>/dev/null && ok "claude keyring"      || warn "claude keyring missing"
sudo cp -f "$HERE"/keyrings/agornostal-ulauncher-noble.gpg /etc/apt/keyrings/ 2>/dev/null && ok "ulauncher keyring"   || warn "ulauncher keyring missing"
# source definitions
sudo cp -f "$HERE"/apt-sources/1password.sources               /etc/apt/sources.list.d/ 2>/dev/null && ok "1password repo"   || warn "1password repo missing"
sudo cp -f "$HERE"/apt-sources/claude-desktop.list             /etc/apt/sources.list.d/ 2>/dev/null && ok "claude repo"      || warn "claude repo missing"
sudo cp -f "$HERE"/apt-sources/agornostal-ulauncher-noble.list /etc/apt/sources.list.d/ 2>/dev/null && ok "ulauncher repo"   || warn "ulauncher repo missing"

# Sublime Text: official repo (this was pulled via Mint's mirror before)
step "Adding Sublime Text official repo"
if [ ! -f /usr/share/keyrings/sublimehq-pub.gpg ]; then
  try bash -c 'curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/sublimehq-pub.gpg'
fi
echo "deb [signed-by=/usr/share/keyrings/sublimehq-pub.gpg] https://download.sublimetext.com/ apt/stable/" \
  | sudo tee /etc/apt/sources.list.d/sublime-text.list >/dev/null && ok "sublime repo"

# ---- APT install ---------------------------------------------------------
step "apt update (picking up new repos)"
try sudo apt-get update

APT_APPS=(
  # standard repos
  git calibre plank docker.io openssh-server python3-pip python3-venv
  xdotool libinput-tools fonts-inter sassc vainfo vdpauinfo
  libglib2.0-dev-bin libxml2-utils libxcb-cursor0 libtraceevent1
  # third-party repos
  1password ulauncher claude-desktop sublime-text
)
step "Installing ${#APT_APPS[@]} APT packages"
if ! sudo apt-get install -y "${APT_APPS[@]}"; then
  warn "bulk install hit an error; retrying individually so one bad package can't block the rest"
  for p in "${APT_APPS[@]}"; do try sudo apt-get install -y "$p"; done
fi

step "Adding $USER to the 'docker' group"
try sudo usermod -aG docker "$USER"

# ---- Flatpak (Flathub) ---------------------------------------------------
step "Flatpak / Flathub apps"
command -v flatpak >/dev/null || try sudo apt-get install -y flatpak
try sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
FLATPAKS=(
  com.bitwarden.desktop
  com.discordapp.Discord
  com.ktechpit.whatsie
  io.github.nroduit.Weasis
  md.obsidian.Obsidian
)
try sudo flatpak install -y --system flathub "${FLATPAKS[@]}"

# ---- Snap (optional: iCloud for Linux) -----------------------------------
step "Snap: icloud-for-linux (elementary has no snap by default)"
command -v snap >/dev/null || try sudo apt-get install -y snapd
try sudo snap install icloud-for-linux

# ---- summary -------------------------------------------------------------
step "Summary"
if [ "${#FAILED[@]}" -eq 0 ]; then
  ok "All steps completed."
else
  warn "${#FAILED[@]} step(s) need attention:"
  printf '    - %s\n' "${FAILED[@]}"
fi
cat <<'NOTE'

Next:
  * Log out and back in for the 'docker' group to take effect.
  * Sign in to 1Password, Bitwarden, Discord, Obsidian, iCloud as needed.
  * Reapply the macOS-style Cmd<->Ctrl swap:  ../manifests/keyboard-swap.sh
NOTE
