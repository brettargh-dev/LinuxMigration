#!/usr/bin/env bash
# Offline installer for the Broadcom BCM4360 Wi-Fi driver (broadcom-sta / wl)
# Target: elementary OS 8 / Ubuntu 24.04 "noble" (amd64)
# Run it ON the new elementary install, from the USB stick, with NO internet needed.
#
#   cd /path/to/broadcom-offline-bundle
#   sudo bash install.sh
#
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/debs"
KREL="$(uname -r)"

echo "============================================================"
echo " Broadcom BCM4360 offline driver installer"
echo " Running kernel : $KREL"
echo " Debs folder    : $DIR"
echo "============================================================"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:  sudo bash install.sh" >&2
  exit 1
fi

if [ ! -d "$DIR" ] || ! ls "$DIR"/*.deb >/dev/null 2>&1; then
  echo "ERROR: no .deb files found in $DIR" >&2
  exit 1
fi

# --- kernel header sanity check -------------------------------------------
# DKMS compiles the driver against the CURRENTLY RUNNING kernel. The bundle
# ships headers for 6.8.0-146-generic. If your kernel differs, the build may
# fail for lack of matching headers (see README, "If the build fails").
if [ ! -d "/usr/src/linux-headers-$KREL" ] && \
   ! ls "$DIR"/linux-headers-"$KREL"_*.deb >/dev/null 2>&1; then
  echo
  echo "!! WARNING: no headers for your running kernel ($KREL) are installed"
  echo "!!          or present in this bundle. The bundle carries headers for"
  echo "!!          6.8.0-146-generic. If DKMS fails to build below, read the"
  echo "!!          README section 'If the build fails'."
  echo
fi

# --- install ---------------------------------------------------------------
# apt resolves order and versions from the local folder and will NOT downgrade
# anything elementary already has. --no-download keeps it fully offline.
echo ">> Installing packages (offline)..."
if apt-get install --no-download --yes --fix-broken "$DIR"/*.deb; then
  echo ">> apt install succeeded."
else
  echo ">> apt path failed; falling back to dpkg (two passes) ..."
  dpkg -i "$DIR"/*.deb
  dpkg -i "$DIR"/*.deb        # second pass settles install order
  dpkg --configure -a
fi

# --- verify ----------------------------------------------------------------
echo
echo ">> DKMS status:"
dkms status 2>/dev/null || true

echo
echo ">> Loading the driver..."
# wl conflicts with the open bcma/b43/brcmsmac drivers; push them aside now.
for m in b43 b43legacy ssb brcmsmac bcma; do modprobe -r "$m" 2>/dev/null || true; done
if modprobe wl 2>/dev/null; then
  echo ">> 'wl' module loaded."
else
  echo "!! Could not load 'wl' yet. A reboot usually sorts this out."
fi

echo
if lsmod | grep -q '^wl'; then
  echo "SUCCESS: the wl driver is loaded. Wi-Fi should appear now; if not, reboot."
else
  echo "Installed. REBOOT now, then check Wi-Fi. If still missing, see the README."
fi
echo "============================================================"
