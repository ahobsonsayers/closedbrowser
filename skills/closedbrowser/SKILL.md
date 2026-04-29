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
echo "CLOSEDBROWSER_URL: $(printenv CLOSEDBROWSER_URL || echo NOT_SET)" && echo "agent-browser: $(which agent-browser 2>/dev/null || echo NOT_FOUND)" && echo "browser-use: $(which browser-use 2>/dev/null || echo NOT_FOUND)"
```

**If CLOSEDBROWSER_URL is not set, stop and ask the user to set it.** Nothing else matters without it.

**Normalize the URL if needed:**
- Has a port (e.g., `localhost:3000`) → `ws://` (local, no SSL)
- No port (e.g., `browser.example.com`) → `wss://` (remote, SSL)
- On connection failure, try the other protocol

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

## Shared Rules

- **Never install tools for the user** — only provide instructions
- **Never launch a local browser** — this skill only connects to an external browser via CDP
- **Always use literal URL values** — read `CLOSEDBROWSER_URL` once, then use the actual value in all commands; never use `$CLOSEDBROWSER_URL` shell substitutions

## Anti-Bot Protection (Headful + Stealth)

**When in doubt, use headful + stealth — it does no harm on unprotected sites.**

For any site with bot detection (Cloudflare, DataDome, Akamai, CAPTCHAs, or unexpected blocks), append `/?headless=false&stealth=true` to the CDP URL.

**The trailing slash before `?` is critical** — without it the server returns 400.

```
# Correct
ws://localhost:3000/?headless=false&stealth=true

# WRONG — missing slash, will 400
ws://localhost:3000?headless=false&stealth=true
```

Always use both flags together — never just one.

## Troubleshooting

| Error | Action |
|-------|--------|
| Connection refused | Check URL, protocol (`ws://` vs `wss://`), and that the container is running. Try the other protocol. |
| 400 Bad Request with query params | Missing trailing slash — use `ws://host:port/?...`, not `ws://host:port?...`. |
| Site blocked / CAPTCHA | Close and reconnect with `/?headless=false&stealth=true` on the CDP URL. |
| CDP connection dropped / session expired | Remote browser closed due to inactivity or session timeout. Add `timeout` query param to extend lifetime, e.g. `ws://localhost:3000/?headless=false&stealth=true&timeout=120000`. Increase further for long-running sessions. |

See the tool-specific reference file for additional troubleshooting.
