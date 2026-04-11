#!/usr/bin/env bash
set -euo pipefail

# Patch wrapper.sh if it exists (onkernel base image only)
if [[ -f /wrapper.sh ]]; then
	# Patch wrapper.sh to add a line at the top which cleans up any stale X11 lock/socket from a previous run
	sed -i '2i rm -f /tmp/.X1-lock /tmp/.X11-unix/X1' /wrapper.sh

	# Patch wrapper.sh to look for the brave new tab wording over the chromium new tab wording
	sed -i "s|target='New Tab - Chromium'|target='New Tab - Brave'|" /wrapper.sh
fi
