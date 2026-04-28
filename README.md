# closedbrowser

A containerised Chromium browser built on [browserless](https://github.com/browserless/browserless), with uBlock Origin and I Still Don't Care About Cookies pre-installed.

## Running

```bash
docker compose up -d
```

## Ports

| Port   | Description                                            |
| ------ | ------------------------------------------------------ |
| `3000` | Browserless API — HTTP, WebSocket, docs at `/docs`     |

## Persistence

By default browser data is ephemeral and lost on container restart. To persist the profile (history, cookies, settings) mount the `user-data` directory:

```yaml
volumes:
  - ./data/user-data:/user-data
  - ./data/downloads:/downloads
```

## Extensions

[uBlock Origin Lite](https://github.com/uBlockOrigin/uBOL-home) and [I Still Don't Care About Cookies](https://github.com/OhMyGuus/I-Still-Dont-Care-About-Cookies) are pre-installed.

To add your own, drop an unpacked extension directory (must contain a `manifest.json`) into `data/user-data/extensions/` and restart the container. Requires the `user-data` mount above.

## Environment variables

ClosedBrowser has environment variables that are both unique/specific to this image and inherited from the base browserless image.

### ClosedBrowser environment variables

Recommended not to change.

| Variable | Default | Description |
| --- | --- | --- |
| `GLOBAL_EXTENSIONS_DIR` | `$APP_DIR/extensions` | Pre-installed extensions directory (uBlock, IDCAC) |
| `USER_EXTENSIONS_DIR` | `/user-extensions` | Custom user extensions mount point |

### Browserless environment variables

The standard browserless configuration environment variables can be seen below, as found in [config.ts](https://github.com/browserless/browserless/blob/main/src/config.ts).

### Server

| Variable | Default | Description |
| --- | --- | --- |
| `HOST` | `localhost` | Listen address |
| `PORT` | `3000` | Listen port |
| `DEBUG` | `browserless*,-**:verbose` | Debug logging filter |

### Security

| Variable | Default | Description |
| --- | --- | --- |
| `TOKEN` | — | Require authentication on all endpoints |
| `ALLOW_FILE_PROTOCOL` | `false` | Allow `file://` URLs in browser |

### Sessions

| Variable | Default | Description |
| --- | --- | --- |
| `CONCURRENT` | `10` | Max concurrent browser sessions |
| `QUEUED` | `10` | Max queued requests before `429` reject |
| `TIMEOUT` | `30000` | Session timeout ms (`-1` for no timeout) |
| `RETRIES` | `5` | Connection retry attempts |
| `MAX_PAYLOAD_SIZE` | `10485760` | Max request size in bytes (default 10MB) |
| `MAX_CPU_PERCENT` | `99` | CPU usage limit percentage |
| `MAX_MEMORY_PERCENT` | `99` | Memory usage limit percentage |

### Alerts

| Variable | Default | Description |
| --- | --- | --- |
| `HEALTH` | `false` | Enable pre-request health checks |
| `FAILED_HEALTH_URL` | — | POST webhook when health check fails |
| `QUEUE_ALERT_URL` | — | POST webhook when queue is non-empty |
| `REJECT_ALERT_URL` | — | POST webhook when request is rejected |
| `TIMEOUT_ALERT_URL` | — | POST webhook on session timeout |
| `ERROR_ALERT_URL` | — | POST webhook on errors |

### CORS

| Variable | Default | Description |
| --- | --- | --- |
| `ALLOW_CORS` | `false` | Enable CORS support |
| `CORS_ALLOW_CREDENTIALS` | `true` | Allow credentials in CORS header |
| `CORS_ALLOW_HEADERS` | `*` | Headers to allow in CORS requests |
| `CORS_ALLOW_METHODS` | `OPTIONS, POST, GET` | Methods to allow in CORS requests |
| `CORS_ALLOW_ORIGIN` | `*` | Origin pattern to match against |
| `CORS_EXPOSE_HEADERS` | `*` | Headers to expose in CORS responses |
| `CORS_MAX_AGE` | `2592000` | CORS preflight cache duration (seconds) |

### Browser APIs

| Variable | Default | Description |
| --- | --- | --- |
| `ALLOW_GET` | `false` | Allow GET-style calls on browser APIs via `?body=JSON` |

### Directories

| Variable | Default | Description |
| --- | --- | --- |
| `DATA_DIR` | `/user-data` | Browser profile persistence directory (recommended not to change) |
| `DOWNLOAD_DIR` | `/downloads` | Download directory (recommended not to change) |
| `METRICS_JSON_PATH` | `tmpdir` | Path to write metrics JSON file |
| `ROUTES` | `build/routes` | Custom API routes directory |
| `STATIC` | `static` | Static file directory for debugger |

### Reverse Proxy

| Variable | Default | Description |
| --- | --- | --- |
| `EXTERNAL` | — | External URL for reverse proxy (sets `wss://` protocol) |

### Debugger

| Variable | Default | Description |
| --- | --- | --- |
| `ENABLE_DEBUGGER` | `true` | Enable built-in debugger endpoint |

### Metrics

| Variable | Default | Description |
| --- | --- | --- |
| `MACHINE_STATS_SOURCE` | `auto` | CPU/memory stats source: `auto`, `host`, or `cgroup` |

### Localization

| Variable | Default | Description |
| --- | --- | --- |
| `TZ` | `UTC` | Timezone (e.g. `Europe/London`) |


