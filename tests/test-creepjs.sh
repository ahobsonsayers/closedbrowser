#!/bin/bash
# CreepJS test

echo "Fetching..."
HTML=$(curl -s "http://localhost:3000/content?headless=false" \
	-H "Content-Type: application/json" \
	-X POST \
	-d '{"url":"https://abrahamjuliot.github.io/creepjs/","waitForTimeout":15000}')

echo ""
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
