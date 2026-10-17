#!/usr/bin/env bash
# =============================================================================
#  NFZ-ESP-DEV — build.sh
# =============================================================================
#  Builds the image for the architecture of the machine it runs on, checks
#  the tools inside, and optionally pushes it. Runs as your own user (rootless
#  podman): no sudo, so a push can't stall on a password prompt.
#
#  Usage (from anywhere; the script always works in its own folder):
#    ./build.sh           build and check only
#    ./build.sh --push    build, check, then push both tags
#
#  Tags produced (ARCH = this machine's architecture, e.g. x86_64 or aarch64):
#    <REGISTRY>/<REGISTRY_USER>/<IMAGE_NAME>:latest-<ARCH>
#    <REGISTRY>/<REGISTRY_USER>/<IMAGE_NAME>:<VERSION>-<ARCH>
#
#  The registry login is kept in AUTH_FILE (survives reboots). Log in once per
#  build machine, e.g. with the quay robot account (needs Write on the repo):
#    echo '<token>' | podman login quay.io -u '<user>+builder' \
#        --password-stdin --authfile ~/.config/containers/auth.json
#
#  The full build output is saved to build.log (ignored by git).
# =============================================================================
set -euo pipefail

# --- Settings ----------------------------------------------------------------
REGISTRY="${REGISTRY:-quay.io}"
REGISTRY_USER="${REGISTRY_USER:-quizzical0902}"
IMAGE_NAME="${IMAGE_NAME:-nfz-esp-dev}"
AUTH_FILE="${AUTH_FILE:-$HOME/.config/containers/auth.json}"
LOG_FILE="build.log"

# --- Arguments ----------------------------------------------------------------
case "${1:-}" in
    "")     PUSH=0 ;;
    --push) PUSH=1 ;;
    *)      echo "Usage: $0 [--push]" >&2; exit 2 ;;
esac

# --- Checks -------------------------------------------------------------------
cd "$(dirname "$(readlink -f "$0")")"

[[ -f VERSION && -f Containerfile ]] || {
    echo "ERROR: VERSION or Containerfile not found in $(pwd)" >&2
    exit 1
}
VERSION=$(tr -d '[:space:]' < VERSION)
[[ "$VERSION" =~ ^[0-9]+$ ]] || {
    echo "ERROR: VERSION must be a whole number, got '$VERSION'" >&2
    exit 1
}

ARCH=$(uname -m)
IMAGE="$REGISTRY/$REGISTRY_USER/$IMAGE_NAME"
TAG_LATEST="$IMAGE:latest-$ARCH"
TAG_VERSION="$IMAGE:$VERSION-$ARCH"

echo "==> Building $TAG_VERSION (also tagged $TAG_LATEST)"
echo "==> Log: $(pwd)/$LOG_FILE"

# --- Build --------------------------------------------------------------------
# --pull=newer: pick up a rebuilt ESP-IDF base image of the same release
podman build --pull=newer -t "$TAG_LATEST" -t "$TAG_VERSION" . 2>&1 | tee "$LOG_FILE"

# --- Check the result ---------------------------------------------------------
# Runs through the entrypoint, so ESP-IDF is loaded (idf.py, esp-clangd)
echo
echo "=== Tools in the image ==="
podman run --rm "$TAG_VERSION" bash -c '
    set -e
    idf.py --version
    clangd --version | head -1
    nvim --version | head -1
    tree-sitter --version
    zsh --version
    tmux -V
    rg --version | head -1
    fd --version
    claude --version
' 2>&1 | tee -a "$LOG_FILE"
echo "Build OK: $TAG_VERSION"

# --- Push ---------------------------------------------------------------------
if (( PUSH )); then
    mkdir -p "$(dirname "$AUTH_FILE")"
    podman login --authfile "$AUTH_FILE" --get-login "$REGISTRY" >/dev/null 2>&1 \
        || podman login --authfile "$AUTH_FILE" "$REGISTRY"
    podman push --authfile "$AUTH_FILE" "$TAG_LATEST"
    podman push --authfile "$AUTH_FILE" "$TAG_VERSION"
    echo "Pushed: $TAG_LATEST and $TAG_VERSION"
else
    echo
    echo "Not pushed. To push this build:  ./build.sh --push"
    echo "or:"
    echo "  podman push --authfile $AUTH_FILE $TAG_LATEST"
    echo "  podman push --authfile $AUTH_FILE $TAG_VERSION"
fi
