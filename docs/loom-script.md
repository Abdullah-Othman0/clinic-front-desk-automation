# Loom script: Clinic Front Desk Automation (90 seconds)

**Before recording**
- `./scripts/setup-sheet.sh --reset` for a clean sheet.
- Open 4 tabs: n8n intake workflow, the Google Sheet, Telegram (desktop app), Gmail.
- Have a terminal ready with the three curl commands below, or use the form.
- Make it look good: zoom the browser to 110%, use a dark Telegram theme, close all other tabs.

---

### 0:00–0:12 · The problem (camera on, workflow canvas behind you)
> "A dental clinic's front desk loses hours every day answering the same messages: prices, opening hours, 'can I book tomorrow?'. Bookings get lost and patients forget appointments. I built an AI front desk that handles all of this automatically, in Arabic and English."

### 0:12–0:25 · The system at a glance (pan across the n8n canvas)
> "Messages come in from the website form or a chatbot. Google Gemini reads each one and works out what the patient wants and how urgent it is. Then n8n books, answers or escalates. Every section is labelled, so the clinic can see exactly what happens."

### 0:25–0:55 · Live demo: 3 messages
1. **English booking.** Send *"Hi, I'd like a cleaning tomorrow at 5 pm"*.
   > "A booking. It understood 'tomorrow' as a real date…" Switch to the **sheet**: the new row appears with status *Pending*.
2. **Arabic emergency.** Send *"ضرسي بيوجعني جداً ووشي وارم، محتاج حد يشوفني النهاردة"*.
   > "An Arabic message about severe pain…" Switch to **Telegram**: 🚨 URGENT alert. "The team knows within seconds."
3. **Price question.** Send *"How much is teeth whitening?"*.
   > "A question, answered only from the clinic's own price list, with no made-up answers." Show the JSON reply or the email.

### 0:55–1:10 · Sheet + Telegram + email
- **Gmail:** open the confirmation email. Then open an Arabic one and point out the right-to-left layout.
  > "Every patient gets a reply in their own language."
- **Sheet:** change Sarah's status to *Confirmed*.
  > "Staff confirm with one click. The day before, the patient gets a reminder automatically, and that's fewer no-shows."
- **Telegram:** scroll to the daily summary.
  > "And every evening the clinic gets a summary of the day and tomorrow's schedule."

### 1:10–1:20 · Error alert
- Temporarily break something, e.g. rename the "Bookings" tab, then send a booking. Show the Telegram ⚠️ alert with the failed node and execution link.
  > "If anything ever fails, I get an alert with the exact step and a link to fix it. Nothing fails silently."
- Rename the tab back.

### 1:20–1:30 · Close (camera on)
> "A secured webhook, validated AI output, retries, error alerts and no secrets in code. It's built to run for a real clinic. It works the same for any business that drowns in repetitive messages. If that's you, send me a message and let's automate your front desk."
