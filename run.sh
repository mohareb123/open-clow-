#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# OpenClaw Bot — VPS/Server Launcher  (fps.ms, DigitalOcean, Hetzner, etc.)
# النموذج الأساسي: Gemini 2.5 Flash
# البدائل: OpenAI → OpenRouter → Pollinations AI (مجاني)
# الأدوات: يوتيوب ، سبوتيفاي ، بحث ويب ، متصفح ، توليد صور مجاني
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
CONFIG="$OPENCLAW_DIR/openclaw.json"
CREDS_DIR="$OPENCLAW_DIR/credentials"
LOG_DIR="$OPENCLAW_DIR/logs"
COOKIES_DIR="$OPENCLAW_DIR/cookies"
TOKEN_FILE="$OPENCLAW_DIR/.gateway-token"
PLUGIN_DIR="$SCRIPT_DIR/plugins/media-tools"
ADMIN_ID="${ADMIN_TELEGRAM_ID:-6570434162}"   # override via env or edit here

# ── Playwright browsers path ──────────────────────────────────────────────────
export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/ms-playwright"

mkdir -p "$LOG_DIR" "$CREDS_DIR" "$COOKIES_DIR" "$HOME/.cache/ms-playwright"

# ── Validate required secrets ──────────────────────────────────────────────────
: "${TELEGRAM_BOT_TOKEN:?❌ Set TELEGRAM_BOT_TOKEN}"
if [ -z "${GOOGLE_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ Set GOOGLE_API_KEY or OPENAI_API_KEY" >&2; exit 1
fi

# ── Persist gateway auth token ─────────────────────────────────────────────────
if [ ! -f "$TOKEN_FILE" ]; then
  node -e "process.stdout.write(require('crypto').randomBytes(32).toString('hex'))" \
    > "$TOKEN_FILE" && chmod 600 "$TOKEN_FILE"
fi
GATEWAY_TOKEN=$(cat "$TOKEN_FILE")

# ── AllowFrom (Telegram admin) ────────────────────────────────────────────────
printf '{"version":1,"allowFrom":["%s"]}' "$ADMIN_ID" \
  > "$CREDS_DIR/telegram-default-allowFrom.json"
chmod 600 "$CREDS_DIR/telegram-default-allowFrom.json"

# ── Copy cookies if present ────────────────────────────────────────────────────
[ -f "$SCRIPT_DIR/cookies/youtube.txt" ]  && cp "$SCRIPT_DIR/cookies/youtube.txt"  "$COOKIES_DIR/youtube.txt"  && chmod 600 "$COOKIES_DIR/youtube.txt"
[ -f "$SCRIPT_DIR/cookies/spotify.txt" ]  && cp "$SCRIPT_DIR/cookies/spotify.txt"  "$COOKIES_DIR/spotify.txt"  && chmod 600 "$COOKIES_DIR/spotify.txt"
echo "[run.sh] Cookies: $(ls "$COOKIES_DIR" 2>/dev/null | tr '\n' ' ')"

# ── Install Chromium for browser tool (once, ~175MB) ──────────────────────────
PLAYWRIGHT_CORE_DIR=$(node -e "
try { console.log(require.resolve('openclaw').replace('/dist/index.js','') + '/node_modules/playwright-core'); } catch {}
try { const p=require.resolve('playwright-core'); console.log(p.replace('/index.js','').replace('/lib/index.js','')); } catch {}
" 2>/dev/null | grep "playwright-core" | head -1 || true)

CHROMIUM_BIN=$(ls -d "$PLAYWRIGHT_BROWSERS_PATH"/chromium-*/chrome-linux64/chrome 2>/dev/null | tail -1 || true)
if [ -z "$CHROMIUM_BIN" ] || [ ! -x "$CHROMIUM_BIN" ]; then
  if [ -n "$PLAYWRIGHT_CORE_DIR" ] && [ -f "$PLAYWRIGHT_CORE_DIR/cli.js" ]; then
    echo "[run.sh] Installing Chromium (~175MB)..."
    cd "$PLAYWRIGHT_CORE_DIR" && node cli.js install chromium 2>&1 | tail -5 || true
    cd "$SCRIPT_DIR"
    CHROMIUM_BIN=$(ls -d "$PLAYWRIGHT_BROWSERS_PATH"/chromium-*/chrome-linux64/chrome 2>/dev/null | tail -1 || true)
  fi
fi
[ -n "$CHROMIUM_BIN" ] && [ -x "$CHROMIUM_BIN" ] \
  && echo "[run.sh] Chromium: $CHROMIUM_BIN ✓" \
  || { CHROMIUM_BIN=""; echo "[run.sh] ⚠️  Chromium not found — browser tool disabled."; }

# ── Primary model ──────────────────────────────────────────────────────────────
[ -n "${GOOGLE_API_KEY:-}" ] && PRIMARY="google/gemini-2.5-flash" || PRIMARY="openai/gpt-4o-mini"

# ── Fallback list ──────────────────────────────────────────────────────────────
node -e "
const f=[];
if(process.env.GOOGLE_API_KEY && process.env.PRIMARY!=='google/gemini-2.5-flash') f.push('google/gemini-2.5-flash');
if(process.env.OPENAI_API_KEY) f.push('openai/gpt-4o-mini');
if(process.env.OPENROUTER_API_KEY) f.push('openrouter/google/gemini-2.5-flash:free');
f.push('pollinations/openai-fast');
process.stdout.write(JSON.stringify(f));
" PRIMARY="$PRIMARY" > /tmp/oc_fallbacks.json 2>/dev/null
FALLBACKS=$(cat /tmp/oc_fallbacks.json)

# ── Write openclaw.json ────────────────────────────────────────────────────────
echo "[run.sh] Writing config — primary: $PRIMARY"
OPENCLAW_CONFIG="$CONFIG" GATEWAY_TOKEN="$GATEWAY_TOKEN" \
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
GOOGLE_API_KEY="${GOOGLE_API_KEY:-}" OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}" \
ADMIN_ID="$ADMIN_ID" PRIMARY="$PRIMARY" FALLBACKS="$FALLBACKS" \
CHROMIUM_BIN="$CHROMIUM_BIN" \
node -e "
const fs=require('fs'), path=require('path');
const cfg=process.env.OPENCLAW_CONFIG;
const hasG=!!process.env.GOOGLE_API_KEY, hasO=!!process.env.OPENAI_API_KEY, hasOR=!!process.env.OPENROUTER_API_KEY;
const primary=process.env.PRIMARY;
const fallbacks=JSON.parse(process.env.FALLBACKS||'[]');
const chromium=process.env.CHROMIUM_BIN||'';

const providers={};
if(hasG) providers.google={ baseUrl:'https://generativelanguage.googleapis.com/v1beta/openai/', models:[{id:'gemini-2.5-flash'}] };
if(hasO) providers.openai={ models:[{id:'gpt-4o-mini'}] };
if(hasOR) providers.openrouter={ apiKey:process.env.OPENROUTER_API_KEY, models:[
  {id:'google/gemini-2.5-flash:free'},{id:'meta-llama/llama-3.3-70b-instruct:free'},{id:'deepseek/deepseek-r1:free'}
]};
providers.pollinations={ baseUrl:'https://text.pollinations.ai/openai/', apiKey:'no-key', models:[{id:'openai-fast'}] };

const imgPrimary=hasOR ? 'openrouter/google/gemini-3.1-flash-image-preview'
                       : hasG ? 'google/gemini-3.1-flash-image-preview' : null;
const imgFallbacks=hasG && imgPrimary!=='google/gemini-3.1-flash-image-preview' ? ['google/gemini-3.1-flash-image-preview'] : [];

const pluginEntries={
  telegram:     {enabled:true},
  duckduckgo:   {enabled:true, config:{webSearch:{region:'us-en',safeSearch:'off'}}},
  'llm-task':   {enabled:true},
  'memory-wiki':{enabled:true},
  'media-tools':{enabled:true},
};
if(chromium) pluginEntries.browser={enabled:true};

const filteredFallbacks=fallbacks.filter(f=>f!==primary);
const agentDefaults={ model:{primary,fallbacks:filteredFallbacks}, models:Object.fromEntries([primary,...fallbacks].map(m=>[m,{}])) };
if(imgPrimary) agentDefaults.imageGenerationModel={primary:imgPrimary,fallbacks:imgFallbacks,timeoutMs:120000};

const config={
  gateway: {mode:'local',auth:{mode:'token',token:process.env.GATEWAY_TOKEN}},
  plugins: {entries:pluginEntries, allow:chromium?['media-tools','browser']:['media-tools']},
  channels:{telegram:{enabled:true,botToken:process.env.TELEGRAM_BOT_TOKEN}},
  agents:  {defaults:agentDefaults},
  models:  {providers},
  tools:   {web:{search:{enabled:true,provider:'duckduckgo',maxResults:8,timeoutSeconds:30},fetch:{enabled:true}}},
  commands:{ownerAllowFrom:['telegram:'+process.env.ADMIN_ID]},
  meta:    {lastTouchedVersion:'2026.6.11'}
};
if(chromium) config.browser={enabled:true,executablePath:chromium,headless:true,noSandbox:true};

fs.mkdirSync(path.dirname(cfg),{recursive:true});
fs.writeFileSync(cfg,JSON.stringify(config,null,2),{mode:0o600});
console.log('[run.sh] Config OK ✓');
"

# ── Install media-tools plugin (force refreshes code every boot) ──────────────
if [ -d "$PLUGIN_DIR" ]; then
  echo "[run.sh] Installing media-tools plugin..."
  openclaw plugins install "$PLUGIN_DIR" --force 2>&1 | grep -E "Installed|Error" | head -3 || true
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 OpenClaw ($PRIMARY) starting..."

# ── Launch ────────────────────────────────────────────────────────────────────
export OPENCLAW_NO_RESPAWN=1
openclaw gateway run 2>&1 | tee -a "$LOG_DIR/openclaw-$(date +%Y-%m-%d).log"
