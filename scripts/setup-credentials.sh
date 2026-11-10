#!/usr/bin/env bash
# Creates/updates all n8n credentials from .env (+ secrets/google-service-account.json).
# Runs inside the container: secrets are read from the container env, written to a temp
# file, imported (n8n encrypts them with N8N_ENCRYPTION_KEY) and the temp file is deleted.
# Credentials whose values are still empty are skipped.
# Re-run after changing .env:  docker compose up -d && ./scripts/setup-credentials.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1   # Git Bash on Windows: don't rewrite /tmp paths

docker compose exec -T n8n sh -c 'node -e "
const fs = require(\"fs\"), e = process.env, out = [];
const add = (id, name, type, data, ok) => ok ? out.push({ id, name, type, data }) : console.log(\"skip  \" + name + \" (not configured yet)\");
add(\"clinicTelegram01\", \"Clinic Telegram Bot\", \"telegramApi\", { accessToken: e.TELEGRAM_BOT_TOKEN }, e.TELEGRAM_BOT_TOKEN);
add(\"clinicGemini0001\", \"Clinic Google Gemini\", \"googlePalmApi\", { host: \"https://generativelanguage.googleapis.com\", apiKey: e.GEMINI_API_KEY }, e.GEMINI_API_KEY);
add(\"clinicSmtpGmail1\", \"Clinic Gmail SMTP\", \"smtp\", { user: e.SMTP_USER, password: e.SMTP_PASS, host: \"smtp.gmail.com\", port: 465, secure: true }, e.SMTP_USER && e.SMTP_PASS);
add(\"clinicWebhookAu1\", \"Clinic Webhook Secret\", \"httpHeaderAuth\", { name: \"X-Clinic-Secret\", value: e.WEBHOOK_SECRET }, e.WEBHOOK_SECRET);
const sa = \"/secrets/google-service-account.json\";
const j = fs.existsSync(sa) ? JSON.parse(fs.readFileSync(sa, \"utf8\")) : null;
add(\"clinicGoogleSa01\", \"Clinic Google Service Account\", \"googleApi\", j && { email: j.client_email, privateKey: j.private_key }, j);
fs.writeFileSync(\"/tmp/creds.json\", JSON.stringify(out));
console.log(\"import \" + out.map(c => c.name).join(\", \"));
" && n8n import:credentials --input=/tmp/creds.json; rc=$?; rm -f /tmp/creds.json; exit $rc'
