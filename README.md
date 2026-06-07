# closedbrowser

A containerised Chromium browser built on [BlitzBrowser](https://github.com/blitzbrowser/blitzbrowser), with I Still Don't Care About Cookies and NopeCHA pre-installed.

## Usage

For instructions on running the container, see [Running](#running).

This image is primarily designed for use with an AI agent. As such, there is an LLM skill at `skills/closedbrowser` which will guide your agent to use this image. This skill will allow you to use either [browser-use](https://github.com/browser-use/browser-use) (recommended) or [agent-browser](https://github.com/all_in_oss/agent-browser) to interact with the browser running in the container.

You will need to have one of these tools installed:
- [browser-use](https://docs.browser-use.com/open-source/browser-use-cli) — recommended
- [agent-browser](https://agent-browser.dev)

If you have both installed, you will be asked which one to use.

See the skill at `skills/closedbrowser` for more details on setup.

### Skill config (environment variables)

| Variable                          | Required | Description                                                            |
| --------------------------------- | -------- | ---------------------------------------------------------------------- |
| `CLOSEDBROWSER_API_URL`           | Yes      | CDP WebSocket URL (e.g., `ws://localhost:9999` or `wss://browser.example.com`) |
| `CLOSEDBROWSER_API_KEY`           | No       | API key for authenticated containers (only if container has `API_KEY` set) |
| `CLOSEDBROWSER_DASHBOARD_URL`    | No       | Dashboard URL for live view (e.g., `https://browser.example.com`)      |
| `CLOSEDBROWSER_DEFAULT_PROFILE`  | No       | Default profile for persistence (e.g., `my-profile`). Only one session can use a given profile at a time. |

### CDP URL

The skill constructs a CDP URL to connect to the browser. The base format is:

```
ws://localhost:9999
wss://browser.example.com
```

If `CLOSEDBROWSER_API_KEY` is set, it's appended as a query param:

```
ws://localhost:9999?apiKey=YOUR_API_KEY
```

For persistence, use `userDataId`:

```
ws://localhost:9999?apiKey=YOUR_API_KEY&userDataId=my-profile
```

For live view, add `liveView=true`:

```
ws://localhost:9999?apiKey=YOUR_API_KEY&userDataId=my-profile&liveView=true
```

## Running

```bash
docker compose up -d
```

## Ports

| Port   | Description              |
| ------ | ------------------------ |
| `9999` | BlitzBrowser CDP/API     |
| `3000` | Dashboard (app service)  |

## Volumes

```yaml
volumes:
  - ./blitzbrowser:/blitzbrowser
```

| Directory                    | Description                                          |
| ---------------------------- | ---------------------------------------------------- |
| `/blitzbrowser/extensions/` | Custom extensions (must contain `manifest.json`)    |
| `/blitzbrowser/user-data`   | Browser profiles (cookies, local storage)            |
| `/blitzbrowser/browsers`   | Downloaded browser binaries                          |

**Note:** Create the directories on the host before running to prevent permission issues:

```bash
mkdir -p ./blitzbrowser
docker compose up -d
```

### Extensions

[I Still Don't Care About Cookies](https://github.com/OhMyGuus/I-Still-Dont-Care-About-Cookies) and [NopeCHA](https://github.com/NopeCHALLC/nopecha-extension) are pre-installed.

To add your own, drop an unpacked extension directory (must contain a `manifest.json`) into `./extensions/` on the host and restart the container.

## Environment variables

To enable authentication, set `API_KEY` on the API service and `AUTH_KEY` on the dashboard. You can securely generate a key with:

```bash
openssl rand -hex 32
```

### API service (closedbrowser-api)

| Variable                    | Default | Description                                                |
| --------------------------- | ------- | ---------------------------------------------------------- |
| `API_KEY`                   | —       | Require authentication on all endpoints                    |
| `MAX_BROWSER_INSTANCES`    | `99`    | Max concurrent browser sessions                            |
| `DISABLE_SHM`               | —       | Disable shared memory (set if you can't configure `shm_size`) |
| `EXTENSION_NOPECHA_API_KEY` | —       | NopeCHA extension API key (optional, 100 free credits/24h) |
| `TZ`                        | `UTC`   | Timezone (e.g., `Europe/London`)                           |

### Dashboard service (closedbrowser-app)

| Variable                | Default                  | Description                                                  |
| ----------------------- | ------------------------ | ------------------------------------------------------------ |
| `BLITZBROWSER_API_URL`  | `http://localhost:9999`  | BlitzBrowser API URL (must be accessible from your browser)  |
| `BLITZBROWSER_API_KEY`  | —                        | API key if BlitzBrowser requires auth                        |
| `AUTH_KEY`              | —                        | Dashboard login key (separate from `API_KEY`)                |
| `HTTPS_DISABLED`        | —                        | Set to `true` to allow HTTP connections to the dashboard     |

## CDP Query Parameters

Append query params to the WebSocket URL:

```
ws://localhost:9999?userDataId=my-profile&liveView=true
```

### Browser Properties

| Parameter          | Description                                                       | Example                          |
| ------------------ | ----------------------------------------------------------------- | -------------------------------- |
| `userDataId`       | Persist session data (matches `/^[a-zA-Z0-9-_]{1,64}$/`)        | `?userDataId=my-profile`         |
| `userDataReadOnly` | Load profile without saving changes (`true`/`false`)             | `?userDataReadOnly=true`         |
| `liveView`         | Enable live view in dashboard                                     | `?liveView=true`                  |
| `proxyUrl`         | HTTP proxy URL (`http://user:pass@host:port`)                    | `?proxyUrl=http://...`           |
| `timezone`         | Override browser timezone                                         | `?timezone=Europe/London`        |
| `browserVersion`   | Chrome version (`default`, `latest`, or specific version)        | `?browserVersion=latest`         |

### Authentication

| Method | Format |
| ------ | ------ |
| Query param | `?apiKey=YOUR_API_KEY` |
| HTTP header | `x-api-key: YOUR_API_KEY` |

## Docker Compose

```yaml
services:
  api:
    container_name: closedbrowser-api
    image: arranhs/closedbrowser:latest
    restart: unless-stopped
    shm_size: 1g
    networks:
      - closedbrowser
    ports:
      - 9999:9999
    volumes:
      - ./blitzbrowser:/blitzbrowser
    environment:
      - API_KEY=my-secret-api-key
      - TZ=Europe/London

  app: # optional — dashboard for live view
    container_name: closedbrowser-app
    image: arranhs/closedbrowser-app:latest
    restart: unless-stopped
    networks:
      - closedbrowser
    ports:
      - 3000:3000
    environment:
      - BLITZBROWSER_API_URL=http://localhost:9999
      - BLITZBROWSER_API_KEY=my-secret-api-key
      - HTTPS_DISABLED=true

networks:
  closedbrowser:
```