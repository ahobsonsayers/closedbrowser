FROM ghcr.io/browserless/chromium:v2.47.0

USER root

# Directory environment variables.
# It is recommend to not override these at run time.
ENV MOUNT_DIR=/data
ENV DATA_DIR=$MOUNT_DIR/profiles
ENV DOWNLOAD_DIR=$MOUNT_DIR/downloads

ENV GLOBAL_EXTENSIONS_DIR=$APP_DIR/extensions
ENV USER_EXTENSIONS_DIR=$MOUNT_DIR/extensions

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

# Install gosu
COPY --chmod=0755 --from=tianon/gosu:debian /gosu /usr/local/bin/gosu

ENTRYPOINT ["/usr/src/app/scripts/entrypoint.sh"]
