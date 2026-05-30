# closedbrowser: agent-browser Reference

## Rules

- **Never run `agent-browser install`** — only connects to external browsers
- **Never use `--stealth` or `--headed` CLI flags** — use query params on the CDP URL instead (see Anti-Bot Protection in SKILL.md)
- **Always pass `--cdp <url>`** — include the CDP URL on every command; do not use `agent-browser connect` for persistent connections as CDP sessions can drop unexpectedly
- **`--cdp` is a global flag** — it must come before the subcommand

## Connect

Pass `--cdp` with the full WebSocket URL on every command:

```bash
agent-browser --cdp ws://localhost:9999 open https://example.com
agent-browser --cdp ws://localhost:9999 snapshot -i
agent-browser --cdp ws://localhost:9999 click @e1
```

`--cdp` accepts a port number or full URL:
- Port: `--cdp 9222` (connects to `localhost:9222`)
- URL: `--cdp ws://localhost:9999` or `--cdp wss://browser.example.com`

## Workflow

```bash
agent-browser --cdp <url> open https://example.com
agent-browser --cdp <url> wait --load networkidle
agent-browser --cdp <url> snapshot -i
# use @refs from snapshot to interact
agent-browser --cdp <url> fill @e1 "user@example.com"
agent-browser --cdp <url> click @e2
# re-snapshot after any navigation or DOM change
agent-browser --cdp <url> snapshot -i
```

**Always wait for `networkidle` after navigation.** If the network never settles (streaming sites, long-polling), skip the wait and proceed to snapshot.

## Command Reference

All commands require `--cdp <url>` before the subcommand (shortened below for readability).

```bash
# Navigation
agent-browser --cdp <url> open <target-url>   # Navigate (aliases: goto, navigate)
agent-browser --cdp <url> back                # Go back
agent-browser --cdp <url> forward             # Go forward
agent-browser --cdp <url> reload              # Reload page
agent-browser --cdp <url> close               # Close browser
agent-browser --cdp <url> close --all         # Close all sessions

# Snapshot (get interactive element @refs)
agent-browser --cdp <url> snapshot -i

# Wait
agent-browser --cdp <url> wait --load networkidle         # Wait for network idle
agent-browser --cdp <url> wait <selector>                 # Wait for element
agent-browser --cdp <url> wait <ms>                       # Wait for time
agent-browser --cdp <url> wait --text "Welcome"           # Wait for text
agent-browser --cdp <url> wait --url "**/dashboard"       # Wait for URL pattern
agent-browser --cdp <url> wait --fn "js condition"        # Wait for JS condition
agent-browser --cdp <url> wait "#spinner" --state hidden  # Wait for element to disappear

# Interaction (use @refs from snapshot)
agent-browser --cdp <url> click @e1                # Click element
agent-browser --cdp <url> dblclick @e1             # Double-click
agent-browser --cdp <url> fill @e1 "text"          # Clear and fill
agent-browser --cdp <url> type @e1 "text"          # Type into element (appends)
agent-browser --cdp <url> press Enter              # Press key (Enter, Tab, Control+a)
agent-browser --cdp <url> keyboard type "text"     # Type at current focus (no ref needed)
agent-browser --cdp <url> select @e1 "option"      # Select dropdown
agent-browser --cdp <url> hover @e1                # Hover
agent-browser --cdp <url> scroll down [px]         # Scroll (up/down/left/right)
agent-browser --cdp <url> scroll up
agent-browser --cdp <url> upload @e1 <files>       # Upload files
agent-browser --cdp <url> drag @e1 @e2             # Drag and drop

# Screenshots
agent-browser --cdp <url> screenshot               # Screenshot
agent-browser --cdp <url> screenshot --full        # Full page
agent-browser --cdp <url> screenshot --annotate    # Annotated with numbered element labels

# Get info
agent-browser --cdp <url> get text @e1             # Text content
agent-browser --cdp <url> get html @e1             # innerHTML
agent-browser --cdp <url> get value @e1            # Input value
agent-browser --cdp <url> get attr @e1 <attr>      # Attribute
agent-browser --cdp <url> get title                # Page title
agent-browser --cdp <url> get url                  # Current URL
agent-browser --cdp <url> get count <selector>     # Count matching elements
agent-browser --cdp <url> get box @e1              # Bounding box

# JavaScript
agent-browser --cdp <url> eval "js code"           # Run JavaScript

# Tabs
agent-browser --cdp <url> tab                      # List tabs
agent-browser --cdp <url> tab new [url]            # New tab
agent-browser --cdp <url> tab <tN>                 # Switch to tab (t1, t2, etc.)
agent-browser --cdp <url> tab close [tN]           # Close tab

# Cookies
agent-browser --cdp <url> cookies                  # Get all cookies
agent-browser --cdp <url> cookies set <name> <val> # Set cookie
agent-browser --cdp <url> cookies clear            # Clear cookies
```

## Troubleshooting

See SKILL.md for shared troubleshooting (connection refused, 400 errors, 401 Unauthorized, session timeouts).

| Error | Action |
|-------|--------|
| Stale @refs | Re-run `snapshot -i` after page changes. |
| 401 Unauthorized | Verify `$CLOSEDBROWSER_API_KEY` is correct |
