# OpenClaw AI Telegram Bot 🤖
## دليل التثبيت الكامل — fps.ms / أي Linux VPS

---

## 📋 المتطلبات

| المطلب | الحد الأدنى | ملاحظة |
|--------|------------|--------|
| نظام التشغيل | Ubuntu 20.04+ / Debian 11+ | أو CentOS Stream 8+ |
| RAM | 512 MB | يُفضَّل 1 GB |
| مساحة | 2 GB | بما فيها Chromium (~500MB) |
| Node.js | v22+ | يُثبَّت تلقائياً |
| Python | 3.8+ | لـ yt-dlp |

---

## 🔑 المفاتيح المطلوبة

### مطلوب (واحد على الأقل):
| المفتاح | من أين | مجاني؟ |
|---------|--------|--------|
| `TELEGRAM_BOT_TOKEN` | [@BotFather](https://t.me/BotFather) | ✅ مجاني |
| `GOOGLE_API_KEY` | [aistudio.google.com](https://aistudio.google.com) | ✅ مجاني |
| `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com) | 💳 مدفوع |
| `OPENROUTER_API_KEY` | [openrouter.ai](https://openrouter.ai) | ✅ نماذج مجانية |

---

## 🚀 التثبيت السريع (5 دقائق)

### الخطوة 1 — رفع الملفات للسيرفر
```bash
# من جهازك المحلي
scp -r openclaw-bot/ user@YOUR_SERVER_IP:~/openclaw-bot/

# أو عبر Git
git clone <your-repo> ~/openclaw-bot
cd ~/openclaw-bot
```

### الخطوة 2 — تشغيل سكريبت الإعداد
```bash
cd ~/openclaw-bot
chmod +x setup.sh
bash setup.sh
```

سيقوم السكريبت تلقائياً بـ:
- تثبيت Node.js 22
- تثبيت openclaw
- تثبيت yt-dlp
- تثبيت مكتبات Chromium
- إنشاء ملف `.env`
- إعداد خدمة systemd

### الخطوة 3 — إضافة المفاتيح
```bash
nano ~/openclaw-bot/.env
```

```env
TELEGRAM_BOT_TOKEN=7123456789:AAF...your_token_here
GOOGLE_API_KEY=AIzaSy...your_key_here
OPENROUTER_API_KEY=sk-or-...your_key_here
ADMIN_TELEGRAM_ID=123456789
```

### الخطوة 4 — إضافة الكوكيز (اختياري لكن مُوصى به)

الكوكيز تحسّن جودة البحث في يوتيوب وتُتيح المحتوى المقيّد جغرافياً:

```bash
mkdir -p ~/openclaw-bot/cookies/
# انسخ كوكيز يوتيوب (صيغة Netscape)
cp youtube_cookies.txt ~/openclaw-bot/cookies/youtube.txt
# انسخ كوكيز سبوتيفاي
cp spotify_cookies.txt ~/openclaw-bot/cookies/spotify.txt
```

لاستخراج الكوكيز من المتصفح، استخدم امتداد [Get cookies.txt LOCALLY](https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc).

### الخطوة 5 — تشغيل البوت
```bash
# تشغيل مباشر للاختبار
source ~/openclaw-bot/.env && bash ~/openclaw-bot/run.sh

# أو عبر systemd (مُوصى به — يعمل 24/7 ويُعيد التشغيل تلقائياً)
systemctl --user enable --now openclaw-bot
```

---

## 🔧 هيكل الملفات

```
openclaw-bot/
├── run.sh                    # 🚀 السكريبت الرئيسي
├── setup.sh                  # ⚙️  إعداد السيرفر
├── .env                      # 🔑 المفاتيح السرية (أنشئه بنفسك)
├── README.md                 # 📖 هذا الدليل
├── cookies/                  # 🍪 كوكيز المتصفح (اختياري)
│   ├── youtube.txt
│   └── spotify.txt
└── plugins/
    └── media-tools/          # 🎵 بلجن الوسائط
        ├── index.js          # الكود الرئيسي
        ├── openclaw.plugin.json
        └── package.json
```

---

## 🛠️ الأدوات المتاحة

| الأداة | الوظيفة | مطلوب |
|--------|---------|--------|
| `youtube_search` | البحث في يوتيوب | yt-dlp |
| `youtube_info` | معلومات فيديو | yt-dlp |
| `youtube_download_audio` | تحميل صوت MP3 | yt-dlp |
| `spotify_search` | البحث عن موسيقى | yt-dlp |
| `spotify_info` | معلومات أغنية | yt-dlp |
| `generate_image` | توليد صور مجاني | لا شيء (Pollinations) |
| `web_search` | البحث في الويب | لا شيء (DuckDuckGo) |
| `web_fetch` | قراءة صفحات ويب | لا شيء |
| `browser` | متصفح كامل | Chromium |
| `llm-task` | مهام AI متقدمة | مفتاح AI |
| `memory-wiki` | ذاكرة دائمة | لا شيء |
| `image_generate` | توليد صور (API) | OpenRouter/Google |

---

## 🔁 إدارة البوت

```bash
# عرض حالة البوت
systemctl --user status openclaw-bot

# إيقاف البوت
systemctl --user stop openclaw-bot

# إعادة التشغيل
systemctl --user restart openclaw-bot

# عرض السجلات المباشرة
journalctl --user -u openclaw-bot -f

# أو قراءة ملف السجل مباشرة
tail -100 ~/.openclaw/logs/openclaw-$(date +%Y-%m-%d).log
```

---

## 🐞 حل المشاكل

### البوت لا يبدأ
```bash
# تحقق من وجود المفاتيح
echo $TELEGRAM_BOT_TOKEN
echo $GOOGLE_API_KEY

# شغّل يدوياً لرؤية الأخطاء
source .env && bash run.sh
```

### web_search لا تعمل
```bash
# تحقق من الإعدادات
openclaw config get tools.web.search.provider
# يجب أن يُظهر: duckduckgo
```

### browser لا يعمل
```bash
# تحقق من Chromium
ls ~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome

# إعادة تثبيت Chromium
cd $(node -e "try{console.log(require.resolve('openclaw').replace('/dist/index.js','')+'/node_modules/playwright-core')}catch{}")
node cli.js install chromium
```

### image_generate تُظهر billing error
هذا طبيعي — استخدم `generate_image` بدلاً منها:
```
اطلب من البوت: "استخدم generate_image لتوليد صورة لـ..."
```

### yt-dlp لا تعمل
```bash
# تحديث yt-dlp
pip3 install -U yt-dlp

# اختبار
yt-dlp --flat-playlist --print "%(title)s" "ytsearch1:test"
```

---

## 🔄 التحديث

```bash
cd ~/openclaw-bot
# حدّث openclaw
npm update -g openclaw

# حدّث yt-dlp
pip3 install -U yt-dlp

# أعد تشغيل البوت
systemctl --user restart openclaw-bot
```

---

## 📞 معلومات البوت

- **اسم البوت**: @H7amzobot
- **النموذج الأساسي**: Google Gemini 2.5 Flash
- **البدائل**: OpenAI GPT-4o Mini → OpenRouter → Pollinations AI

---

## ⚡ fps.ms خطوات إضافية

في لوحة تحكم fps.ms:
1. تأكد من تشغيل المنفذ الخارجي (لا حاجة له — البوت لا يحتاج منفذاً)
2. في إعدادات الـ Firewall: لا تغييرات مطلوبة
3. لتشغيل البوت عند إعادة التشغيل: استخدم `systemctl --user enable openclaw-bot`

للتأكد من تشغيل خدمات المستخدم عند تسجيل الخروج:
```bash
sudo loginctl enable-linger $(whoami)
```
