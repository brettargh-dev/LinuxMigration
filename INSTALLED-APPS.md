# Installed Apps — inventory (from Mint 22.3, for elementary OS 8)

Captured 2026-10-06. The one-shot installer is `app-restore/install-apps.sh`.
Raw lists live in `manifests/`.

## APT — from standard Ubuntu/elementary repos
| Package | What it is |
|---|---|
| `git` | version control |
| `calibre` | e-book manager |
| `plank` | macOS-style dock |
| `docker.io` | containers (you'll be added to the `docker` group) |
| `openssh-server` | SSH access to this machine |
| `python3-pip`, `python3-venv` | Python tooling |
| `xdotool`, `libinput-tools` | input scripting / gesture tools |
| `fonts-inter` | Inter font |
| `sassc` | Sass compiler (theming) |
| `vainfo`, `vdpauinfo` | GPU video-accel diagnostics |
| `libglib2.0-dev-bin`, `libxml2-utils`, `libxcb-cursor0`, `libtraceevent1` | dev/support libs you'd installed manually |

## APT — third-party repos (reproduced from this machine's exact config)
| Package | Repo | Source captured in |
|---|---|---|
| `1password` | downloads.1password.com | `app-restore/apt-sources/1password.sources` + keyring |
| `ulauncher` | agornostal PPA (launchpad) | `agornostal-ulauncher-noble.list` + keyring |
| `claude-desktop` | pkg.claude-desktop-debian.dev (community) | `claude-desktop.list` + keyring |
| `sublime-text` | **download.sublimetext.com** (official) | added fresh by the script* |

\* On this Mint box Sublime came via Mint's mirror; elementary doesn't carry it, so the
script adds Sublime's own official repo instead.

## Flatpak — from Flathub
| App ID | Name |
|---|---|
| `com.bitwarden.desktop` | Bitwarden |
| `com.discordapp.Discord` | Discord |
| `com.ktechpit.whatsie` | WhatSie (WhatsApp) |
| `io.github.nroduit.Weasis` | Weasis (DICOM viewer) |
| `md.obsidian.Obsidian` | Obsidian |

## Snap
| Snap | Name | Note |
|---|---|---|
| `icloud-for-linux` | iCloud for Linux | elementary has no snap by default — script installs `snapd` first |

## Deliberately NOT reinstalled
- `broadcom-sta-dkms` — handled by the offline Wi-Fi bundle (`broadcom-offline-bundle/`), before internet exists.
- `linux-hwe-6.17-*`, `linux-modules-*`, `linux-tools-*` — Mint's kernel packages; elementary manages its own kernel.
- `snapd` base snaps (`core20`, `bare`, `gnome-3-38-2004`, `gtk-common-themes`) — pulled in automatically as dependencies.
