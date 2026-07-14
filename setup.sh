#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# OpenClaw Bot — سكريبت الإعداد التلقائي لسيرفر fps.ms / Linux VPS
# يعمل على: Ubuntu 20.04+ / Debian 11+ / CentOS Stream 8+
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOT_DIR="$SCRIPT_DIR"

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       OpenClaw AI Telegram Bot — Auto Setup          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Check OS ────────────────────────────────────────────────────────────────
info "Checking system..."
if command -v apt-get &>/dev/null; then
  PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
  PKG_MGR="dnf"
elif command -v yum &>/dev/null; then
  PKG_MGR="yum"
else
  warn "Unknown package manager. Proceeding without system packages."
  PKG_MGR="none"
fi
success "OS: $(uname -a | cut -d' ' -f1-3)"

# ── 2. Install Node.js 22+ ─────────────────────────────────────────────────────
info "Checking Node.js..."
if command -v node &>/dev/null; then
  NODE_VER=$(node -e "console.log(process.version)" 2>/dev/null || echo "v0")
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d'.' -f1)
  if [ "$NODE_MAJOR" -ge 22 ]; then
    success "Node.js $NODE_VER already installed"
  else
    warn "Node.js $NODE_VER is too old (need v22+). Installing..."
    INSTALL_NODE=true
  fi
else
  INSTALL_NODE=true
fi

if [ "${INSTALL_NODE:-false}" = true ]; then
  if [ "$PKG_MGR" = "apt" ]; then
    info "Installing Node.js 22 via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
    sudo apt-get install -y nodejs
  elif [ "$PKG_MGR" = "dnf" ] || [ "$PKG_MGR" = "yum" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
    sudo $PKG_MGR install -y nodejs
  else
    error "Please install Node.js 22+ manually: https://nodejs.org"
  fi
  success "Node.js $(node -v) installed"
fi

# ── 3. Install system deps for Chromium (browser tool) ───────────────────────
info "Installing Chromium system dependencies..."
if [ "$PKG_MGR" = "apt" ]; then
  sudo apt-get install -y \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2 libxshmfence1 fonts-liberation ca-certificates \
    libnspr4 libdbus-1-3 libexpat1 2>/dev/null || warn "Some Chromium deps failed (may still work)"
elif [ "$PKG_MGR" = "dnf" ] || [ "$PKG_MGR" = "yum" ]; then
  sudo $PKG_MGR install -y nss atk at-spi2-atk cups-libs libdrm libXkbcommon \
    libXcomposite libXdamage libXfixes libXrandr mesa-libgbm pango cairo \
    alsa-lib libXshmfence liberation-fonts 2>/dev/null || true
fi

# ── 4. Install Python3 + pip (for yt-dlp) ────────────────────────────────────
info "Checking Python3 + yt-dlp..."
if ! command -v python3 &>/dev/null; then
  [ "$PKG_MGR" = "apt" ] && sudo apt-get install -y python3 python3-pip
  [ "$PKG_MGR" != "apt" ] && sudo $PKG_MGR install -y python3 python3-pip
fi
YTDLP_PATH="$HOME/.local/bin/yt-dlp"
if ! command -v yt-dlp &>/dev/null && [ ! -f "$YTDLP_PATH" ]; then
  info "Installing yt-dlp..."
  pip3 install -q --user yt-dlp || pip3 install -q yt-dlp
fi
YTDLP_PATH=$(command -v yt-dlp 2>/dev/null || echo "$HOME/.local/bin/yt-dlp")
[ -f "$YTDLP_PATH" ] && success "yt-dlp: $YTDLP_PATH" || warn "yt-dlp not found — YouTube/Spotify tools won't work"

# ── 5. Install openclaw globally ──────────────────────────────────────────────
info "Checking openclaw..."
if ! command -v openclaw &>/dev/null; then
  info "Installing openclaw globally..."
  npm install -g openclaw 2>&1 | tail -5
  success "openclaw $(openclaw --version 2>/dev/null || echo 'installed')"
else
  success "openclaw $(openclaw --version 2>/dev/null) already installed"
fi

# ── 6. Install media-tools plugin dependencies ───────────────────────────────
info "Installing media-tools plugin dependencies..."
cd "$BOT_DIR/plugins/media-tools"
npm install --omit=dev 2>&1 | tail -3
cd "$BOT_DIR"
success "Plugin dependencies installed"

# ── 7. Update run.sh with correct yt-dlp path ────────────────────────────────
sed -i "s|YTDLP_PATH=.*|YTDLP_PATH=\"$YTDLP_PATH\"|" "$BOT_DIR/run.sh" 2>/dev/null || true

# ── 8. Make scripts executable ────────────────────────────────────────────────
chmod +x "$BOT_DIR/run.sh"
success "Scripts ready"

# ── 9. Create .env template if it doesn't exist ───────────────────────────────
if [ ! -f "$BOT_DIR/.env" ]; then
  cat > "$BOT_DIR/.env" <<'EOF'
# ════════════════════════════════════════════════════════
# OpenClaw Bot — Environment Variables
# Fill in ALL required values before starting the bot
# ════════════════════════════════════════════════════════

# [REQUIRED] Telegram bot token from @BotFather
TELEGRAM_BOT_TOKEN=

# [REQUIRED] At least one AI provider key
GOOGLE_API_KEY=          # aistudio.google.com (FREE tier available)
OPENAI_API_KEY=          # platform.openai.com
OPENROUTER_API_KEY=      # openrouter.ai (FREE models available)

# [OPTIONAL] Your Telegram user ID (get it from @userinfobot)
# Default is already set in run.sh
ADMIN_TELEGRAM_ID=6570434162
EOF
  success ".env template created at $BOT_DIR/.env"
  echo ""
  warn "⚠️  IMPORTANT: Edit $BOT_DIR/.env and add your API keys!"
  echo ""
fi

# ── 10. Setup systemd service (optional) ─────────────────────────────────────
if [ "${SETUP_SYSTEMD:-true}" = "true" ] && command -v systemctl &>/dev/null; then
  SERVICE_FILE="$HOME/.config/systemd/user/openclaw-bot.service"
  mkdir -p "$(dirname "$SERVICE_FILE")"
  OPENCLAW_BIN=$(command -v openclaw)
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=OpenClaw AI Telegram Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$BOT_DIR
ExecStart=/bin/bash $BOT_DIR/run.sh
Restart=always
RestartSec=15
EnvironmentFile=$BOT_DIR/.env
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload 2>/dev/null || true
  success "Systemd service created: $SERVICE_FILE"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ Setup Complete!                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "  1. Edit ${BLUE}$BOT_DIR/.env${NC} and add your API keys"
echo -e "  2. Add cookies (optional):"
echo -e "     • YouTube: ${BLUE}$BOT_DIR/cookies/youtube.txt${NC}"
echo -e "     • Spotify: ${BLUE}$BOT_DIR/cookies/spotify.txt${NC}"
echo -e "  3. Start the bot:"
echo -e "     ${GREEN}source $BOT_DIR/.env && bash $BOT_DIR/run.sh${NC}"
echo ""
echo -e "  ${YELLOW}Or use systemd (auto-start + auto-restart):${NC}"
echo -e "     ${GREEN}systemctl --user enable --now openclaw-bot${NC}"
echo ""
