FROM ghcr.io/browserless/chromium:v2.47.0

USER root

# Directory environment variables.
# It is recommend to not override these at run time.
ENV DATA_DIR=/user-data
ENV DOWNLOAD_DIR=/downloads
ENV GLOBAL_EXTENSIONS_DIR=$APP_DIR/extensions
ENV USER_EXTENSIONS_DIR=/user-extensions

# Add scripts and patches
COPY scripts /tmp/scripts
COPY patches /tmp/patches
COPY scripts/entrypoint.sh /usr/src/app/scripts/entrypoint.sh

# Setup browser
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq unzip && \
    /tmp/scripts/01-patch-browserless.sh && \
    /tmp/scripts/02-install-extensions.sh && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

# Create directories and fix permissions
RUN mkdir -p "$DATA_DIR" "$DOWNLOAD_DIR" "$USER_EXTENSIONS_DIR" && \
    chown -R blessuser:blessuser "$DATA_DIR" "$DOWNLOAD_DIR" "$GLOBAL_EXTENSIONS_DIR" "$USER_EXTENSIONS_DIR"

USER blessuser

ENTRYPOINT ["/usr/src/app/scripts/entrypoint.sh"]
