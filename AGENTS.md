# AGENTS.md

Agent instructions for working on closedbrowser.

## Branching Strategy

Each new feature or change should be developed in its own independent branch. This keeps changes isolated and allows for separate PRs and reviews.

```bash
# Create a new feature branch from main
git checkout main
git pull
git checkout -b feature-name

# Work on your changes, commit, and push
git push -u origin feature-name

# Create a PR from the feature branch to main
```

Never combine unrelated changes in the same branch. If you have multiple features to implement, create separate branches for each.

## Build Commands

```bash
task build          # Build Docker image: arranhs/closedbrowser:latest
task run            # Run container via docker compose up
```

## Lint Commands

```bash
task format         # Format shell scripts with shfmt (2-space indent)
task lint           # Lint shell scripts with shellcheck
```

## Test Commands

```bash
task test               # Run all bot detection tests
task test:rebrowser      # Run Rebrowser bot detection test
task test:sannysoft      # Run Sannysoft bot detection test
task test:creepjs        # Run CreepJS bot detection test
```

Tests use `?headless=false` query parameter to run in headful mode for better bot detection scores.

## Test Requirements

- `htmlq` (HTML parser): `go install github.com/ericchiang/pup@latest`
- Container must be running on `localhost:3000`

## Project Architecture

```
closedbrowser/
├── Dockerfile            # Browserless v2.46.0 base with extensions
├── compose.yaml          # Docker compose configuration
├── Taskfile.yaml         # Task runner definitions
├── scripts/              # Build-time scripts (Dockerfile COPY)
│   ├── 01-install-extensions.sh
│   ├── 02-setup-alias.sh
│   └── chromium-alias.sh
├── tests/                # Bot detection test scripts
│   ├── test-rebrowser.sh
│   ├── test-sannysoft.sh
│   └── test-creepjs.sh
└── data/                 # Persistent data (gitignored)
    ├── user-data/        # Browser profile persistence
    └── downloads/        # Download directory
```

## Code Style

### Shell Scripts

- Shebang: `#!/usr/bin/env bash` for portability
- Always use `set -euo pipefail` for strict mode
- Use tabs for indentation (2-space width)
- Variable assignment: `VAR=$(command)`
- Use `[[ ]]` for conditionals, not `[ ]`
- Quote all variable expansions: `"$VAR"`, `"${VAR}"`
- Use `{}` for variable names when followed by other characters: `"${VAR}_suffix"`
- Function names: lowercase with underscores: `install_extension()`
- Local variables: `local VAR=`
- Use `printf` instead of `echo` for complexoutput

### Test Scripts

- Assign curl output to `HTML`variable first: `HTML=$(curl -s "...")`
- Use `htmlq` for HTML parsing
- Output format: simple human-readable without emojis or formatting
- Use `?headless=false` query parameter for headful mode
- JSON body for `/content` endpoint uses `url` and `waitForTimeout` fields

### Dockerfile

- Base image: `ghcr.io/browserless/chromium:v2.46.0`
- User: `blessuser` (switch back after USER root)
- Environment variables use `ENV VAR=value`
- Combine RUN commands with `&& ` for fewer layers
- Clean up apt cache: `rm -rf /var/lib/apt/lists/*`

### Taskfile

- Schema: `# yaml-language-server: $schema=https://taskfile.dev/schema.json`
- Version 3 format
- Use `task:` dependency for running other tasks
- Use `cmds:` array for shell commands

## Browserless Key Learnings

### Headful Mode

- Use `?headless=false` query parameter, not environment variable
- The `/content` REST API endpoint only accepts `headless` via query parameter
- JSON body does not support `headless` field

### Playwright vs Puppeteer

- Default routes (`/`, `/chromium`, `/chrome`) use Puppeteer/CDP
- Explicit `/playwright` paths use Playwright only
- Playwright routes enforce User-Agent check (reject non-Playwright clients)
- For REST API `/content`, use Puppeteer/CDP path

### Bot Detection Scores

Headful mode improves detection scores significantly:

| Metric | Headless | Headful |
|--------|----------|---------|
| Like Headless Score | 56% | 44% |
| Headless Score | 67% | 33% |
| hasHeadlessUA | true | false|
| hasSwiftShader | true | false |
| webDriverIsOn | true | true|

Headful mode fixes most detections except `webDriverIsOn` (requires stealth patches).

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TOKEN` | — | Require authentication on all endpoints |
| `CONCURRENT` | `10` | Max concurrent browser sessions |
| `QUEUED` | `10` | Max queued requests before `429` reject |
| `TIMEOUT` | `30000` | Session timeout ms (`-1` for no timeout) |
| `TZ` | `UTC` | Timezone (e.g. `Europe/London`) |

## Extensions

Pre-installed extensions:
- uBlock Origin Lite (ad blocking)
- I Still Don't Care About Cookies (cookie consent)

To add custom extensions:
1. Mount `user-data`: `./data/user-data:/user-data`
2. Place unpacked extension in `data/user-data/extensions/`
3. Restart container (extension must contain `manifest.json`)

## Port

- `3000`: Browserless API (HTTP, WebSocket, docs at `/docs`)

## Common Tasks

### Add a new extension

1. Add to `scripts/01-install-extensions.sh`:
   ```bash
   install_extension "owner/repo" "extension-name"
   ```
2. Rebuild: `task build`

### Add a new test script

1. Create `tests/test-{name}.sh` following existing pattern
2. Add task to `Taskfile.yaml`:
   ```yaml
   test:{name}:
     cmds:
       - ./tests/test-{name}.sh
   ```
3. Add to `test` task dependencies if running by default

### Debug bot detection

1. Run container: `task run`
2. Run specific test: `task test:rebrowser`
3. Check scores for issues
4. Compare headless vs headful by changing query parameter