---
name: closedbrowser
description: Browser automation using closedbrowser (containerized Chromium via CDP). Use when the user needs to automate browser tasks with a remote CDP endpoint, especially when CLOSEDBROWSER_URL is configured. Always use this skill when the user mentions closedbrowser, remote browser automation, CDP WebSocket connections, or browser automation with CLOSEDBROWSER_URL environment variable.
allowed-tools: Bash(agent-browser:*), Bash(browser-use:*), Bash(echo:*), Bash(printenv:*), Bash(which:*)
---

# closedbrowser automation

Browser automation via CLI connecting to an external browser over CDP WebSocket. Supports two backends: **agent-browser** and **browser-use**.

## Step 1: Check Environment and Tools

Run this single check before doing anything else:

```bash
echo "CLOSEDBROWSER_URL: $(printenv CLOSEDBROWSER_URL || echo NOT_SET)" && echo "CLOSEDBROWSER_TOKEN: $(printenv CLOSEDBROWSER_TOKEN || echo NOT_SET)" && echo "agent-browser: $(which agent-browser 2>/dev/null || echo NOT_FOUND)" && echo "browser-use: $(which browser-use 2>/dev/null || echo NOT_FOUND)"
```

**If CLOSEDBROWSER_URL is not set, stop and ask the user to set it.** Nothing else matters without it.

**CLOSEDBROWSER_TOKEN is optional** — only required if the container was started with a `TOKEN` environment variable.

**Normalize the URL if needed:**
- Has a port (e.g., `localhost:3000`) → `ws://` (local, no SSL)
- No port (e.g., `browser.example.com`) → `wss://` (remote, SSL)
- On connection failure, try the other protocol
- If `CLOSEDBROWSER_TOKEN` is set, append as query param after trailing slash: `/?token=$CLOSEDBROWSER_TOKEN` (use substitution, never literal)

Then select a tool:

| Result | Action |
|--------|--------|
| Only agent-browser found | Read `agent-browser.md` in this skill directory. |
| Only browser-use found | Read `browser-use.md` in this skill directory. |
| Both found | Ask the user which they prefer. Wait for answer, then read the corresponding file. |
| Neither found | Tell the user they need one of the tools below, then **stop and wait**. Never install for the user. |

**Installation instructions (provide to user, never run yourself):**
- agent-browser: `brew install agent-browser` — see https://agent-browser.dev/installation
- browser-use: `curl -fsSL https://browser-use.com/cli/install.sh | bash` — see https://docs.browser-use.com/open-source/browser-use-cli

## CRITICAL SECURITY RULE: Variable Substitution

**This is non-negotiable. Violating this exposes secrets in tool call logs.**

### URL: Use LITERAL Value (NO substitution)

Read `CLOSEDBROWSER_URL` once at startup, then use the **actual resolved value** in all commands:

```bash
# WRONG - variable expansion visible in tool output
agent-browser --cdp "$CLOSEDBROWSER_URL" open https://example.com

# CORRECT - resolve once, use literal value
agent-browser --cdp ws://localhost:3000 open https://example.com
```

### Token: MUST Use $VAR Substitution (REQUIRED)

**The token must NEVER appear in tool call output.** Always use shell substitution:

```bash
# WRONG - token exposed in tool output (SECURITY VIOLATION)
agent-browser --cdp ws://localhost:3000/?token=abc123secret open https://example.com

# WRONG - do not read token into a variable and use it literally
TOKEN_VALUE=$(printenv CLOSEDBROWSER_TOKEN)
agent-browser --cdp ws://localhost:3000/?token=$TOKEN_VALUE open https://example.com

# CORRECT - use $CLOSEDBROWSER_TOKEN substitution
agent-browser --cdp ws://localhost:3000/?token=$CLOSEDBROWSER_TOKEN open https://example.com
```

**Why this matters:** Tool call logs are persisted. Exposed tokens = security breach.

### Quick Reference

| Variable | Use In Commands | Why |
|----------|-----------------|-----|
| `CLOSEDBROWSER_URL` | Literal value (resolve once) | Not secret, but cleaner logs |
| `CLOSEDBROWSER_TOKEN` | `$CLOSEDBROWSER_TOKEN` | NEVER exposed in output |

