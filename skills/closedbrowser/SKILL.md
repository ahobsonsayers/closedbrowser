---
name: closedbrowser
description: Use when automating browser tasks via remote CDP endpoint or WebSocket, especially with CLOSEDBROWSER_API_URL configured. Also triggers on live view, live share, closedbrowser, containerized Chromium, or remote browser automation.
allowed-tools: Bash(agent-browser:*), Bash(browser-use:*), Bash(echo:*), Bash(printenv:*), Bash(which:*)
required_environment_variables:
  - name: CLOSEDBROWSER_API_URL
    prompt: CDP WebSocket URL with scheme (e.g., ws://localhost:9999)
    help: The main CDP endpoint. Must be set or the agent cannot connect.
  - name: CLOSEDBROWSER_API_KEY
    prompt: API key (if the container requires auth)
    help: Optional. Only needed if the container was started with API_KEY set.
  - name: CLOSEDBROWSER_DASHBOARD_URL
    prompt: Dashboard base URL (e.g., https://browser.example.com)
    help: Required for live view / live share. If unset and the user requests a live view URL, ask the user: "What is the URL of the dashboard?"
  - name: CLOSEDBROWSER_DEFAULT_PROFILE
    prompt: Default profile name (e.g., my-profile)
    help: Unset by default. Set this to persist cookies/login across sessions. All data is lost on close if this is not set and no userDataId is provided.
---

# closedbrowser automation

Connect to remote Chromium via CDP WebSocket. Supports **agent-browser** and **browser-use** backends.

## Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `CLOSEDBROWSER_API_URL` | Yes | CDP WebSocket URL (e.g., `ws://localhost:9999`) |
| `CLOSEDBROWSER_API_KEY` | No | API key (only if container requires auth) |
| `CLOSEDBROWSER_DASHBOARD_URL` | No | Dashboard base URL — **required for live view** |
| `CLOSEDBROWSER_DEFAULT_PROFILE` | No | **Unset by default**. Set to persist cookies/login across sessions. |

**Security:**
- API URL → use **literal value** in commands
- API key → use **`$CLOSEDBROWSER_API_KEY`** substitution (never show in tool output)

## Step 1: Check Environment and Select Tool

```bash
printenv CLOSEDBROWSER_API_URL && echo "OK" || echo "MISSING"
echo "agent-browser: $(which agent-browser 2>/dev/null || echo NOT_FOUND)"
echo "browser-use: $(which browser-use 2>/dev/null || echo NOT_FOUND)"
```

**If `CLOSEDBROWSER_API_URL` is MISSING: stop and ask the user to set it.**

**Normalize URL:** has port → `ws://`; no port → `wss://`. On failure try the other.

**Select tool:**

| Found | Action |
|-------|--------|
| Only agent-browser | Read `agent-browser.md` |
| Only browser-use | Read `browser-use.md` |
| Both | Ask user which they prefer |
| Neither | Give install instructions, **stop and wait** |

**Install instructions (provide, never run):**
- agent-browser: `brew install agent-browser` — https://agent-browser.dev/installation
- browser-use: `curl -fsSL https://browser-use.com/cli/install.sh | bash` — https://docs.browser-use.com/open-source/browser-use-cli

## Rules

- **Never install tools for the user**
- **Never launch a local browser** — only external CDP
- **Always include `apiKey` in the URL** — if `CLOSEDBROWSER_API_KEY` is set, the CDP URL **must** include `?apiKey=$CLOSEDBROWSER_API_KEY`. Without it, the connection will close immediately with no useful error. This is the most common failure mode.
- **Default profile:** Use `CLOSEDBROWSER_DEFAULT_PROFILE` if set. Do NOT set `userDataId` manually. Override only if user explicitly says: no persistence, different profile, or no profile.
- **No profile:** If user requests anonymous/temp/private OR `CLOSEDBROWSER_DEFAULT_PROFILE` is not set AND user says "no profile", **omit `userDataId` entirely**. Warn: "All browser state will be lost on close. Set CLOSEDBROWSER_DEFAULT_PROFILE for persistence."
- **Stale sessions:** If a previous session exists in a "failed" or unexpected state, close it before opening a new one. Always close before reconnecting.
- **Close the browser when done.** Closing frees resources and is best practice. But closing destroys all browser state — only close when you are absolutely certain all work is finished. If there is any doubt, ask the user before closing.

## Query Parameters

Query params go directly after the host: `ws://host:port?...`

| Parameter | Required | Description |
|-----------|----------|-------------|
| `apiKey` | Only if `API_KEY` set | Authentication |
| `userDataId` | Optional | Session profile. Uses `CLOSEDBROWSER_DEFAULT_PROFILE` by default. |
| `liveView` | Optional | Enable real-time interaction |
| `proxyUrl` | Optional | `http://user:pass@host:port` |
| `timezone` | Optional | Override browser timezone |
| `browserVersion` | Optional | `default`, `latest`, or specific version |

**User data pattern:** `/^[a-zA-Z0-9-_]{1,64}$/`

### Examples

```bash
# Uses default profile if CLOSEDBROWSER_DEFAULT_PROFILE is set
ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY

# With live view
ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY&userDataId=$CLOSEDBROWSER_DEFAULT_PROFILE&liveView=true

# With proxy
ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY&proxyUrl=http://user:pass@proxy:8080
```

## Live View

Live view **cannot be toggled** on an existing session. Close and reconnect:

```bash
# Enable
agent-browser --cdp "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" close
agent-browser --cdp "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY&userDataId=$CLOSEDBROWSER_DEFAULT_PROFILE&liveView=true" open https://example.com

# Disable
agent-browser --cdp "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" close
agent-browser --cdp "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY&userDataId=$CLOSEDBROWSER_DEFAULT_PROFILE" open https://example.com
```

### Retrieving Live View URL

**Template:** `{DASHBOARD_URL}/browsers/{INSTANCE_ID}/live-view`

If `CLOSEDBROWSER_DASHBOARD_URL` is not set and user requests live view:
1. **Ask the user:** "What is the URL of the dashboard?"
2. Use their answer to construct the URL

**Example:**
- Dashboard: `https://browser.arranhs.com`
- Instance: `40d1c33d-3038-4b4f-8195-888f753229ba`
- Live view: `https://browser.arranhs.com/browsers/40d1c33d-3038-4b4f-8195-888f753229ba/live-view`

The `/browsers/{id}/live-view` path is appended automatically.

**Pool management:** `GET /browser-pool` (list active instances). Use `id` from response.

## Troubleshooting

| Error | Action |
|-------|--------|
| "WebSocket connection closed" immediately | Missing `apiKey` query param. Add `?apiKey=$CLOSEDBROWSER_API_KEY` to the CDP URL. |
| Connection refused | Check URL, protocol (`ws://` vs `wss://`), container running. Try other protocol. |
| 400 Bad Request | Check URL format and query params |
| 401 Unauthorized | Missing or invalid apiKey |
| "Session already running with different config" | Use different `userDataId` or close existing session |
| Session in "failed" state | Close the stale session first: `browser-use --cdp-url <url> close` or `agent-browser --cdp <url> close`, then reconnect |
| CDP connection dropped | Remote browser closed due to inactivity. Check container logs. |
| Live view not working | Ensure `liveView=true` in URL params |

See agent-browser.md or browser-use.md for tool-specific reference.
