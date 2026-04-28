# closedbrowser: agent-browser Reference

## Rules

- **Always use `--cdp <url>`** — every command must include the full WebSocket CDP URL (e.g., `ws://localhost:3000` or `wss://browser.example.com`)
- **`--cdp` is a global flag** — it must come before the subcommand

## Connect

Pass `--cdp` with full WebSocket URL on every command:

```bash
# Local browser
agent-browser --cdp ws://localhost:3000 open https://example.com

# Remote browser service
agent-browser --cdp "wss://browser-service.com/cdp?token=..." open https://example.com
```

To disconnect and reconnect with a different URL:

```bash
agent-browser --cdp <old-url> close
agent-browser --cdp <new-url> open <target-url>
```

## Anti-Bot Reconnect

If blocked:

```bash
agent-browser --cdp <url> close
agent-browser --cdp "ws://localhost:3000/?headless=false&stealth=true" open <target-url>
```

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
agent-browser --cdp <url> close
```

**Always wait for `networkidle` after navigation.** If the network never settles (streaming sites, long-polling), skip the wait and proceed to snapshot.

## Command Reference

All commands use `--cdp <url>` as a prefix (shortened to `<url>` below for readability).

```bash
# Navigation
agent-browser --cdp <url> open <url>
agent-browser --cdp <url> close

# Wait
agent-browser --cdp <url> wait --load networkidle

# Snapshot (get interactive element refs)
agent-browser --cdp <url> snapshot -i

# Interaction (use @refs from snapshot)
agent-browser --cdp <url> click @e1
agent-browser --cdp <url> fill @e2 "text"
agent-browser --cdp <url> select @e3 "option"

# Screenshots
agent-browser --cdp <url> screenshot
agent-browser --cdp <url> screenshot --full

# Info
agent-browser --cdp <url> get text @e1
agent-browser --cdp <url> get url
```

## Troubleshooting

See SKILL.md for shared troubleshooting (connection refused, 400 errors, CAPTCHA, missing env var).

| Error | Action |
|-------|--------|
| Stale @refs | Re-run `snapshot -i` after page changes. |
