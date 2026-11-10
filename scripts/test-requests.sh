#!/usr/bin/env bash
# Sends realistic patient messages (Arabic + English) to the intake webhook.
# Usage: ./scripts/test-requests.sh          (all samples)
#        ./scripts/test-requests.sh 4        (only sample 4)
# Patient emails go to TEST_EMAIL (default: SMTP_USER from .env) so you can see them.
set -uo pipefail
cd "$(dirname "$0")/.."
env_get() { grep -E "^$1=" .env | cut -d= -f2-; }

URL="http://127.0.0.1:$(env_get N8N_PORT)/webhook/clinic-intake"
SECRET="$(env_get WEBHOOK_SECRET)"
EMAIL="${TEST_EMAIL:-$(env_get SMTP_USER)}"
ONLY="${1:-}"
n=0

send() { # send "<label>" '<raw body>' [secret]
  n=$((n + 1))
  [ -n "$ONLY" ] && [ "$ONLY" != "$n" ] && return
  echo "── $n. $1"
  # body goes through stdin: on Windows, command-line args would mangle Arabic text
  printf '%s' "$2" | curl -s -m 90 -w '  -> HTTP %{http_code}\n' -X POST "$URL" \
    -H "Content-Type: application/json" -H "X-Clinic-Secret: ${3-$SECRET}" --data-binary @-
  sleep "${DELAY:-6}"   # stay under the Gemini free-tier rate limit
}
json() { # json name phone email message  -> JSON body (sample texts contain no quotes or backslashes)
  printf '{"name":"%s","phone":"%s","email":"%s","message":"%s"}' "$@"
}

send "EN complete booking" "$(json "Sarah Ahmed" "+201001112233" "$EMAIL" \
  "Hi, I'd like to book a teeth cleaning appointment tomorrow at 5 pm please.")"
send "AR complete booking" "$(json "محمد علي" "01012345678" "$EMAIL" \
  "مساء الخير، عايز أحجز كشف يوم الأحد الجاي الساعة 7 مساءً لو سمحت")"
send "AR booking missing date" "$(json "منى حسن" "01198765432" "$EMAIL" \
  "السلام عليكم، عايزة أحجز ميعاد تنظيف أسنان لو سمحت")"
send "EN FAQ question" "$(json "James Miller" "" "$EMAIL" \
  "Are you open on Saturdays, and how much does teeth whitening cost?")"
send "AR question not in FAQ" "$(json "ريم" "01055554444" "$EMAIL" \
  "هل عندكم دكتورة ست متخصصة في تقويم الأسنان؟ وهل بتعملوا تخدير كلي للأطفال؟")"
send "EN angry complaint" "$(json "Karim Youssef" "01222223333" "$EMAIL" \
  "This is unacceptable. I waited 2 hours yesterday past my appointment time and then I was charged twice on my card. I want this fixed now.")"
send "AR urgent pain (chatbot, no email)" "$(json "أحمد سمير" "01033332222" "" \
  "ضرسي بيوجعني جداً من امبارح ووشي وارم ومش قادر أنام، محتاج حد يشوفني النهاردة ضروري")"
send "Spam" "$(json "SEO Expert" "" "" \
  "Boost your clinic's Instagram! Buy 10,000 followers for only \$9.99 👉 bit.ly/cheap-followers")"
send "Malformed body (broken JSON)" '{"name": "Broken", "message": '
send "Missing message field" '{"name": "No Message", "phone": "0100"}'
send "Wrong secret header" "$(json "Intruder" "" "" "hello")" "wrong-secret"
