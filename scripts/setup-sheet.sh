#!/usr/bin/env bash
# One-time: creates the Bookings, Inquiries, Reservations, Leads and Stays tabs in GOOGLE_SHEET_ID with header rows,
# using the service account in secrets/. Safe to re-run (only adds what is missing; rewrites headers).
#   ./scripts/setup-sheet.sh --reset   also deletes all data rows (clean sheet before a demo)
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1

docker compose exec -T -e RESET="${1:-}" n8n node -e '
const crypto = require("crypto"), fs = require("fs");
const sa = JSON.parse(fs.readFileSync("/secrets/google-service-account.json", "utf8"));
const id = process.env.GOOGLE_SHEET_ID;
const TABS = {
  Bookings:  ["id","created_at","name","phone","email","date","time","status","reminder_sent","language","summary"],
  Inquiries: ["id","created_at","intent","urgency","name","phone","email","language","message","summary","action_taken"],
  // Website chatbot requests (workflow 5); clinic chatbot bookings go to Bookings above
  Reservations: ["id","created_at","name","phone","date","time","guests","allergies","occasion","status","language","summary"],
  Leads:     ["id","created_at","name","phone","company","need","budget","call_date","call_time","score","status","summary"],
  Stays:     ["id","created_at","name","phone","check_in","check_out","nights","guests","room","extras","status","language","summary"],
};
const b64 = o => Buffer.from(typeof o === "string" ? o : JSON.stringify(o)).toString("base64url");
(async () => {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = b64({ alg: "RS256", typ: "JWT" }) + "." + b64({ iss: sa.client_email, scope: "https://www.googleapis.com/auth/spreadsheets",
    aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 600 });
  const jwt = unsigned + "." + crypto.sign("RSA-SHA256", Buffer.from(unsigned), sa.private_key).toString("base64url");
  const tok = await (await fetch("https://oauth2.googleapis.com/token", { method: "POST",
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt }) })).json();
  if (!tok.access_token) throw new Error("Google auth failed: " + JSON.stringify(tok));
  const api = async (path, method = "GET", body) => {
    const r = await fetch("https://sheets.googleapis.com/v4/spreadsheets/" + id + path, { method,
      headers: { Authorization: "Bearer " + tok.access_token, "Content-Type": "application/json" }, body: body && JSON.stringify(body) });
    const j = await r.json(); if (!r.ok) throw new Error(j.error?.message || r.status); return j;
  };
  const meta = await api("?fields=sheets.properties");
  const have = meta.sheets.map(s => s.properties);
  const requests = [];
  for (const name of Object.keys(TABS)) {
    if (have.some(p => p.title === name)) continue;
    const blank = have.find(p => /^(Sheet1|ورقة1)$/.test(p.title));
    if (blank) { requests.push({ updateSheetProperties: { properties: { sheetId: blank.sheetId, title: name }, fields: "title" } }); blank.title = name; }
    else requests.push({ addSheet: { properties: { title: name } } });
  }
  if (requests.length) await api(":batchUpdate", "POST", { requests });
  const sheets = (await api("?fields=sheets.properties")).sheets.map(s => s.properties);
  const fmt = [];
  for (const [name, cols] of Object.entries(TABS)) {
    if (process.env.RESET === "--reset") { await api("/values/" + name + "!A2:Z:clear", "POST", {}); console.log("cleared " + name); }
    await api("/values/" + name + "!A1?valueInputOption=RAW", "PUT", { values: [cols] });
    const sheetId = sheets.find(p => p.title === name).sheetId;
    fmt.push({ updateSheetProperties: { properties: { sheetId, gridProperties: { frozenRowCount: 1 } }, fields: "gridProperties.frozenRowCount" } },
             { repeatCell: { range: { sheetId, startRowIndex: 0, endRowIndex: 1 }, cell: { userEnteredFormat: { textFormat: { bold: true } } }, fields: "userEnteredFormat.textFormat.bold" } });
    console.log("ok  " + name + ": " + cols.join(", "));
  }
  await api(":batchUpdate", "POST", { requests: fmt });
})().catch(e => { console.error("ERROR: " + e.message); process.exit(1); });
'
