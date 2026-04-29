#!/usr/bin/env bash
set -euo pipefail

# Patch browserless to load all extensions in the global and
# user extensions directories on browser session start.
git -C "$APP_DIR" apply /tmp/patches/blockads-default.patch
git -C "$APP_DIR" apply /tmp/patches/extensions-load.patch
