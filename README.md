# NFZ-ESP-DEV

A container for ESP32 development in the terminal: Espressif's official
ESP-IDF image plus zsh (Oh My Zsh), tmux, Neovim (for kickstart.nvim) and the
Claude Code CLI. Built with rootless podman; runs on x86_64 and aarch64.

| Part | Version | Source |
|---|---|---|
| ESP-IDF (compilers, esptool, OpenOCD, QEMU, esp-clangd) | v6.1 | `docker.io/espressif/idf` |
| Neovim | v0.12.6 | GitHub release, checksum pinned |
| tree-sitter CLI | v0.27.1 | GitHub release, checksum pinned |
| Oh My Zsh | commit `964ddf7` | GitHub, pinned commit |
| zsh, tmux, ripgrep, fd, udev, less | Ubuntu 24.04 | apt |
| Claude Code CLI | latest at build time | official installer |

## Setup (once per machine)

1. `~/.local/bin` in your `PATH` (zsh on Fedora doesn't add it); in
   `~/.config/zsh/.zshrc`:
   ```
   export PATH="$HOME/.local/bin:$PATH"
   ```
2. Link the start script:
   ```
   ln -s ~/Documents/nfz-esp-dev/espdev ~/.local/bin/espdev
   ```
3. Serial ports: be in the `dialout` group (on NFZ-OS-KDE: copy the group from
   `/usr/lib/group` to `/etc/group`, `sudo usermod -aG dialout $USER`, reboot).
4. Get the image: `podman pull quay.io/quizzical0902/nfz-esp-dev:latest-$(uname -m)`
   or build it with `./build.sh`.

## Use

```
cd ~/Projects/esp32/my-project
espdev                       # zsh inside: idf.py, nvim, claude, tmux
espdev idf.py build          # or run one command
espdev idf.py -p /dev/ttyACM0 flash monitor
```

- The project folder is mounted at the same path as on the host.
- USB serial ports plugged in at start (`/dev/ttyACM*`, `/dev/ttyUSB*`) are
  passed in; plug the board in before running `espdev`.
- Neovim uses your host config (`~/.config/nvim`); its plugins and language
  servers live in the podman volume `nfz-esp-nvim-data`.
- Claude Code uses your host's `~/.claude` (login, memory). It may ask you to
  log in once inside the container.
- Text and icons are drawn by the host terminal: set a Nerd Font there.

## Build

```
./build.sh            # build and check the tools
./build.sh --push     # build, check and push
```

Tags: `:latest-<arch>` and `:<VERSION>-<arch>`. To update ESP-IDF, Neovim,
tree-sitter or Oh My Zsh, change the version (and checksums) at the top of the
matching section in `Containerfile`, bump `VERSION`, note it in
`CHANGELOG.md`.
