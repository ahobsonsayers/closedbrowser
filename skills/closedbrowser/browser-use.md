# closedbrowser: browser-use Reference

## Rules

- Connect via the `BU_CDP_WS` env var and control the browser by piping **raw Python on stdin**.
- **Always include `apiKey` in the URL** — if `CLOSEDBROWSER_API_KEY` is set, the CDP URL must include `?apiKey=$CLOSEDBROWSER_API_KEY`. Forgetting this causes "WebSocket connection closed" immediately.
- **Build the env var from existing vars** — never hardcode or echo the API key. Use `$VAR` substitution.

## Connect

**Always read SKILL.md first for environment setup.** The main skill handles `CLOSEDBROWSER_API_URL`, `CLOSEDBROWSER_API_KEY`, and `CLOSEDBROWSER_DEFAULT_PROFILE` setup.

Build the CDP env var from existing vars (never hardcode/echo the key):

```bash
export BU_CDP_WS="${CLOSEDBROWSER_API_URL}?apiKey=${CLOSEDBROWSER_API_KEY}&userDataId=${CLOSEDBROWSER_DEFAULT_PROFILE}"
```

Then pipe raw Python on stdin. The daemon persists the session across `browser-use` invocations, so you only set the env var once per shell:

```bash
browser-use <<'PY'
new_tab("https://example.com")
wait_for_load()
print(page_info())
PY
```

**If a previous session exists in a failed state**, close it before opening a new one:

```bash
browser-use close --all
# then reconnect
export BU_CDP_WS="${CLOSEDBROWSER_API_URL}?apiKey=${CLOSEDBROWSER_API_KEY}&userDataId=${CLOSEDBROWSER_DEFAULT_PROFILE}"
browser-use <<'PY'
new_tab("https://example.com")
PY
```

`BU_CDP_WS` accepts a full WebSocket URL:
- `BU_CDP_WS=ws://localhost:9999`
- `BU_CDP_WS="wss://browser.example.com?apiKey=$CLOSEDBROWSER_API_KEY"`

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

**Close the browser when done.** Closing frees resources and is best practice. But closing destroys all browser state — only close when absolutely certain all work is finished. If there is any doubt, ask the user before closing.

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
scroll(x, y)

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

## Troubleshooting

See SKILL.md for shared troubleshooting (connection refused, 400 errors, 401 Unauthorized, session timeouts).

| Error | Action |
|-------|--------|
| "WebSocket connection closed" immediately | Missing `apiKey` query param. Add `?apiKey=$CLOSEDBROWSER_API_KEY` to the CDP URL. |
| Element not found | Re-query the AX tree after page changes. |
| Session in "failed" state | Close the stale session first: `browser-use close --all`, then reconnect |
| 401 Unauthorized | Verify `$CLOSEDBROWSER_API_KEY` is correct |
| "Session already running with different config" | Use a different `userDataId` or close the existing session |