## Shared Rules

- **Never install tools for the user** — only provide instructions
- **Never launch a local browser** — this skill only connects to an external browser via CDP

## Query Parameters

Reference: [Browserless Launch Options](https://docs.browserless.io/baas/launch-options)

All query parameters are common to both agent-browser and browser-use. Append them to the CDP WebSocket URL after a trailing slash.

**Critical: Always use a trailing slash before query params** — without it the server returns 400.

```
# Correct
ws://localhost:3000/?headless=false&stealth=true

# WRONG — missing slash, will 400
ws://localhost:3000?headless=false&stealth=true
```

### Supported Parameters

| Parameter | Description | Docs |
|-----------|-------------|------|
| `token` | Authorization token | ✅ |
| `timeout` | Session timeout in ms (default 60000) | ✅ |
| `blockAds` | Enable ad blocker (uBlock Origin) | ✅ |
| `headless` | Run headless (`true`/`false`) — use `false` for bot protection | ✅ |
| `stealth` | Enable stealth mode | ✅ |
| `slowMo` | Delay between actions (ms) | ✅ |
| `ignoreDefaultArgs` | Ignore default browser args | ✅ |
| `acceptInsecureCerts` | Accept invalid SSL certs | ✅ |
| `launch` | JSON launch options (URL/base64 encoded) | ✅ |

### Chrome Flags (via `--` prefix)

Any Chrome flag can be passed with `--` prefix:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--proxy-server` | Proxy server (host:port) | `?--proxy-server=proxy.com:8080` |
| `--window-size` | Browser window size | `?--window-size=1920,1080` |
| `--lang` | Browser language | `?--lang=en-US` |

### Not Yet Supported

These are in the docs but not implemented in this container:
- `proxy`, `proxyCountry`, `proxyCity`, `proxySticky`, `proxyLocaleMatch`, `proxyPreset` — residential proxy features
- `externalProxyServer` — custom proxy URL
- `record`, `replay` — session recording
- `profile` — authenticated profiles
- `humanlike` — human behavior simulation
- `blockConsentModals` — cookie consent blocking

### Combining Parameters

Parameters combine in order. Later params override earlier ones:

```
ws://localhost:3000/?headless=false&stealth=true&blockAds=true&timeout=120000
```

### The `launch` Parameter

For complex configurations, use the `launch` parameter with a JSON object. Encode with URL encoding or base64:

```bash
# URL encoded
?launch=%7B%22headless%22%3Afalse%2C%22stealth%22%3Atrue%2C%22args%22%3A%5B%22--window-size%3D1920%2C1080%22%5D%7D

# base64 (simpler)
?launch=eyJoZWFkbGVzcyI6ZmFsc2UsInN0ZWFsdCI6dHJ1ZSwiYXJncyI6WyItLXdpbmRvdy1zaXplPTE5MjAsMTA4MCJdfQ==
```

JSON options: `headless`, `stealth`, `slowMo`, `ignoreDefaultArgs`, `acceptInsecureCerts`, `args` (Chrome flags array).

For full details, see [Browserless Launch Options](https://docs.browserless.io/baas/launch-options).

## Anti-Bot Protection (Headful + Stealth)

**When in doubt, use headful + stealth — it does no harm on unprotected sites.**

For any site with bot detection (Cloudflare, DataDome, Akamai, CAPTCHAs, or unexpected blocks), add `headless=false&stealth=true` to your URL.

Always use both flags together — never just one.

See **Query Parameters** section above for the full list of available options.

## Troubleshooting

| Error | Action |
|-------|--------|
| Connection refused | Check URL, protocol (`ws://` vs `wss://`), and that the container is running. Try the other protocol. |
| 400 Bad Request with query params | Missing trailing slash — use `ws://host:port/?...`, not `ws://host:port?...`. |
| Site blocked / CAPTCHA | Close and reconnect with `headless=false&stealth=true` on the CDP URL. |
| CDP connection dropped / session expired | Remote browser closed due to inactivity or session timeout. Add `timeout` query param to extend lifetime. See Query Parameters section. |

See the tool-specific reference file for additional troubleshooting.
