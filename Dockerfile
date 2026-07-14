FROM node:22-slim

# ── Chromium system deps (for browser tool) ──────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2 libxshmfence1 \
    libnspr4 fonts-liberation ca-certificates wget curl python3 python3-pip \
  && pip3 install --no-cache-dir yt-dlp \
  && rm -rf /var/lib/apt/lists/*

# ── Install openclaw globally ─────────────────────────────────────────────────
RUN npm install -g openclaw

WORKDIR /app
COPY . .
RUN chmod +x run.sh setup.sh

# ── Pre-download Chromium (cached in image layer) ─────────────────────────────
ENV PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright
RUN cd $(node -e "try{console.log(require.resolve('openclaw').replace('/dist/index.js','')+'/node_modules/playwright-core')}catch{}") \
  && node cli.js install chromium --with-deps 2>/dev/null || true

# ── Install plugin dependencies ───────────────────────────────────────────────
RUN cd /app/plugins/media-tools && npm install --omit=dev

# Runtime secrets via environment variables — never bake into image
# docker run --env-file .env openclaw-bot
CMD ["bash", "run.sh"]
