#!/usr/bin/env bash
set -euo pipefail

git -C "$APP_DIR" apply /tmp/patches/blockads-default.patch
git -C "$APP_DIR" apply /tmp/patches/dashboard-start.patch
git -C "$APP_DIR" apply /tmp/patches/extensions-load.patch
