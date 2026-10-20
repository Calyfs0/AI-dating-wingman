# Kehlo Edge Function prompts

Server-side only. OpenAI keys never ship in the Flutter client.  
Shared safety copy lives in `supabase/functions/_shared/safety.ts` (`SAFETY_RULES`).

Optional: set Edge secret `SAFETY_MODERATION=true` to enable OpenAI Moderations for severe categories (`sexual/minors`, graphic violence). Off by default so normal flirty chat is not over-blocked.

---

## `generate-replies`

**Modes:** screenshot reply · typed message · openers (`mode: "openers"`).

### Shared building blocks

| Constant | Purpose |
|----------|---------|
| `SESSION_RULES` | No cross-request memory; only this payload |
| `LANGUAGE_RULES` | Match latest message language/script (Tamil, Hindi, Hinglish, English, …) |
| `VOICE_RULES` | Casual texting voice; ban therapy/HR tone |
| `EMPATHY_RULES` | Brief human beat; don’t invent reciprocal romance |
| `TONE_RULES` | `natural` vs `playful` must differ |
| `SAFETY_RULES` | Consent, no coercion/minors/harm; soft refuse manipulative asks |

### Screenshot instructions (`SCREENSHOT_INSTRUCTIONS`)

- Role: dating reply companion.
- Layout gate: right/green/blue = USER, left/gray = OTHER; bottom-most bubble is latest.
- If latest is USER → `needs_reply: false` + `latest_speaker: "user"` (no invented follow-ups).
- Else two copy-paste replies; `latest_incoming` must be the OTHER's latest line only.
- Server forces no-reply when `latest_speaker` is `user`, even if the model also emitted replies.

### Openers instructions (`OPENERS_INSTRUCTIONS`)

- Role: first-message companion from a profile screenshot.
- Hooks must be visible; no invented hobbies.
- Two openers (`natural`, `playful`) + `hook` / `why`.

### Text instructions (`TEXT_INSTRUCTIONS`)

- Latest pasted incoming message (+ optional context).
- Same language/voice/tone/safety rules as screenshot path.

### Retries

Up to two quality retries for language mismatch, near-duplicate replies, or overly formal English patterns.

### Streaming

When `stream: true`, SSE `partial` then `done` (or `error`). Same prompts; one non-stream quality retry after the first pass if needed.

---

## `practice-session`

- Role: named persona (`personaName` + `personaStyle`) texting in-character.
- Never coach or admit AI/practice mode mid-scene.
- Ends after ~3–4 user turns with honest, non-hype `feedback` (no scores).
- Includes `SAFETY_RULES` (persona must not encourage harm / non-consent).

---

## `profile-audit`

- Role: Kehlo Profile — score photo/bio vibes, rewrite bio variants, extract opener hook.
- No mean insults; never invent invisible hobbies/photos.
- Includes `SAFETY_RULES` (respectful critique only).

---

## `people-coach`

- **Briefing:** `whatYouKnow`, `goodTopics`, `avoid`, `challenge` from local notes only.
- **Debrief:** one tip + `nextMoves`.
- Casual tone; no invented biography.
- Includes `SAFETY_RULES`.

---

## Legacy (not primary Kehlo path)

`analyze-conversation` / `generate-response` are legacy coach paths. Prefer `generate-replies` for product flows.

---

## Editing prompts

1. Change the Edge Function (or `_shared/safety.ts`).
2. Update this doc.
3. Deploy: `npx supabase functions deploy <name> --no-verify-jwt`.
