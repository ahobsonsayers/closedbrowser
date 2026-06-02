FROM node:22-alpine AS builder

ARG BLITZBROWSER_COMMIT=3e86847eb3aaa153645d2632cf42905cd43fa70b

RUN apk add --no-cache \
    ca-certificates \
    git

RUN corepack enable && \
    corepack prepare pnpm@9 --activate

RUN git clone https://github.com/blitzbrowser/blitzbrowser.git /blitzbrowser && \
    git -C /blitzbrowser checkout "$BLITZBROWSER_COMMIT"

COPY scripts /tmp/scripts
COPY patches /tmp/patches
RUN chmod +x /tmp/scripts/*.sh && \
    /tmp/scripts/01-patch-dashboard.sh

WORKDIR /blitzbrowser/dashboard

RUN rm -f pnpm-workspace.yaml
RUN pnpm install --frozen-lockfile
RUN pnpm build

FROM gcr.io/distroless/nodejs22-debian12:nonroot

WORKDIR /app

COPY --from=builder /blitzbrowser/dashboard/node_modules ./node_modules
COPY --from=builder /blitzbrowser/dashboard/build ./build

EXPOSE 3000

CMD ["build/index.js"]
