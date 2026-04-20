#!/usr/bin/env bash
set -euo pipefail

# Patch browserless to load all extensions in the global and
# user extensions directories on browser session start.
git -C "$APP_DIR" apply /tmp/patches/browsers.cdp.patch
