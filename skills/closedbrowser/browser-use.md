# browser-use Reference

Pure browser-use CLI usage (browser-harness). Read SKILL.md first for service setup and the CDP URL to substitute below.

## Rules

- Connect via the `BU_CDP_WS` env var and control the browser by piping **raw Python on stdin**.
- The daemon persists the session across `browser-use` invocations, so you only set the env var once per shell.

## Connect

**Build the env var from the CDP URL** (built per SKILL.md — never hardcode or echo credentials):

```bash
export BU_CDP_WS="<cdp-url>"
```

Then pipe raw Python on stdin:

```bash
browser-use <<'PY'
new_tab("https://example.com")
wait_for_load()
print(page_info())
PY
```

**If a previous session exists in a failed state**, kill the stale daemon before opening a new one (CLI 3.0 removed `browser-use close`; a local `close` never stopped the remote browser anyway):

```bash
kill $(cat ~/.config/browser-harness/runtime/bu-default.pid) 2>/dev/null
rm -f ~/.config/browser-harness/runtime/bu-default.pid ~/.config/browser-harness/runtime/bu-default.sock
# then reconnect
export BU_CDP_WS="<cdp-url>"
browser-use <<'PY'
new_tab("https://example.com")
PY
```

`BU_CDP_WS` accepts a full WebSocket URL:
- `BU_CDP_WS=ws://localhost:9999`
- `BU_CDP_WS=wss://browser.example.com`

**Pitfall:** `BU_CDP_URL` (the http/https variant) only speaks `http/https`. A WebSocket endpoint (`ws://`/`wss://`) MUST use `BU_CDP_WS`, not `BU_CDP_URL`.

## Workflow

```python
# First navigation is new_tab(), not goto_url()
new_tab("https://example.com")
wait_for_load()
print(page_info())

# Interact via the accessibility tree
nodes = cdp("Accessibility.getFullAXTree")["nodes"]
# find the node by role/name, get its backendDOMNodeId
q = cdp("DOM.getBoxModel", backendNodeId=n)["model"]["content"]
x, y = sum(q[0::2])/4, sum(q[1::2])/4
click_at_xy(x, y)
wait_for_load()
```

**Always re-query the AX tree before interacting** — node ids are not stable across page changes.

**Closing and verification:** see "Close the browser" in SKILL.md — close only when all work is done, then verify via the pool API. To stop the local daemon: kill the pidfile process and delete the `.pid` + `.sock` under `~/.config/browser-harness/runtime/`, or use `browser-use --reload`.

## Helper Reference (pre-imported, no import needed)

```python
# Navigation
new_tab(url)          # first navigation (NOT goto_url)
goto_url(url)         # navigate current tab
back()
scroll(x, y)

# Tabs
list_tabs()
switch_tab(target)
close_tab(target)

# State
page_info()           # dict: url, title, dimensions

# Interaction
click_at_xy(x, y)     # viewport px
type_text(text)
fill_input(selector, text)
press_key(key)        # e.g. "Enter", "Control+a"

# Wait
wait_for_load()
wait_for_element(selector)

# Screenshots
capture_screenshot(path)

# Data Extraction
js(code)              # run JS, return result
cdp("Domain.method", ...)  # raw CDP

# Tab state
ensure_real_tab()     # if current tab is stale/internal
```

## Element Interaction (AX tree approach)

Use the accessibility-tree approach to locate and click elements:

```python
nodes = cdp("Accessibility.getFullAXTree")["nodes"]
# filter by role/name, get backendDOMNodeId
q = cdp("DOM.getBoxModel", backendNodeId=n)["model"]["content"]
x, y = sum(q[0::2])/4, sum(q[1::2])/4   # viewport px for click_at_xy
click_at_xy(x, y)
```

## CLI 3.0 notes (browser-harness 0.1.x)

CLI 3.0 removed the preset subcommands (`open`, `close`, `snapshot`) — everything is raw Python on stdin, and daemon management is automatic. Useful commands:

```bash
browser-use skill show    # print the full upstream reference for THIS CLI version
browser-use --doctor      # connection diagnostics (chrome running, daemon alive, cloud auth)
browser-use --reload      # restart the local daemon
```

- **`switch_tab()` takes the targetId string from `list_tabs()`** — passing a URL raises `No target with given id found` (hit 2026-09-08). Pattern: `tabs = list_tabs()` → filter by URL → `switch_tab(t["targetId"])`.
- Cloud/remote daemons: `start_remote_daemon("name")` / `stop_remote_daemon(name)` inside the Python block; the old `BU_NAME=...` env syntax is gone.
- Page titles get a horse marker (`🐴`) appended by default; set `BH_TAB_MARKER=0` before daemon start for clean titles.

## Live view note

The local daemon caches the CDP URL at startup. Toggling `liveView` requires a full daemon restart (kill pidfile, delete `.pid` + `.sock`, re-export `BU_CDP_WS` with the new URL, run any command to spawn a fresh daemon). See SKILL.md for live-view semantics and URL retrieval.

## Troubleshooting

See SKILL.md for shared troubleshooting (connection refused, 400 errors, 401 Unauthorized, session timeouts).

| Error | Action |
|-------|--------|
| Element not found | Re-query the AX tree after page changes. |
| Session in "failed" state | Kill the stale daemon (pidfile under `~/.config/browser-harness/runtime/`), then reconnect |
| "Session already running with different config" | Use a different profile or close the existing session (see SKILL.md) |