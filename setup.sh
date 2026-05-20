#!/usr/bin/env bash
# setup.sh — fetch the upstream submodules.
#
# Idempotent. Safe to re-run. Works in Git Bash on Windows, Linux, and macOS.
#
# If you cloned this repo with `git clone --recurse-submodules`, the
# submodules are already present and this script is a no-op.

set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .gitmodules ]; then
    echo "Error: .gitmodules not found — are you in the right directory?" >&2
    exit 1
fi

echo "[setup] Initializing submodules..."
git submodule update --init --recursive

echo
echo "Setup complete. Next:"
echo "  ./build.sh"
