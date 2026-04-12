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

| Variable     | Default | Description                              |
| ------------ | ------- | ---------------------------------------- |
| `TOKEN`      | —       | Require authentication on all endpoints  |
| `CONCURRENT` | `10`    | Max concurrent browser sessions          |
| `QUEUED`     | `10`    | Max queued requests before `429` reject  |
| `TIMEOUT`    | `30000` | Session timeout ms (`-1` for no timeout) |
| `TZ`         | `UTC`   | Timezone (e.g. `Europe/London`)          |
