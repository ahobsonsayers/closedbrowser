FROM node:22-alpine AS builder

ARG BLITZBROWSER_COMMIT=3e86847eb3aaa153645d2632cf42905cd43fa70b

# Install system dependencies
RUN apk add --no-cache \
    ca-certificates \
    git

RUN corepack enable && \
    corepack prepare pnpm@9 --activate

WORKDIR /blitzbrowser

# Clone code
RUN git clone https://github.com/blitzbrowser/blitzbrowser . && \
    git checkout "$BLITZBROWSER_COMMIT"

# Apply patch
COPY patches /tmp/patches
RUN git apply /tmp/patches/fix-api-no-sandbox.patch

WORKDIR /blitzbrowser/blitzbrowser

# Build application
RUN pnpm install --frozen-lockfile
RUN pnpm build

FROM ghcr.io/puppeteer/puppeteer:latest

ENV MOUNT_DIR=/data
ENV APP_DIR=/home/pptruser
ENV GLOBAL_EXTENSIONS_DIR=$APP_DIR/extensions
ENV USER_EXTENSIONS_DIR=$MOUNT_DIR/extensions

USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fluxbox \
    fonts-noto-color-emoji \
    fonts-recommended \
    tini \
    xvfb \
    x11vnc && \
    rm -rf /var/lib/apt/lists/*

# Install gosu
COPY --chmod=0755 --from=tianon/gosu:debian /gosu /usr/local/bin/gosu

# Font cache setup
RUN fc-cache -f -v

# Directory setup
RUN rm -rf /home/pptruser/node_modules && \
    mkdir -p \
      /.cache/fontconfig \
      /blitzbrowser/browsers \
      /blitzbrowser/user-data \
      /var/cache/fontconfig && \
    chmod -R 777 \
      /.cache/fontconfig \
      /blitzbrowser/browsers \
      /blitzbrowser/user-data \
      /var/cache/fontconfig

WORKDIR /home/pptruser

COPY --from=builder /blitzbrowser/blitzbrowser/package.json ./package.json
COPY --from=builder /blitzbrowser/blitzbrowser/node_modules ./node_modules
COPY --from=builder /blitzbrowser/blitzbrowser/dist ./dist

# Add scripts
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["tini", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
