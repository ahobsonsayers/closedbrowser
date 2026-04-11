FROM ghcr.io/browserless/chromium:latest

USER root

ENV DATA_DIR=/user-data
ENV DOWNLOAD_DIR=/downloads
ENV EXTENSIONS_DIR=$APP_DIR/extensions

# Add scripts
COPY scripts /tmp/scripts

# Install Brave browser, remove Chromium, and setup
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq unzip && \
    /tmp/scripts/uninstall-chromium.sh && \
    /tmp/scripts/install-brave.sh && \
    /tmp/scripts/01-install-extensions.sh && \
    /tmp/scripts/patch-wrapper.sh && \
    rm -rf /tmp/scripts && \
    rm -rf /var/lib/apt/lists/*

# Add brave browser policies
COPY brave/policies.json /etc/brave/policies/managed/policies.json

# Create directories
RUN mkdir -p "$DATA_DIR" "$DOWNLOAD_DIR" && \
    chown -R blessuser:blessuser "$DATA_DIR" "$DOWNLOAD_DIR"

USER blessuser