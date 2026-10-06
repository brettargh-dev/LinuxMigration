# Linux Migration Checklist — Mint 22.3 → elementary OS 8

**Machine:** MacBook (Haswell i5-4288U · 15 GB RAM · 113 GB Apple SSD · UEFI · Intel graphics)
**From:** Linux Mint 22.3 (Cinnamon)  →  **To:** elementary OS 8 "Circe" (Ubuntu 24.04 noble base)
**Prepared:** 2026-10-06

> Hardware verdict: ✅ comfortably supported. The one real gotcha is Wi-Fi (Broadcom
> BCM4360) — handled by the offline bundle in this folder. See `broadcom-offline-bundle/`.

---

## Phase 0 — Before you touch anything (back up!)

Your `/home/emma` is **9.9 GB**. A clean install **erases the disk**, so back up first.

- [ ] **Full-disk safety net:** take a **Timeshift** snapshot (already installed) to an
      external drive — lets you roll back if the install goes sideways.
- [ ] **Copy `/home/emma` to an external drive** (9.9 GB). Don't skip these in particular:
  - [ ] `dotfiles/` (196K) — your configs
  - [ ] `PersonalVault/` (6.2M)
  - [ ] `Calibre Library/` (36M)
  - [ ] `MRI/` (932K) — DICOM data (Weasis)
  - [ ] `DevProjects/` (115M — **includes this migration folder + the Wi-Fi bundle**)
  - [ ] `.ssh/`, `.gnupg/` — keys (hidden; easy to miss)
  - [ ] Browser profiles / bookmarks if not synced
- [ ] **1Password:** confirm you can sign in on a fresh machine (account email +
      Secret Key + password). Don't rely only on the local vault.
- [ ] **iCloud (icloud-for-linux snap):** note that elementary has **no snap** by
      default — plan to reinstall snapd there if you still want it (Phase 6).
- [ ] **Put a copy of `broadcom-offline-bundle/` on the USB stick** you'll keep handy —
      you'll need it right after install, before Wi-Fi works.

## Phase 1 — Make the installer

- [ ] Download the **elementary OS 8** ISO (elementary.io) on this machine while you
      still have internet. Verify the checksum.
- [ ] Flash to an **8 GB+ USB** with **Mint's "USB Image Writer"** or `dd`.
- [ ] (Separate stick, ideally) the `broadcom-offline-bundle/` copy from Phase 0.

## Phase 2 — Install elementary OS

- [ ] Boot the USB: power on holding **⌥ Option**, pick the EFI/USB volume.
- [ ] In the installer, **tick "Install third-party software"** if offered (helps with
      graphics/firmware — though it still won't fetch the Broadcom driver offline).
- [ ] Choose **"Erase disk and install"** (UEFI; the installer handles the EFI partition).
- [ ] Create your user. Finish, remove USB, reboot.

> ⚠️ Expect **no Wi-Fi** on first boot. That's normal — next phase fixes it.

## Phase 3 — Wi-Fi (the Broadcom driver) — FIRST thing after install

- [ ] Plug in the bundle USB. Open Terminal:
  ```bash
  cd /media/$USER/<STICK>/broadcom-offline-bundle
  sudo bash install.sh
  ```
- [ ] Reboot if asked. Confirm: `lsmod | grep wl` lists `wl`, and Wi-Fi appears.
- [ ] If the build complains about kernel headers → see the bundle's `README.txt`
      ("If the build fails"): quickest fix is a one-time phone **USB tether**.
- [ ] Bluetooth (same Broadcom module) should already work.

## Phase 4 — System update & essentials (needs internet = Phase 3 done)

- [ ] `sudo apt update && sudo apt full-upgrade`
- [ ] Re-add third-party **apt repos** (these apps are NOT in elementary's repos):
  - [ ] **1Password** — add 1Password's apt repo + key, then `apt install 1password`
  - [ ] **Sublime Text** — add sublimehq repo, then `apt install sublime-text`
  - [ ] **Claude Desktop** — reinstall however you got `claude-desktop` (`.deb`/repo)
  - [ ] **Docker** — `apt install docker.io` (in universe), then add yourself to
        `docker` group: `sudo usermod -aG docker $USER`
  - [ ] **ulauncher** — via its PPA/`.deb`

## Phase 5 — Reinstall your apps (manifests are in `manifests/`)

- [ ] **apt** — review `manifests/apt-manual.txt` (29 pkgs) and install the ones you
      still want. Skip Mint/HWE-kernel-specific lines (`linux-hwe-*`, `linux-tools-*`,
      `broadcom-sta-dkms` — already installed in Phase 3). Core picks:
      `git calibre plank python3-pip python3-venv openssh-server xdotool
      libinput-tools fonts-inter`
- [ ] **Flatpak** (`manifests/flatpak-apps.txt`) — add Flathub then reinstall:
  ```bash
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub com.bitwarden.desktop com.discordapp.Discord \
    com.ktechpit.whatsie io.github.nroduit.Weasis md.obsidian.Obsidian
  ```
- [ ] **Snap** (`manifests/snap-apps.txt`) — only if you still want **icloud-for-linux**:
      `sudo apt install snapd` then `sudo snap install icloud-for-linux`.

## Phase 6 — Restore the macOS-style experience

Pantheon is already Mac-like, but to match your Mint setup:

- [ ] **Cmd ↔ Ctrl swap:** run `manifests/keyboard-swap.sh` (Pantheon uses the same
      gsettings schema — currently `['ctrl:swap_lwin_lctl']`).
- [ ] **Dock:** `plank` is installed in Phase 5 (Pantheon has its own dock too — your call).
- [ ] **App launcher:** `ulauncher` (Phase 4) for Spotlight-style search.
- [ ] Restore `dotfiles/` and re-link as needed.

## Phase 7 — Restore data & verify

- [ ] Copy back `PersonalVault/`, `Calibre Library/`, `MRI/`, `DevProjects/`, etc.
- [ ] Restore `.ssh/` and `.gnupg/` (fix perms: `chmod 700 ~/.ssh`, `600` on keys).
- [ ] Sign into 1Password; confirm vault access.
- [ ] Final checks:
  - [ ] Wi-Fi + Bluetooth work
  - [ ] Suspend/resume (lid close), battery %, screen brightness keys
  - [ ] Audio in/out, webcam
  - [ ] Keyboard swap feels right
- [ ] Keep the Timeshift/home backup until you're 100% settled.

---

### Files in this folder
- `broadcom-offline-bundle/` — offline Broadcom Wi-Fi driver + installer (Phase 3)
- `manifests/apt-manual.txt` — your manually-installed apt packages
- `manifests/flatpak-apps.txt` — your Flatpak apps
- `manifests/snap-apps.txt` — your snaps
- `manifests/keyboard-swap.sh` — reapplies the Cmd↔Ctrl swap
