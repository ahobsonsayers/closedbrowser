# closedbrowser: browser-use Reference

## Rules

- **Never omit `--cdp-url`** — every command must include the CDP URL; browser-use does not persist connections between commands
- **`--cdp-url` is a global flag** — it must come before the subcommand
- **Always include `apiKey` in the URL** — if `CLOSEDBROWSER_API_KEY` is set, the CDP URL must include `?apiKey=$CLOSEDBROWSER_API_KEY`. Forgetting this causes "WebSocket connection closed" immediately.

## Connect

**Always read SKILL.md first for environment setup.** The main skill handles `CLOSEDBROWSER_API_URL`, `CLOSEDBROWSER_API_KEY`, and `CLOSEDBROWSER_DEFAULT_PROFILE` setup.

browser-use does NOT persist connections — pass `--cdp-url` on every command:

```bash
browser-use --cdp-url "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" open https://example.com
browser-use --cdp-url "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" state    # must repeat URL
browser-use --cdp-url "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" click 5   # must repeat URL
```

**If a previous session exists in a failed state**, close it before opening a new one:

```bash
browser-use --cdp-url "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" close
browser-use --cdp-url "ws://localhost:9999?apiKey=$CLOSEDBROWSER_API_KEY" open https://example.com
```

`--cdp-url` accepts a port number or full URL:
- Port: `--cdp-url 9222` (connects to `localhost:9222`)
- URL: `--cdp-url ws://localhost:9999` or `--cdp-url "wss://browser.example.com?apiKey=$CLOSEDBROWSER_API_KEY"`

To close:

```bash
browser-use --cdp-url <url> close
```

## Workflow

```bash
browser-use --cdp-url <url> open https://example.com
browser-use --cdp-url <url> wait selector "body"
browser-use --cdp-url <url> state
# use indices from state to interact
browser-use --cdp-url <url> input 12 "user@example.com"
browser-use --cdp-url <url> click 15
# re-run state after any navigation or DOM change
browser-use --cdp-url <url> state
browser-use --cdp-url <url> close
```

**Always run `state` before interacting with elements.** Returns page URL, title, and clickable elements with numeric indices.

**Close the browser when done.** Closing frees resources and is best practice. But closing destroys all browser state — only close when absolutely certain all work is finished. If there is any doubt, ask the user before closing.

## Command Reference

All commands use `--cdp-url <url>` as a prefix (shortened to `<url>` below for readability).

```bash
# Navigation
browser-use --cdp-url <url> open <target-url>
browser-use --cdp-url <url> back
browser-use --cdp-url <url> scroll down              # --amount N for pixels
browser-use --cdp-url <url> scroll up
browser-use --cdp-url <url> close

# Tabs
browser-use --cdp-url <url> tab list
browser-use --cdp-url <url> tab new [target-url]
browser-use --cdp-url <url> tab switch <index>
browser-use --cdp-url <url> tab close <index>

# State (get interactive element indices — always run before interacting)
browser-use --cdp-url <url> state

# Interaction (use indices from state)
browser-use --cdp-url <url> click <index>
browser-use --cdp-url <url> click <x> <y>            # pixel coordinates
browser-use --cdp-url <url> input <index> "text"      # click, clear, type
browser-use --cdp-url <url> input <index> ""           # clear field
browser-use --cdp-url <url> type "text"                # type into focused element
browser-use --cdp-url <url> select <index> "option"
browser-use --cdp-url <url> keys "Enter"               # also "Control+a", etc.
browser-use --cdp-url <url> hover <index>
browser-use --cdp-url <url> dblclick <index>
browser-use --cdp-url <url> rightclick <index>
browser-use --cdp-url <url> upload <index> <path>

# Wait
browser-use --cdp-url <url> wait selector "css"        # --state visible|hidden, --timeout ms
browser-use --cdp-url <url> wait text "text"

# Screenshots
browser-use --cdp-url <url> screenshot [path.png]      # base64 if no path
browser-use --cdp-url <url> screenshot --full

# Data Extraction
browser-use --cdp-url <url> eval "js code"
browser-use --cdp-url <url> get title
browser-use --cdp-url <url> get html [--selector "h1"]
browser-use --cdp-url <url> get text <index>
browser-use --cdp-url <url> get value <index>
browser-use --cdp-url <url> get attributes <index>
browser-use --cdp-url <url> get bbox <index>

# Cookies
browser-use --cdp-url <url> cookies get [--url <filter>]
browser-use --cdp-url <url> cookies set <name> <value>  # --domain, --secure, etc.
browser-use --cdp-url <url> cookies clear [--url <filter>]
browser-use --cdp-url <url> cookies export <file>
browser-use --cdp-url <url> cookies import <file>

# Session
browser-use --cdp-url <url> close
browser-use close --all                            # hard reset all sessions
```

## Troubleshooting

See SKILL.md for shared troubleshooting (connection refused, 400 errors, 401 Unauthorized, session timeouts).

| Error | Action |
|-------|--------|
| "WebSocket connection closed" immediately | Missing `apiKey` query param. Add `?apiKey=$CLOSEDBROWSER_API_KEY` to the CDP URL. |
| Invalid element index / Element not found | Re-run `state` after page changes. |
| Session in "failed" state | Close the stale session first: `browser-use --cdp-url <url> close`, then reconnect |
| 401 Unauthorized | Verify `$CLOSEDBROWSER_API_KEY` is correct |