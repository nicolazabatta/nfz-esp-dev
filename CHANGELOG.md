# NFZ-ESP-DEV changelog

ESP-IDF development container: Espressif's image + terminal tools.
Image: `quay.io/quizzical0902/nfz-esp-dev:latest-<arch>` (plus a tag per
release: `:<VERSION>-<arch>`, e.g. `:1-x86_64`). Built with `./build.sh`.

Releases are numbered. To start a new release: bump `VERSION`, add a section
at the top of this file, and tag the commit in git.

---

## Version 1 — in progress (not built yet)

### Added
- `Containerfile` on `docker.io/espressif/idf:v6.1` (ESP-IDF, compilers,
  esptool, OpenOCD, QEMU, esp-clangd), adding:
  - from Ubuntu 24.04: `zsh` (default shell), `tmux`, `ripgrep`, `fd-find`
    (as `fd`), `udev`, `less`;
  - Neovim v0.12.6 and the tree-sitter CLI v0.27.1 from their GitHub
    releases, checksums pinned for x86_64 and arm64 (Ubuntu's are too old for
    kickstart.nvim);
  - Oh My Zsh at commit `964ddf7` (robbyrussell theme, no self-updates) and
    `files/zshrc` (loads ESP-IDF in every shell);
  - Claude Code CLI (official installer).
- `espdev`: runs the current folder in the container at the same path, with
  the host's `~/.config/nvim`, `~/.claude` and `~/.gitconfig`, a volume for
  Neovim plugins (`nfz-esp-nvim-data`), and every plugged-in USB serial port.
- `build.sh`: rootless build for this machine's architecture, tags
  `:latest-<arch>` and `:<VERSION>-<arch>`, checks the tools in the result,
  `--push` with a persistent login file.

## Not in the image
- Nerd Font: only needed on the host (the terminal draws the text). NFZ-OS-KDE
  has Meslo and JetBrainsMono.
- Neovim config: the host's kickstart.nvim fork. Languages for ESP work:
  C/C++ (esp-clangd), Lua, Markdown, plus Tree-sitter for CMake, Kconfig,
  JSON, YAML, Python, Bash. Clipboard inside the container: OSC 52
  (`vim.g.clipboard = 'osc52'`), which kitty supports.

## Pending / ideas
- A `devcontainer.json` using this image, so VS Code and the terminal share
  one environment.
- Multi-arch manifest (one tag for x86_64 and aarch64).
