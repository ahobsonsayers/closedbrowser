---
name: closedbrowser
description: Browser automation using closedbrowser (containerized Chromium via CDP). Use when the user needs to automate browser tasks with a remote CDP endpoint, especially when CLOSEDBROWSER_URL is configured. Always use this skill when the user mentions closedbrowser, remote browser automation, CDP WebSocket connections, or browser automation with CLOSEDBROWSER_URL environment variable.
allowed-tools: Bash(agent-browser:*), Bash(browser-use:*), Bash(echo:*), Bash(printenv:*), Bash(which:*)
required_environment_variables:
  - name: CLOSEDBROWSER_URL
    prompt: ClosedBrowser WebSocket URL
    help: WebSocket URL for connecting to ClosedBrowser (e.g., ws://localhost:9999)
  - name: CLOSEDBROWSER_TOKEN
    prompt: ClosedBrowser Auth Token
    help: Token for authenticating to ClosedBrowser
---

# closedbrowser automation

Browser automation via CLI connecting to an external browser over CDP WebSocket. Supports two backends: **agent-browser** and **browser-use**.

## Step 1: Check Environment and Tools

Run this single check before doing anything else:

```bash
printenv | grep ^CLOSEDBROWSER_ && echo "agent-browser: $(which agent-browser 2>/dev/null || echo NOT_FOUND)" && echo "browser-use: $(which browser-use 2>/dev/null || echo NOT_FOUND)"
```

If any `CLOSEDBROWSER_*` vars appear in output, they are **not set**.

**If CLOSEDBROWSER_URL is not set, stop and ask the user to set it.** Nothing else matters without it.

**CLOSEDBROWSER_TOKEN is optional** — only required if the container was started with a `TOKEN` environment variable.

**Normalize the URL if needed:**
- Has a port (e.g., `localhost:9999`) → `ws://` (local, no SSL)
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
agent-browser --cdp ws://localhost:9999 open https://example.com
```

### Token: MUST Use $VAR Substitution (REQUIRED)

**The token must NEVER appear in tool call output.** Always use shell substitution:

```bash
# WRONG - token exposed in tool output (SECURITY VIOLATION)
agent-browser --cdp ws://localhost:9999/?token=abc123secret open https://example.com

# WRONG - do not read token into a variable and use it literally
TOKEN_VALUE=$(printenv CLOSEDBROWSER_TOKEN)
agent-browser --cdp ws://localhost:9999/?token=$TOKEN_VALUE open https://example.com

# CORRECT - use $CLOSEDBROWSER_TOKEN substitution
agent-browser --cdp ws://localhost:9999/?token=$CLOSEDBROWSER_TOKEN open https://example.com
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
- **Default profile**: If `CLOSEDBROWSER_DEFAULT_PROFILE` is set, use it by default (literal value, not substitution). Skip only when user explicitly says: no persistence, different profile, or no profile/session. **Only one session can use a given profile at a time** — don't run multiple agents with the same profile simultaneously.

## Query Parameters

Reference: [Browserless Launch Options](https://docs.browserless.io/baas/launch-options)

All query parameters are common to both agent-browser and browser-use. Append them to the CDP WebSocket URL after a trailing slash.

**Critical: Always use a trailing slash before query params** — without it the server returns 400.

```
# Correct
ws://localhost:9999/?headless=false&stealth=true

# WRONG — missing slash, will 400
ws://localhost:9999?headless=false&stealth=true
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
ws://localhost:9999/?headless=false&stealth=true&blockAds=true&timeout=120000
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

## The `launch` Object

The `launch` object is a JSON string passed as a single query parameter. Use it for browser-level options like `headless`, `stealth`, or array flags like `args: [...]`.

### Launch Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `args` | Array of Chrome command-line flags (see Chrome Flags section) | `[]` |
| `headless` | Run browser headless. Set `false` for headful mode (helps bypass bot detection) | `true` |
| `stealth` | Enable stealth mode to reduce automation signals | `false` |
| `slowMo` | Delay between actions in milliseconds | `0` |
| `ignoreDefaultArgs` | Ignore default browser args (boolean or array) | `false` |
| `acceptInsecureCerts` | Accept invalid SSL certificates | `false` |

### Encoding the `launch` Value

**URL encoding:**
```
?launch=%7B%22headless%22%3Afalse%2C%22stealth%22%3Atrue%2C%22args%22%3A%5B%22--window-size%3D1920%2C1080%22%5D%7D
```

**Base64 (simpler):**
```
?launch=eyJoZWFkbGVzcyI6ZmFsc2UsInN0ZWFsdCI6dHJ1ZSwiYXJncyI6WyItLXdpbmRvdy1zaXplPTE5MjAsMTA4MCJdfQ==
```

Decoded: `{"headless":false,"stealth":true,"args":["--window-size=1920,1080"]}`

## Chrome Flags

Chrome flags are passed via the `args` array inside the `launch` object.

### Available Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--window-size` | Browser window size | `"--window-size=1920,1080"` |
| `--lang` | Browser language | `"--lang=en-US"` |
| `--user-data-dir` | Profile directory for persistence | `"--user-data-dir=/data/profiles/my-session"` |
| `--proxy-server` | Proxy server (host:port) | `"--proxy-server=proxy.com:8080"` |

See [Chrome Command-Line Switches](https://peter.sh/experiments/chromium-command-line-switches/) for others.

### Example: Multiple Flags

```json
{"headless":false,"stealth":true,"args":["--window-size=1920,1080","--lang=en-US"]}
```

**Base64:** `eyJoZWFkbGVzcyI6ZmFsc2UsInN0ZWFsdGgiOnRydWUsImFyZ3MiOlsiLS13aW5kb3ctc2l6ZT0xOTIwLDEwODAiLCItLWxhbmc9ZW4tVVMiXX0K`

For full details, see [Browserless Launch Options](https://docs.browserless.io/baas/launch-options).

## Persistent Profiles (user-data-dir)

Use the `--user-data-dir` Chrome flag to persist browser data (cookies, localStorage, etc.) across sessions. The container mounts profiles at `/data/profiles/<name>`.

### Profile Directory Structure

```
/data/profiles/
  my-session/      # Chrome profile directory
  another-profile/ # Another profile
```

### Usage

```json
{"args":["--user-data-dir=/data/profiles/my-session"]}
```

**Base64:** `eyJhcmdzIjpbIi0tdXNlci1kYXRhLWRpcj0vZGF0YS9wcm9maWxlcy9teS1zZXNzaW9uIl19`

Decoded: `{"args":["--user-data-dir=/data/profiles/my-session"]}`

### Default Behavior (No Persistence)

By default, closedbrowser automatically creates a temporary user-data-dir and disposes of it after disconnect — there is **no persistence**. Use `--user-data-dir` only when you need data to persist across sessions.

### Notes

- **Always use this when the user mentions a named session or profile**, or if they want persistence — ask them what to call it
- Use different profile names for different users/sessions to avoid state pollution

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
