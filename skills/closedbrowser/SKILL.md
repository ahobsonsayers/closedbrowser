---
name: closedbrowser
description: Browser automation using closedbrowser (containerized Chromium via CDP). Use when the user needs to automate browser tasks with a remote CDP endpoint, especially when CLOSEDBROWSER_URL is configured. Always use this skill when the user mentions closedbrowser, remote browser automation, CDP WebSocket connections, or browser automation with CLOSEDBROWSER_URL environment variable.
allowed-tools: Bash(agent-browser:*), Bash(browser-use:*), Bash(echo:*), Bash(printenv:*), Bash(which:*)
required_environment_variables:
  - name: CLOSEDBROWSER_URL
    prompt: ClosedBrowser WebSocket URL
    help: WebSocket URL for connecting to ClosedBrowser (e.g., ws://localhost:9999)
  - name: CLOSEDBROWSER_API_KEY
    prompt: ClosedBrowser API Key
    help: API key for authenticating to the ClosedBrowser container
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

**CLOSEDBROWSER_API_KEY is optional** — only required if the container was started with `API_KEY` set.

**Normalize the URL if needed:**
- Has a port (e.g., `localhost:9999`) → `ws://` (local, no SSL)
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

### API Key: MUST Use $VAR Substitution (REQUIRED)

**The API key must NEVER appear in tool call output.** Always use shell substitution:

```bash
# WRONG - API key exposed in tool output (SECURITY VIOLATION)
agent-browser --cdp ws://localhost:9999/?apiKey=abc123secret open https://example.com

# WRONG - do not read API key into a variable and use it literally
API_KEY_VALUE=$(printenv CLOSEDBROWSER_API_KEY)
agent-browser --cdp ws://localhost:9999/?apiKey=$API_KEY_VALUE open https://example.com

# CORRECT - use $CLOSEDBROWSER_API_KEY substitution
agent-browser --cdp ws://localhost:9999/?apiKey=$CLOSEDBROWSER_API_KEY open https://example.com
```

**Why this matters:** Tool call logs are persisted. Exposed API keys = security breach.

### Quick Reference

| Variable | Use In Commands | Why |
|----------|-----------------|-----|
| `CLOSEDBROWSER_URL` | Literal value (resolve once) | Not secret, but cleaner logs |
| `CLOSEDBROWSER_API_KEY` | `$CLOSEDBROWSER_API_KEY` | NEVER exposed in output |

## Shared Rules

- **Never install tools for the user** — only provide instructions
- **Never launch a local browser** — this skill only connects to an external browser via CDP
- **Default profile**: If `CLOSEDBROWSER_DEFAULT_PROFILE` is set, use it by default (literal value, not substitution). Skip only when user explicitly says: no persistence, different profile, or no profile/session. **Only one session can use a given profile at a time** — don't run multiple agents with the same profile simultaneously.

## Query Parameters

All query parameters are common to both agent-browser and browser-use. Append them to the CDP WebSocket URL after a trailing slash.

**Critical: Always use a trailing slash before query params** — without it the server returns 400.

```
# Correct
ws://localhost:9999/?apiKey=$CLOSEDBROWSER_API_KEY&userDataId=default&liveView=true

# WRONG — missing slash, will 400
ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY&userDataId=default&liveView=true
```

### Supported Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `apiKey` | API key for authentication | Only if container has `API_KEY` set |
| `userDataId` | Session ID for persisting browser data (cookies, localStorage) | Optional |
| `liveView` | Enable live view for real-time interaction | Optional |
| `timezone` | Override browser timezone (not recommended) | Optional |
| `proxyUrl` | HTTP proxy URL: `http://user:pass@host:port` | Optional |
| `browserVersion` | Chrome version: `default`, `latest`, or specific version | Optional |
| `userDataReadOnly` | Use user data without saving changes (`true`/`false`) | Optional |

### User Data (Sessions)

Use `userDataId` to persist browser sessions:
- Same `userDataId` reuses cookies, localStorage, etc.
- Different ID for fresh session
- Valid pattern: `/^[a-zA-Z0-9-_]{1,64}$/`
- User data is downloaded before starting and saved at the end of the session

### Examples

```
# Basic connection
ws://localhost:9999/

# With authentication and session
ws://localhost:9999/?apiKey=$CLOSEDBROWSER_API_KEY&userDataId=abc&liveView=true

# With proxy
ws://localhost:9999/?proxyUrl=http://user:pass@proxy.com:1080&userDataId=123
```

## Troubleshooting

| Error | Action |
|-------|--------|
| Connection refused | Check URL, protocol (`ws://` vs `wss://`), and that the container is running. Try the other protocol. |
| 400 Bad Request with query params | Missing trailing slash — use `ws://host:port/?...`, not `ws://host:port?...`. |
| 401 Unauthorized | Missing or invalid `apiKey` — verify `$CLOSEDBROWSER_API_KEY` |
| "Session is already running with different config" | Use different `userDataId` or close existing session first |
| CDP connection dropped / session expired | Remote browser closed due to inactivity. Check container logs. |
| Live view not working | Ensure `liveView=true` in URL params |

See the tool-specific reference file for additional troubleshooting.
