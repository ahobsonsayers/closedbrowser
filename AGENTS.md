# AGENTS.md

Agent instructions for working on closedbrowser.

## Skills

Use the `closedbrowser` skill for browser automation tasks with the containerized Chromium CDP endpoint.

## Build Commands

```bash
task build              # Build Docker image: arranhs/closedbrowser:latest
task build:no-cache     # Build without cache (full rebuild)
task run                # Run container in foreground
task run:daemon         # Run container in background
```

**Rebuild after any changes to `scripts/` or `patches/`** — they are applied at build time, not runtime.

## Test Commands

```bash
task test               # Run all bot detection tests
task test:rebrowser     # Run Rebrowser bot detection test
task test:sannysoft     # Run Sannysoft bot detection test
task test:creepjs       # Run CreepJS bot detection test
```

**Prerequisites**: `htmlq` (HTML parser: `go install github.com/ericchiang/pup@latest`), `browser-use` CLI, container running on `localhost:3000`.

**compose.yaml**: `shm_size: 1g` is required — without it Chrome crashes.

## Test Scripts

Use `browser-use close` before opening, `sleep 10` after open, `trap cleanup EXIT` for cleanup.

## Lint Commands

```bash
task format             # Format shell scripts with shfmt (2-space indent)
task lint               # Lint shell scripts with shellcheck
```

## Branching

Each feature or change gets its own branch. Never combine unrelated changes.

## Build Process

1. `01-patch-browserless.sh` applies patches to browserless source via `git apply`
2. `02-install-extensions.sh` downloads and installs extensions (uBlock Origin Lite, IDCAC)
3. Patched browserless loads extensions from `GLOBAL_EXTENSIONS_DIR` (`$APP_DIR/extensions`) and `USER_EXTENSIONS_DIR` (`/data/extensions`)

## Browserless Key Learnings (hard-won)

- **Headful mode**: `?headless=false&stealth=true` query param (not in JSON body)
- **REST API `/content`**: Only accepts `headless` via query param, not JSON body
- **Playwright routes** (`/chromium/playwright`) enforce User-Agent check; use Puppeteer/CDP routes for unrestricted access
- **Extension loading**: `manifest.json` required in extension directory; mount to `/data/extensions/{name}/`

## Code Style

**Shell scripts**: shebang `#!/usr/bin/env bash`, `set -euo pipefail`, tabs for indentation, quote all variable expansions, use `printf` not `echo`.

**Patches**: Target file path in patch is relative to `$APP_DIR` (browserless install dir). Rebuild after modifying.

**Dockerfile**: Base image `ghcr.io/browserless/chromium:v2.47.0`, switch back from root to `blessuser` after setup, combine RUN commands with `&&`, clean apt cache.

## Environment Variables (non-obvious)

| Variable | Default | Description |
| --- | --- | --- |
| `HOST` | `localhost` | Listen address |
| `PORT` | `3000` | Listen port |
| `DEBUG` | `browserless*,-**:verbose` | Debug logging filter |

## Common Tasks

**Add built-in extension**: Update `scripts/02-install-extensions.sh` with `install_extension "owner/repo" "extension-name"`, then `task build`.

**Add custom extension at runtime**: Mount to `/data/extensions/{name}/` in `compose.yaml` (requires `manifest.json`).

**Add test script**: Create `tests/test-{name}.sh`, add task to `Taskfile.yaml` under `test:{name}:`, add to `test` task deps.

**Debug bot detection**: `task run:daemon`, then `task test:rebrowser`. Compare results with `headless=false` vs `headless=true` query param.

**Update patches**: Modify patches in `patches/`, then `task build:no-cache` and verify extension loading.