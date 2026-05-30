# closedbrowser

A containerised Chromium browser built on [BlitzBrowser](https://github.com/blitzbrowser/blitzbrowser), with uBlock Origin and I Still Don't Care About Cookies pre-installed.

## Usage

For instructions on running the container, see [Running](#running).

This image is primarily designed for use with an AI agent. As such, there is an LLM skill at `skills/closedbrowser` which will guide your agent to use this image. This skill will allow you to use either [browser-use](https://github.com/browser-use/browser-use) (recommended) or [agent-browser](https://github.com/all_in_oss/agent-browser) to interact with the browser running in the container.

You will need to have one of these tools installed:
- [browser-use](https://docs.browser-use.com/open-source/browser-use-cli) — recommended
- [agent-browser](https://agent-browser.dev)

If you have both installed, you will be asked which one to use.

See the skill at `skills/closedbrowser` for more details on setup.

### Skill config (environment variables)

| Variable                      | Required | Description                                                            |
| ----------------------------- | -------- | ---------------------------------------------------------------------- |
| `CLOSEDBROWSER_URL`           | Yes      | CDP endpoint URL (e.g., `localhost:9999` or `browser.example.com`)     |
| `CLOSEDBROWSER_TOKEN`         | No       | Token for authenticated containers (only if container has `TOKEN` set) |
| `CLOSEDBROWSER_DEFAULT_PROFILE` | No     | Default profile for persistence (e.g., `my-profile`). Only one session can use a given profile at a time. |

### CDP URL

The skill constructs a CDP URL to connect to the browser. The base format is:

```
ws://localhost:9999/
wss://browser.example.com/
```

If `CLOSEDBROWSER_TOKEN` is set, it's appended as a query param:

```
ws://localhost:9999/?token=YOUR_TOKEN
```

For sites with bot detection (Cloudflare, DataDome, etc.), the skill can add `headless=false&stealth=true` to enable headful mode with stealth flags:

```
ws://localhost:9999/?headless=false&stealth=true
```

## Running

```bash
docker compose up -d
```

## Ports

| Port   | Description     |
| ------ | --------------- |
| `9999` | BlitzBrowser API |

## Volumes

Mount a single `data` directory to persist all browser data:

```yaml
volumes:
  - ./data:/data
```

| Directory           | Description                                       |
| ------------------- | ------------------------------------------------- |
| `/data/profiles/`   | Browser profile (cookies, history, local storage) |
| `/data/downloads/`  | Downloaded files                                  |
| `/data/extensions/` | Custom extensions (must contain `manifest.json`)  |

**Note:** Create the `./data` directory on the host before running to prevent permission issues:

```bash
mkdir -p ./data
docker compose up -d
```

### Extensions

[uBlock Origin Lite](https://github.com/uBlockOrigin/uBOL-home), [I Still Don't Care About Cookies](https://github.com/OhMyGuus/I-Still-Dont-Care-About-Cookies), and [NopeCHA](https://github.com/NopeCHALLC/nopecha-extension) are pre-installed.

To add your own, drop an unpacked extension directory (must contain a `manifest.json`) into `data/extensions/` and restart the container. Requires the `data` mount above.

## Environment variables

ClosedBrowser has environment variables that are both unique/specific to this image and inherited from the base BlitzBrowser image.

### ClosedBrowser environment variables

| Variable                    | Default | Description                                                |
| --------------------------- | ------- | ---------------------------------------------------------- |
| `EXTENSION_UBLOCK_ENABLED`  | `true`  | Enable uBlock Origin Lite by default (`true`/`false`)      |
| `EXTENSION_NOPECHA_API_KEY` | —       | NopeCHA extension API key (optional, 100 free credits/24h) |

### BlitzBrowser environment variables

The standard BlitzBrowser configuration environment variables can be seen in the [BlitzBrowser documentation](https://docs.blitzbrowser.com).

### Server

| Variable | Default     | Description     |
| -------- | ----------- | --------------- |
| `HOST`   | `localhost` | Listen address  |
| `PORT`   | `9999`      | Listen port     |

### Security

| Variable              | Default | Description                             |
| --------------------- | ------- | --------------------------------------- |
| `TOKEN`               | —       | Require authentication on all endpoints |
| `ALLOW_FILE_PROTOCOL` | `false` | Allow `file://` URLs in browser         |

### Sessions

| Variable             | Default    | Description                              |
| -------------------- | ---------- | ---------------------------------------- |
| `CONCURRENT`         | `10`       | Max concurrent browser sessions          |
| `QUEUED`             | `10`       | Max queued requests before `429` reject  |
| `TIMEOUT`            | `30000`    | Session timeout ms (`-1` for no timeout) |
| `RETRIES`            | `5`        | Connection retry attempts                |
| `MAX_PAYLOAD_SIZE`   | `10485760` | Max request size in bytes (default 10MB) |
| `MAX_CPU_PERCENT`    | `99`       | CPU usage limit percentage               |
| `MAX_MEMORY_PERCENT` | `99`       | Memory usage limit percentage            |

### Alerts

| Variable            | Default | Description                           |
| ------------------- | ------- | ------------------------------------- |
| `HEALTH`            | `false` | Enable pre-request health checks      |
| `FAILED_HEALTH_URL` | —       | POST webhook when health check fails  |
| `QUEUE_ALERT_URL`   | —       | POST webhook when queue is non-empty  |
| `REJECT_ALERT_URL`  | —       | POST webhook when request is rejected |
| `TIMEOUT_ALERT_URL` | —       | POST webhook on session timeout       |
| `ERROR_ALERT_URL`   | —       | POST webhook on errors                |

### CORS

| Variable                 | Default              | Description                             |
| ------------------------ | -------------------- | --------------------------------------- |
| `ALLOW_CORS`             | `false`              | Enable CORS support                     |
| `CORS_ALLOW_CREDENTIALS` | `true`               | Allow credentials in CORS header        |
| `CORS_ALLOW_HEADERS`     | `*`                  | Headers to allow in CORS requests       |
| `CORS_ALLOW_METHODS`     | `OPTIONS, POST, GET` | Methods to allow in CORS requests       |
| `CORS_ALLOW_ORIGIN`      | `*`                  | Origin pattern to match against         |
| `CORS_EXPOSE_HEADERS`    | `*`                  | Headers to expose in CORS responses     |
| `CORS_MAX_AGE`           | `2592000`            | CORS preflight cache duration (seconds) |

### Browser APIs

| Variable    | Default | Description                                            |
| ----------- | ------- | ------------------------------------------------------ |
| `ALLOW_GET` | `false` | Allow GET-style calls on browser APIs via `?body=JSON` |

### Directories

| Variable            | Default        | Description                        |
| ------------------- | -------------- | ---------------------------------- |
| `METRICS_JSON_PATH` | `tmpdir`       | Path to write metrics JSON file    |
| `ROUTES`            | `build/routes` | Custom API routes directory        |
| `STATIC`            | `static`       | Static file directory for debugger |

### Reverse Proxy

| Variable   | Default | Description                                             |
| ---------- | ------- | ------------------------------------------------------- |
| `EXTERNAL` | —       | External URL for reverse proxy (sets `wss://` protocol) |

### Debugger

| Variable          | Default | Description                       |
| ----------------- | ------- | --------------------------------- |
| `ENABLE_DEBUGGER` | `true`  | Enable built-in debugger endpoint |

### Metrics

| Variable               | Default | Description                                          |
| ---------------------- | ------- | ---------------------------------------------------- |
| `MACHINE_STATS_SOURCE` | `auto`  | CPU/memory stats source: `auto`, `host`, or `cgroup` |

### Localization

| Variable | Default | Description                     |
| -------- | ------- | ------------------------------- |
| `TZ`     | `UTC`   | Timezone (e.g. `Europe/London`) |

## Routes

Useful endpoints to be aware of. See the [BlitzBrowser documentation](https://docs.blitzbrowser.com) for full API details.

| Route                  | Description                                |
| ---------------------- | ------------------------------------------ |
| `/`                    | Chromium browser WebSocket (Puppeteer/CDP) |
| `/browser-instances`   | Browser instance events WebSocket            |


