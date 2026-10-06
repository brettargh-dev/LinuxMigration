# Post-Format Sequence — elementary OS 8 on the MacBook

A straight, do-this-then-that runbook for the day you wipe Mint and install
elementary. The detailed reference is `MIGRATION-CHECKLIST.md`; **this file is the
ordered sequence.**

> ⚠️ **Key fact about the installer:** elementary OS's installer does **NOT** have
> Mint/Ubuntu's *"Install third-party software / drivers"* checkbox. So do **not**
> count on it to set up Wi-Fi. Your MacBook's Broadcom BCM4360 chip will have **no
> driver after install** — and no Wi-Fi means you can't download one. The offline
> USB you make in Step 1 is what guarantees you get online. Even if some driver
> prompt did appear, it couldn't fetch Broadcom's driver without internet anyway.

---

## ‼️ STEP 0 — Before you erase anything (still on Mint, with internet)

Formatting wipes the internal disk, **including this `LinuxMigration` folder**. Get
it onto USB first, or you'll have no Wi-Fi driver and no scripts afterward.

- [ ] **Back up your data** — copy `/home/emma` (9.9 GB) to an external drive.
      Don't forget hidden `~/.ssh` and `~/.gnupg`. (See checklist Phase 0.)

---

## STEP 1 — Make TWO USB sticks (still on Mint)

### USB #1 — the elementary installer (bootable, 8 GB+)
- [ ] Download the **elementary OS 8** ISO from elementary.io; verify its checksum.
- [ ] Flash it with Mint's **"USB Image Writer"** (Menu → search *USB Image Writer*),
      or from a terminal (replace `sdX` with your stick — check with `lsblk`):
      ```bash
      sudo dd if=~/Downloads/elementaryos-8*.iso of=/dev/sdX bs=4M status=progress oflag=sync
      ```

