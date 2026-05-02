# closedbrowser

A containerised Chromium browser built on [browserless](https://github.com/browserless/browserless), with uBlock Origin and I Still Don't Care About Cookies pre-installed.

## Usage

For instructions on running the container, see [Running](#running).

This image is primarily designed for use with an AI agent. As such, there is an LLM skill at `skills/closedbrowser` which will guide your agent to use this image. This skill will allow you to use either [browser-use](https://github.com/browser-use/browser-use) (recommended) or [agent-browser](https://github.com/all_in_oss/agent-browser) to interact with the browser running in the container.

You will need to have one of these tools installed:
- [browser-use](https://docs.browser-use.com/open-source/browser-use-cli) — recommended
- [agent-browser](https://agent-browser.dev)

If you have both installed, you will be asked which one to use.

See the skill at `skills/closedbrowser` for more details on setup.

### Skill config (environment variables)

| Variable              | Required | Description                                                            |
| --------------------- | -------- | ---------------------------------------------------------------------- |
| `CLOSEDBROWSER_URL`   | Yes      | CDP endpoint URL (e.g., `localhost:3000` or `browser.example.com`)     |
| `CLOSEDBROWSER_TOKEN` | No       | Token for authenticated containers (only if container has `TOKEN` set) |

### CDP URL

The skill constructs a CDP URL to connect to the browser. The base format is:

```
ws://localhost:3000/
wss://browser.example.com/
```

If `CLOSEDBROWSER_TOKEN` is set, it's appended as a query param:

```
ws://localhost:3000/?token=YOUR_TOKEN
```

For sites with bot detection (Cloudflare, DataDome, etc.), the skill can add `headless=false&stealth=true` to enable headful mode with stealth flags:

```
ws://localhost:3000/?headless=false&stealth=true
```

## Running

```bash
docker compose up -d
```

## Ports

| Port   | Description     |
| ------ | --------------- |
| `3000` | Browserless API |

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

ClosedBrowser has environment variables that are both unique/specific to this image and inherited from the base Browserless image.

### ClosedBrowser environment variables

| Variable                    | Default | Description                                                |
| --------------------------- | ------- | ---------------------------------------------------------- |
| `EXTENSION_UBLOCK_ENABLED`  | `true`  | Enable uBlock Origin Lite by default (`true`/`false`)      |
| `EXTENSION_NOPECHA_API_KEY` | —       | NopeCHA extension API key (optional, 100 free credits/24h) |

### Browserless environment variables

The standard Browserless configuration environment variables can be seen below, as found in [config.ts](https://github.com/browserless/browserless/blob/main/src/config.ts).

### Server

| Variable | Default                    | Description          |
| -------- | -------------------------- | -------------------- |
| `HOST`   | `localhost`                | Listen address       |
| `PORT`   | `3000`                     | Listen port          |
| `DEBUG`  | `browserless*,-**:verbose` | Debug logging filter |

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

Useful endpoints to be aware of. See `/docs/` for full API details.

**Note:** When using WebSocket routes with query parameters, always add a trailing slash before the `?` (e.g., `ws://host:3000/?headless=false`).

| Route                  | Description                                |
| ---------------------- | ------------------------------------------ |
| `/`                    | Chromium browser WebSocket (Puppeteer/CDP) |
| `/chromium`            | Alias for `/`                              |
| `/chromium/playwright` | Playwright Chromium WebSocket              |
| `/docs`                | API documentation (interactive)            |
| `/debugger`            | Built-in Chrome DevTools debugger          |
| `/metrics`             | Browserless metrics                        |
| `/chromium/screenshot` | Screenshot REST API                        |
| `/chromium/content`    | Content extraction REST API                |
| `/chromium/pdf`        | PDF generation REST API                    |

## Query Parameters

Reference: [Browserless Launch Options](https://docs.browserless.io/baas/launch-options)

Append query params to the WebSocket URL after a trailing slash:

```
ws://localhost:3000/?headless=false&stealth=true&timeout=120000
```

### Supported Parameters

| Parameter             | Description                                                    | Example                     |
| --------------------- | -------------------------------------------------------------- | --------------------------- |
| `token`               | Authorization token                                            | `?token=YOUR_TOKEN`         |
| `timeout`             | Session timeout in ms (default 60000)                          | `?timeout=120000`           |
| `blockAds`            | Enable ad blocker (uBlock Origin)                              | `?blockAds=true`            |
| `headless`            | Run headless (`true`/`false`) — use `false` for bot protection | `?headless=false`           |
| `stealth`             | Enable stealth mode                                            | `?stealth=true`             |
| `slowMo`              | Delay between actions (ms)                                     | `?slowMo=100`               |
| `ignoreDefaultArgs`   | Ignore default browser args                                    | `?ignoreDefaultArgs=true`   |
| `acceptInsecureCerts` | Accept invalid SSL certs                                       | `?acceptInsecureCerts=true` |
| `launch`              | JSON launch options (URL/base64 encoded)                       | `?launch=...`               |

### Chrome Flags (via `--` prefix)

| Parameter        | Description              | Example                          |
| ---------------- | ------------------------ | -------------------------------- |
| `--proxy-server` | Proxy server (host:port) | `?--proxy-server=proxy.com:8080` |
| `--window-size`  | Browser window size      | `?--window-size=1920,1080`       |
| `--lang`         | Browser language         | `?--lang=en-US`                  |

### Not Yet Supported

These are in the Browserless docs but not implemented:
- `proxy`, `proxyCountry`, `proxyCity`, `proxySticky` — residential proxy features
- `record`, `replay` — session recording
- `profile` — authenticated profiles
- `humanlike` — human behavior simulation |
