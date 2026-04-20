#!/usr/bin/env bash
# CreepJS test - checks for bot detection scores

set -euo pipefail

BROWSER_URL="ws://localhost:3000/?headless=false&stealth=true"
TEST_URL="https://abrahamjuliot.github.io/creepjs/"

# Cleanup on exit
cleanup() { browser-use close 2>/dev/null || true; }
trap cleanup EXIT

browser-use close 2>/dev/null || true
browser-use --cdp-url "$BROWSER_URL" open "$TEST_URL"
sleep 10

HTML=$(browser-use get html)

echo "SCORES:"
echo "$HTML" | grep -oE '[0-9]+% (like headless|headless|stealth)' | head -3

echo ""
echo "LIKE HEADLESS:"
echo "$HTML" | grep -oE '(noChrome|hasPermissionsBug|noPlugins|noMimeTypes|notificationIsDenied|hasKnownBgColor|prefersLightColor|uaDataIsBlank|pdfIsDisabled|noTaskbar|hasVvpScreenRes|hasSwiftShader|noWebShare|noContentIndex|noContactsManager|noDownlinkMax): (true|false)' | head -20

echo ""
echo "HEADLESS:"
echo "$HTML" | grep -oE '(webDriverIsOn|hasHeadlessUA|hasHeadlessWorkerUA): (true|false)' | head -5

echo ""
echo "STEALTH:"
echo "$HTML" | grep -oE '(hasIframeProxy|hasHighChromeIndex|hasBadChromeRuntime|hasToStringProxy|hasBadWebGL): (true|false)' | head -5
