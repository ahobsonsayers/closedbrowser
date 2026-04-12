FROM ghcr.io/browserless/chromium:v2.46.0

USER root

ENV DATA_DIR=/user-data
ENV DOWNLOAD_DIR=/downloads
ENV EXTENSIONS_DIR=$APP_DIR/extensions

# Add scripts
COPY scripts /tmp/scripts

# Setup browser
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq unzip && \
    /tmp/scripts/01-install-extensions.sh && \
    /tmp/scripts/02-setup-alias.sh && \
    rm -rf /tmp/scripts && \
    rm -rf /var/lib/apt/lists/*

# Apply patchright anti-detection patches
RUN npm install -g patchright@latest && \
    GLOBAL_NPM=$(npm root -g) && \
    PW_CORE="/usr/src/app/node_modules/playwright-core" && \
    cp "$PW_CORE/browsers.json" /tmp/browsers.json && \
    rm -rf "$PW_CORE" && \
    cp -r "$GLOBAL_NPM/patchright/node_modules/patchright-core" "$PW_CORE" && \
    cp /tmp/browsers.json "$PW_CORE/browsers.json" && \
    rm /tmp/browsers.json

# Create directories
RUN mkdir -p "$DATA_DIR" "$DOWNLOAD_DIR" && \
    chown -R blessuser:blessuser "$DATA_DIR" "$DOWNLOAD_DIR"

USER blessuser