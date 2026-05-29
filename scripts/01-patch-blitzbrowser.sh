#!/usr/bin/env bash
set -euo pipefail

# Patch blitzbrowser to add --no-sandbox flag.
patch -i /tmp/patches/no-sandbox.patch "$APP_DIR/src/components/browser-instance.process.ts"