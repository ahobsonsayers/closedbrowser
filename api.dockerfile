ARG BLITZBROWSER_DIGEST=sha256:e55df2057ad9087931a6871e3b8aac9a5ad24cac267b710cc6029812eb456087
FROM ghcr.io/blitzbrowser/blitzbrowser:latest@${BLITZBROWSER_DIGEST}

USER root

# Directory environment variables.
# It is recommend to not override these at run time.
ENV MOUNT_DIR=/data
ENV APP_DIR=/home/pptruser
ENV GLOBAL_EXTENSIONS_DIR=$APP_DIR/extensions
ENV USER_EXTENSIONS_DIR=$MOUNT_DIR/extensions

# Install gosu
COPY --chmod=0755 --from=tianon/gosu:debian /gosu /usr/local/bin/gosu

# Add scripts and patches
COPY scripts /tmp/scripts
COPY patches /tmp/patches
COPY scripts/entrypoint.sh /usr/src/app/scripts/entrypoint.sh

# Setup browser
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq unzip && \
    chmod +x /tmp/scripts/*.sh && \
    /tmp/scripts/01-patch-blitzbrowser.sh && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

RUN cd $APP_DIR && npm run build

ENTRYPOINT ["/usr/src/app/scripts/entrypoint.sh"]
