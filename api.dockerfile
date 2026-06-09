FROM node:22-alpine AS builder

ARG BLITZBROWSER_COMMIT=3e86847eb3aaa153645d2632cf42905cd43fa70b

# Install system dependencies
RUN apk add --no-cache \
    ca-certificates \
    git

RUN corepack enable && \
    corepack prepare pnpm@9 --activate

WORKDIR /app

# Clone code
RUN git clone https://github.com/blitzbrowser/blitzbrowser . && \
    git checkout "$BLITZBROWSER_COMMIT"

# Apply patch
COPY patches /tmp/patches
RUN git apply /tmp/patches/api.patch

WORKDIR /app/blitzbrowser

# Build application
ENV PUPPETEER_SKIP_DOWNLOAD=true
RUN pnpm install --frozen-lockfile
RUN pnpm build

FROM cloakhq/cloakbrowser:latest AS cloakbrowser

# Move cloakbrowser to a stable location
RUN CLOAKBROWSER_DIR=$(find /root/.cloakbrowser -maxdepth 1 -type d -name "chromium-*" | head -1) && \
    mv "$CLOAKBROWSER_DIR" /chromium

FROM debian:stable-slim

ENV HOME=/app
ENV DATA_DIR=/data

ENV BROWSER_EXECUTABLE_PATH=/opt/cloakbrowser/chrome
ENV CLOAKBROWSER_AUTO_UPDATE=false

ENV GLOBAL_EXTENSIONS_DIR=$HOME/extensions
ENV USER_EXTENSIONS_DIR=$DATA_DIR/extensions

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # BlitzBrowser dependencies
    ca-certificates \
    curl \
    fluxbox \
    fonts-noto-color-emoji \
    fonts-recommended \
    jq \
    tini \
    unzip \
    x11vnc \
    xvfb \
    # CloakBrowser dependencies
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcairo-gobject2 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libfontconfig1 \
    libgbm1 \
    libgdk-pixbuf-2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxshmfence1 \
    libxss1 \
    libxtst6 && \
    rm -rf /var/lib/apt/lists/*

# Install extra dependancies
COPY --chmod=0755 --from=tianon/gosu:debian /gosu /usr/local/bin/gosu
COPY --chmod=0755 --from=oven/bun:latest /usr/local/bin/bun /usr/local/bin/bun

# User and directory setup
RUN useradd browser --uid 1001 --no-create-home && \
    rm -rf /root && \
    mkdir -p \
      $HOME \
      /app/.cache/fontconfig \
      /var/cache/fontconfig \
      /data/user-data \
      /data/extensions \
      /data/browsers && \
    chown browser:browser \
      $HOME \
      /data/user-data \
      /data/extensions \
      /data/browsers \
      /app/.cache/fontconfig \
      /var/cache/fontconfig && \
    fc-cache -f -v

WORKDIR $HOME

COPY --from=builder --chown=browser:browser /app/blitzbrowser/package.json ./package.json
COPY --from=builder --chown=browser:browser /app/blitzbrowser/node_modules ./node_modules
COPY --from=builder --chown=browser:browser /app/blitzbrowser/dist ./dist

COPY --from=cloakbrowser --chown=browser:browser /chromium/ /opt/cloakbrowser/

# Install extensions
COPY scripts/install-extensions.sh /tmp/install-extensions.sh
RUN /tmp/install-extensions.sh && \
    rm -rf /tmp/*

# Add entrypoint
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["tini", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
