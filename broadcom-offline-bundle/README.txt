===========================================================================
 Broadcom BCM4360 Wi-Fi — OFFLINE driver bundle
 For: elementary OS 8  (Ubuntu 24.04 "noble", amd64)
 Built on: Linux Mint 22.3 (same noble base) on 2026-10-06
===========================================================================

WHY YOU NEED THIS
-----------------
Your MacBook's Wi-Fi chip is a Broadcom BCM4360 [14e4:43a0]. It needs the
proprietary "broadcom-sta" (wl) driver, which is NOT on the elementary OS
install media. So a fresh elementary install has no Wi-Fi until this driver
is installed -- and normally you'd need internet to get it. This bundle lets
you install it completely offline.

WHAT'S IN HERE
--------------
  debs/        85 .deb packages:
                 - broadcom-sta-dkms        (the driver itself)
                 - dkms + build-essential   (compiler toolchain to build it)
                 - linux-headers 6.8.0-146  (kernel headers to build against)
                 - all supporting libraries
  install.sh   one-command offline installer
  README.txt   this file

HOW TO USE IT
-------------
1. Install elementary OS 8 as normal (Wi-Fi won't work yet -- that's expected).
   TIP: on the installer's software screen, tick "Install third-party
   software" if offered.

2. Boot into elementary. Plug in this USB stick. Open the Files app and note
   where it's mounted (usually /media/<you>/<STICKNAME>).

3. Open a Terminal and run:

       cd /media/<you>/<STICKNAME>/broadcom-offline-bundle
       sudo bash install.sh

4. When it finishes, reboot if told to. Wi-Fi should now appear in the top
   panel. Done.

(Manual alternative, if you prefer not to use the script:
       cd .../broadcom-offline-bundle/debs
       sudo apt install --no-download ./*.deb
 then reboot.)

IF THE BUILD FAILS  ("kernel headers not found" / dkms error)
-------------------------------------------------------------
This happens only if elementary is running a kernel OTHER than
6.8.0-146-generic (the version whose headers are bundled). Check with:

       uname -r

- If it prints 6.8.0-146-generic  -> the bundle has everything; re-run install.
- If it prints a DIFFERENT 6.8.0-XXX -> you need the headers for THAT version.
  The quickest fix is a 2-minute wired/tether connection just once:
       * plug your phone in via USB and enable "USB tethering", OR
       * use a USB-Ethernet adapter,
  then:
       sudo apt install broadcom-sta-dkms
  (apt will pull the exact headers it needs and build the driver.)

  No cable at all? Rebuild this bundle on the Mint machine for elementary's
  exact kernel: boot elementary, run `uname -r`, then back on Mint run
  `apt-get download linux-headers-<that-version> linux-headers-<that-version>-generic`
  and copy those two .deb files into debs/.

CHECKING IT WORKED
------------------
       lsmod | grep wl          # should list 'wl'
       nmcli device             # wlp3s0 should show as wifi
Bluetooth (same Broadcom module) generally works with no extra steps.
===========================================================================
