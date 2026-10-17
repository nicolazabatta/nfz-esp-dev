# =============================================================================
#  NFZ-ESP-DEV — ESP-IDF development container with Neovim and Claude Code
# =============================================================================
#  Built on Espressif's official image, which already contains ESP-IDF, the
#  compilers, esptool, OpenOCD, QEMU and esp-clangd (clangd that understands
#  ESP32 code). This file only adds the tools for working in a terminal:
#  zsh + Oh My Zsh, tmux, Neovim (for kickstart.nvim) and the Claude Code CLI.
#
#  Build:  ./build.sh   (see there; no sudo needed)
#  Use:    espdev       (start script: current folder inside the container)
#
#  Fonts are not needed here: the terminal on the host (kitty, Konsole) draws
#  the text, so the Nerd Font only has to be installed on the host.
# =============================================================================

# ESP-IDF release to build on. Change it here to move to a new ESP-IDF.
ARG IDF_VERSION=v6.1
FROM docker.io/espressif/idf:${IDF_VERSION}

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/usr/bin/zsh \
    EDITOR=nvim

# -----------------------------------------------------------------------------
# Command-line tools from Ubuntu 24.04
# -----------------------------------------------------------------------------
#   zsh            default shell (with Oh My Zsh, below)
#   tmux           terminal multiplexer
#   ripgrep, fd    used by kickstart.nvim's Telescope (Ubuntu calls fd "fdfind")
#   udev           device information for esptool/OpenOCD
#   less           pager for git and man
# -----------------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends zsh tmux ripgrep fd-find udev less \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Neovim: official release, version and checksums pinned
# -----------------------------------------------------------------------------
# Ubuntu's own Neovim is too old for kickstart.nvim. To update: change the
# version and both checksums (from the release page on GitHub).
# -----------------------------------------------------------------------------
ARG NVIM_VERSION=v0.12.6
ARG NVIM_SHA256_X86_64=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
ARG NVIM_SHA256_ARM64=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815
RUN case "$(uname -m)" in \
        x86_64)  arch=x86_64; sum="$NVIM_SHA256_X86_64" ;; \
        aarch64) arch=arm64;  sum="$NVIM_SHA256_ARM64" ;; \
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${arch}.tar.gz" \
 && echo "${sum}  /tmp/nvim.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/nvim.tar.gz -C /opt \
 && ln -s "/opt/nvim-linux-${arch}/bin/nvim" /usr/local/bin/nvim \
 && rm /tmp/nvim.tar.gz

# -----------------------------------------------------------------------------
# tree-sitter CLI: official release, version and checksums pinned
# -----------------------------------------------------------------------------
# nvim-treesitter uses it to build language parsers; Ubuntu's is too old.
# -----------------------------------------------------------------------------
ARG TREE_SITTER_VERSION=v0.27.1
ARG TREE_SITTER_SHA256_X86_64=d01042f94ba3d6827ddc9788e235f75d8366431be42bdf90ade534d960c98b7d
ARG TREE_SITTER_SHA256_ARM64=404be5d54a4955571c4067c21d4699660eab3a534cefb0659341b207f7139ec5
RUN case "$(uname -m)" in \
        x86_64)  arch=x64;   sum="$TREE_SITTER_SHA256_X86_64" ;; \
        aarch64) arch=arm64; sum="$TREE_SITTER_SHA256_ARM64" ;; \
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/tree-sitter.gz \
        "https://github.com/tree-sitter/tree-sitter/releases/download/${TREE_SITTER_VERSION}/tree-sitter-linux-${arch}.gz" \
 && echo "${sum}  /tmp/tree-sitter.gz" | sha256sum -c - \
 && gunzip -c /tmp/tree-sitter.gz > /usr/local/bin/tree-sitter \
 && chmod 755 /usr/local/bin/tree-sitter \
 && rm /tmp/tree-sitter.gz

# -----------------------------------------------------------------------------
# Oh My Zsh, pinned to one commit (the project has no release tags)
# -----------------------------------------------------------------------------
# Auto-update is off in files/zshrc: the version only changes here.
# -----------------------------------------------------------------------------
ARG OHMYZSH_COMMIT=964ddf789b022b6958b27d02d7fa54f552de21e9
RUN git init -q /root/.oh-my-zsh \
 && git -C /root/.oh-my-zsh fetch -q --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OHMYZSH_COMMIT" \
 && git -C /root/.oh-my-zsh checkout -q FETCH_HEAD \
 && rm -rf /root/.oh-my-zsh/.git
COPY files/zshrc /root/.zshrc

# -----------------------------------------------------------------------------
# Claude Code CLI (official native installer, into /root/.local)
# -----------------------------------------------------------------------------
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH=/root/.local/bin:$PATH

# Espressif's entrypoint loads ESP-IDF (export.sh), then runs the command.
ENTRYPOINT ["/opt/esp/entrypoint.sh"]
CMD ["zsh"]
