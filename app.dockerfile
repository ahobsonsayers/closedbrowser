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
RUN git apply /tmp/patches/fix-ui-ws-protocol.patch

WORKDIR /blitzbrowser/dashboard

# Build application
RUN rm -f pnpm-workspace.yaml
RUN pnpm install --frozen-lockfile
RUN pnpm build

FROM gcr.io/distroless/nodejs22-debian12:nonroot

WORKDIR /app

COPY --from=builder /blitzbrowser/dashboard/node_modules ./node_modules
COPY --from=builder /blitzbrowser/dashboard/build ./build

EXPOSE 3000

CMD ["build/index.js"]
