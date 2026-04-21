# AGENTS.md

Agent instructions for working on closedbrowser.

## Branching Strategy

Each feature or change gets its own branch. Never combine unrelated changes.

```bash
git checkout main
git pull
git checkout -b feature-name
# ... work ...
git push -u origin feature-name
# Create PR to main
```

## Build Commands

```bash
task build              # Build Docker image: arranhs/closedbrowser:latest
task build:no-cache     # Build without cache (full rebuild)
task run                # Run container in foreground
task run:daemon         # Run container in background
```

**Note**: Rebuild after any changes to `scripts/` or `patches/` - they are applied at build time, not runtime.

## Lint Commands

```bash
task format             # Format shell scripts with shfmt (2-space indent)
task lint               # Lint shell scripts with shellcheck
```

## Test Commands

```bash
task test               # Run all bot detection tests
task test:rebrowser     # Run Rebrowser bot detection test
task test:sannysoft     # Run Sannysoft bot detection test
task test:creepjs       # Run CreepJS bot detection test
```

## Test Requirements

- `htmlq` (HTML parser): `go install github.com/ericchiang/pup@latest`
- `browser-use` CLI for browser automation
- Container must be running on `localhost:3000`

## Project Architecture

```
closedbrowser/
├── Dockerfile                  # Browserless v2.47.0 base with extensions
├── compose.yaml                # Docker compose configuration
├── Taskfile.yaml               # Task runner definitions
├── patches/                    # Browserless source patches
│   └── browsers.cdp.patch      # Extension loading patch
├── scripts/                    # Build-time scripts
│   ├── 01-patch-browserless.sh   # Apply patches to browserless
│   └── 02-install-extensions.sh  # Install uBlock and IDCAC
├── tests/                      # Bot detection test scripts
│   ├── test-rebrowser.sh
│   ├── test-sannysoft.sh
│   └── test-creepjs.sh
└── data/                       # Persistent data (gitignored)
    ├── user-data/              # Browser profile persistence
    └── downloads/              # Download directory
```

## Build Process

1. **Patch**: `01-patch-browserless.sh` applies patches to browserless source
2. **Install**: `02-install-extensions.sh` downloads and installs extensions
3. **Runtime**: Patched browserless loads extensions from both `GLOBAL_EXTENSIONS_DIR` and `USER_EXTENSIONS_DIR`

## Code Style

### Shell Scripts

- Shebang: `#!/usr/bin/env bash`
- Always use `set -euo pipefail`
- Use tabs for indentation (2-space width via shfmt)
- Quote all variable expansions: `"$VAR"`, `"${VAR}"`
- Use `printf` instead of `echo` for complex output

### Test Scripts

- Use `browser-use` CLI for browser automation: `browser-use --cdp-url "$BROWSER_URL" open "$URL"`
- Use `htmlq` for HTML parsing
- Headful mode via query param: `?headless=false&stealth=true`
- Cleanup with trap: `trap cleanup EXIT`

### Patches

- Place patches in `patches/` directory
- Patches are applied at build time via `git apply`
- Target file path in patch is relative to `$APP_DIR` (browserless install dir)
- Rebuild image after modifying patches

### Dockerfile

- Base image: `ghcr.io/browserless/chromium:v2.47.0`
- User: `blessuser` (switch back after USER root)
- Combine RUN commands with `&&` for fewer layers
- Clean up apt cache: `rm -rf /var/lib/apt/lists/*`

### Taskfile

- Schema: `# yaml-language-server: $schema=https://taskfile.dev/schema.json`
- Version 3 format
- Use `cmds:` array for shell commands

## Browserless Key Learnings

### Headful Mode

- Use `?headless=false` query parameter
- REST API `/content` only accepts `headless` via query param
- JSON body does not support `headless` field

### Playwright vs Puppeteer

- Default routes (`/`, `/chromium`, `/chrome`) use Puppeteer/CDP
- Explicit `/playwright` paths use Playwright only
- Playwright routes enforce User-Agent check
- For REST API `/content`, use Puppeteer/CDP path

### Bot Detection Scores (Headful + Stealth)

Current test results with stealth patches:

| Metric | Score |
|--------|-------|
| Like Headless | 44% |
| Headless Score | 0% |
| webDriverIsOn | false |
| hasHeadlessUA | false |
| hasSwiftShader | false |

## Environment Variables

### Browserless Config

| Variable | Default | Description |
|----------|---------|-------------|
| `TOKEN` | — | Require authentication on all endpoints |
| `CONCURRENT` | `10` | Max concurrent browser sessions |
| `QUEUED` | `10` | Max queued requests before `429` reject |
| `TIMEOUT` | `30000` | Session timeout ms (`-1` for no timeout) |
| `TZ` | `UTC` | Timezone (e.g. `Europe/London`) |

### Extension Directories (Build-time)

| Variable | Default | Description |
|----------|---------|-------------|
| `GLOBAL_EXTENSIONS_DIR` | `$APP_DIR/extensions` | Pre-installed extensions (uBlock, IDCAC) |
| `USER_EXTENSIONS_DIR` | `/user-extensions` | Custom user extensions mount point |

## Extensions

Pre-installed (in image):
- uBlock Origin Lite (ad blocking)
- I Still Don't Care About Cookies (cookie consent)

Custom extensions at runtime:
- Mount unpacked extension to `/user-extensions/{name}/`
- Requires `manifest.json` in extension directory
- Multiple extensions supported

## Port

- `3000`: Browserless API (HTTP, WebSocket, docs at `/docs`)

## Common Tasks

### Add a built-in extension

1. Update `scripts/02-install-extensions.sh`: `install_extension "owner/repo" "extension-name"`
2. Rebuild: `task build`

### Add a custom extension at runtime

1. Mount extension directory in `compose.yaml`:
   ```yaml
   volumes:
     - ./data/extensions/my-extension:/user-extensions/my-extension
   ```
2. Extension loads automatically on browser start (requires `manifest.json`)

### Add a new test script

1. Create `tests/test-{name}.sh` following existing pattern
2. Add task to `Taskfile.yaml`:
   ```yaml
   test:{name}:
     cmds:
       - ./tests/test-{name}.sh
   ```
3. Add to `test` task dependencies

### Debug bot detection

1. Run container: `task run:daemon`
2. Run specific test: `task test:rebrowser`
3. Check scores for issues
4. Compare by changing `headless` query parameter

### Update browserless patches

1. Modify `patches/browsers.cdp.patch`
2. Rebuild: `task build:no-cache`
3. Test extension loading works correctly
