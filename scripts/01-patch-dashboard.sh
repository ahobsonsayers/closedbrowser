#!/bin/sh
set -e

cd /blitzbrowser

git apply /tmp/patches/dashboard-ws-protocol.patch
