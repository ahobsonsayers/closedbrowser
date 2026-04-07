# closedbrowser

A containerised Brave browser built on [kernel-images](https://github.com/kernel/kernel-images), with uBlock Origin and I Still Don't Care About Cookies pre-installed.

## Running

```bash
docker compose up -d
```

## Ports

| Port              | Description                                                                                                     |
| ----------------- | --------------------------------------------------------------------------------------------------------------- |
| `8080`            | **Live view** — WebRTC stream via [Neko](https://github.com/m1k1o/neko). Enable by setting `ENABLE_WEBRTC=true` |
| `56000-56100/udp` | WebRTC Ports. Required when `ENABLE_WEBRTC=true`                                                                |
| `10001`           | Recording API                                                                                                   |
| `9222`            | **CDP** — Chrome DevTools Protocol. Use with Playwright or Puppeteer                                            |
| `9224`            | **ChromeDriver** — WebDriver/W3C protocol. Use with Selenium. Not needed otherwise                              |

## Persistence

By default browser data is ephemeral and lost on container restart. To persist the profile (history, cookies, settings) mount the `user-data` directory:

```yaml
volumes:
  - ./user-data:/home/kernel/user-data
```

## Extensions

[uBlock Origin](https://github.com/gorhill/uBlock) and [I Still Don't Care About Cookies](https://github.com/OhMyGuus/I-Still-Dont-Care-About-Cookies) are pre-installed.

To add your own, drop an unpacked extension directory (must contain a `manifest.json`) into `user-data/extensions/` and restart the container. Requires the `user-data` mount above.

## Environment variables

| Variable                        | Default       | Description                                                                                          |
| ------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------- |
| `ENABLE_WEBRTC`                 | `false`       | Set to `true` to enable the Neko live view on port `8080`. Also requires exposing `56000-56100/udp`. |
| `WIDTH`                         | `1920`        | Browser window width in pixels                                                                       |
| `HEIGHT`                        | `1080`        | Browser window height in pixels                                                                      |
| `TZ`                            | —             | Timezone (e.g. `Europe/London`)                                                                      |
| `CHROMIUM_FLAGS`                | —             | Additional flags passed to Brave at startup                                                          |
| `PLAYWRIGHT_ENGINE`             | `false`       | Set to `true` to enable Playwright support                                                           |
| `KERNEL_IMAGES_API_FRAME_RATE`  | `10`          | Recording frame rate                                                                                 |
| `KERNEL_IMAGES_API_MAX_SIZE_MB` | `500`         | Maximum recording file size in MB                                                                    |
| `KERNEL_IMAGES_API_OUTPUT_DIR`  | `/recordings` | Directory where recordings are saved                                                                 |