### USB #2 — the migration kit / Wi-Fi driver (data stick, any small USB)
This carries the offline Broadcom driver + the install scripts. **Copy from the
local folder** (its `.deb` files are real), *not* a fresh Git clone (that would need
`git-lfs` or you'd get pointer files).

- [ ] Plug in the stick, then copy the whole folder:
      ```bash
      cp -r ~/DevProjects/LinuxMigration "/media/$USER/<STICK_NAME>/"
      ```
- [ ] **Verify the driver files are real packages, not LFS pointers** (important!):
      ```bash
      file "/media/$USER/<STICK_NAME>/LinuxMigration/broadcom-offline-bundle/debs/dkms_"*.deb
      ```
      Each must say **"Debian binary package"**. If any says *"ASCII text"*, the copy
      came from a Git clone without LFS — recopy from `~/DevProjects/LinuxMigration`.
- [ ] Safely eject both sticks.

> Tip: one 8 GB+ stick can hold both if you prefer — flash the ISO, then copy the
> `LinuxMigration` folder onto the stick's data partition. Two sticks is simpler.

---

## STEP 2 — Install elementary (the format)

- [ ] Shut down. Power on holding **⌥ Option**, pick the elementary USB (EFI).
- [ ] In the installer choose **"Erase disk and install"** (UEFI; it handles the
      EFI partition automatically).
- [ ] Create your user account. Finish → remove the installer USB → reboot.

> Expect **no Wi-Fi** on first boot. That's normal and expected — Step 3 fixes it.

---

## STEP 3 — Wi-Fi driver, FIRST thing after first boot (offline)

- [ ] Log in. Plug in **USB #2** (the migration kit).
- [ ] Open **Terminal** and run (adjust the mount path — check with `ls /media/$USER`):
      ```bash
      cd /media/$USER/<STICK_NAME>/LinuxMigration/broadcom-offline-bundle
      sudo bash install.sh
      ```
- [ ] Reboot if asked. Then confirm it worked:
      ```bash
      lsmod | grep wl          # should list 'wl'
      nmcli device             # wlp3s0 should show as wifi
      ```
- [ ] Connect to your Wi-Fi network from the top-panel menu. **You're online.** 🎉

### If the driver build fails ("kernel headers not found")
This only happens if elementary booted a kernel other than the one the bundle has
headers for (`6.8.0-146-generic`). Check with `uname -r`, then:
- **Quickest fix:** plug your phone in via USB → enable **USB tethering** (gives wired
  internet for ~2 min) → `sudo apt install broadcom-sta-dkms` (apt pulls the exact
  headers). A USB-Ethernet adapter works the same way.
- Full details and a no-cable option are in `broadcom-offline-bundle/README.txt`.

---

## STEP 4 — Update, then reinstall all your apps (needs the Wi-Fi from Step 3)

- [ ] System update:
      ```bash
      sudo apt update && sudo apt full-upgrade
      ```
- [ ] Run the one-shot app installer (as your normal user, **not** sudo):
      ```bash
      cd /media/$USER/<STICK_NAME>/LinuxMigration/app-restore
      ./install-apps.sh
      ```
      This installs all your APT apps (incl. 1Password, Sublime, Claude Desktop,
      ulauncher), the 5 Flatpaks, and iCloud-for-Linux (snap) in one run. See
      `INSTALLED-APPS.md` for the full list.

---

## STEP 5 — Restore your macOS-style setup & data

- [ ] Reapply the **Cmd ↔ Ctrl** keyboard swap:
      ```bash
      bash /media/$USER/<STICK_NAME>/LinuxMigration/manifests/keyboard-swap.sh
      ```
- [ ] Copy your data back from the Step 0 backup (`PersonalVault/`, `Calibre Library/`,
      `MRI/`, `DevProjects/`, Downloads, etc.).
- [ ] Restore keys and fix permissions:
      ```bash
      chmod 700 ~/.ssh && chmod 600 ~/.ssh/*        # (keep .pub readable)
      chmod 700 ~/.gnupg
      ```
- [ ] Log out / back in so the **docker** group and app associations take effect.
- [ ] Sign in to 1Password, Bitwarden, Discord, Obsidian, iCloud.

---

## STEP 6 — Final verification

- [ ] Wi-Fi + Bluetooth work
- [ ] Suspend/resume on lid close, battery %, brightness keys
- [ ] Audio in/out, webcam
- [ ] Keyboard swap feels right (⌘ acts as Ctrl)
- [ ] Your apps launch and are signed in
- [ ] **Keep USB #2 and the `/home` backup** until you're 100% settled.

---

## 📌 Post-migration to-do (do these *after* migration is finished)

- [ ] **Set up real iCloud Drive sync via `rclone`.**
      The `icloud-for-linux` snap is only a web wrapper (same as iCloud in a
      browser) — it does **not** sync files to disk. For an actual synced folder:
  - **First check:** iCloud **Advanced Data Protection (ADP)** must be **OFF** —
        rclone cannot access iCloud Drive if ADP is enabled. (Dealbreaker if on.)
  - Install rclone: `sudo -v ; curl https://rclone.org/install.sh | sudo bash`
        (needs rclone **v1.69+**; iCloud Drive backend is current as of v1.75.x).
  - Configure the remote: `rclone config` → new remote → type **`iclouddrive`**
        → Apple ID + app-specific password / 2FA (saves a trust token that expires
        periodically, so occasional re-auth is expected).
  - Choose a mode:
    - `rclone bisync` for **two-way** sync into a local folder (closest to native),
    - `rclone sync` for a one-way mirror, or
    - `rclone mount` to browse iCloud Drive as a folder on demand.
  - Automate with a **systemd timer or cron** (it is not an always-on daemon).
  - *When we do this, add an `rclone-icloud-setup.sh` to `app-restore/` to script it.*

---

### Quick reference — what's on USB #2 (`LinuxMigration/`)
| Path | Purpose | Step |
|---|---|---|
| `broadcom-offline-bundle/install.sh` | offline Wi-Fi driver | 3 |
| `broadcom-offline-bundle/README.txt` | driver fallbacks | 3 |
| `app-restore/install-apps.sh` | reinstall all apps | 4 |
| `manifests/keyboard-swap.sh` | Cmd↔Ctrl swap | 5 |
| `INSTALLED-APPS.md` | app inventory | ref |
| `MIGRATION-CHECKLIST.md` | full detailed checklist | ref |
