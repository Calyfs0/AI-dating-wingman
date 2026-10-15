import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { responsesJson } from "../_shared/openai_responses.ts";

const MAX_IMAGE_CHARS = 7_500_000;
const MAX_MESSAGE_CHARS = 4000;
const MAX_CONTEXT_CHARS = 2000;

function normalizeImageDataUrl(raw: string): string | null {
  const value = raw.trim();
  if (!value) return null;
  if (value.length > MAX_IMAGE_CHARS) return null;
  if (value.startsWith("data:image/")) return value;
  if (/^[A-Za-z0-9+/=\s]+$/.test(value) && value.length > 100) {
    return `data:image/jpeg;base64,${value.replace(/\s/g, "")}`;
  }
  return null;
}

function normalizeReply(value: string): string {
  // Unicode-aware: keep letters from any script (Tamil, Hindi, etc.), not just ASCII \w.
  return value
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, "")
    .replace(/\s+/g, " ")
    .trim();
}

function tooSimilar(a: string, b: string): boolean {
  const na = normalizeReply(a);
  const nb = normalizeReply(b);
  // Keep non-Latin text if punctuation stripping ever empties a string.
  const fa = na || a.trim().toLowerCase();
  const fb = nb || b.trim().toLowerCase();
  if (!fa || !fb) return true;
  if (fa === fb) return true;
  const shorter = fa.length <= fb.length ? fa : fb;
  const longer = fa.length <= fb.length ? fb : fa;
  if (shorter.length >= 24 && longer.includes(shorter)) {
    return shorter.length / longer.length >= 0.85;
  }
  return false;
}

type ScriptFamily =
  | "devanagari"
  | "tamil"
  | "telugu"
  | "kannada"
  | "malayalam"
  | "bengali"
  | "gujarati"
  | "gurmukhi"
  | "arabic"
  | "cjk"
  | "latin"
  | "other";

function detectScript(value: string): ScriptFamily {
  const counts: Record<ScriptFamily, number> = {
    devanagari: 0,
    tamil: 0,
    telugu: 0,
    kannada: 0,
    malayalam: 0,
    bengali: 0,
    gujarati: 0,
    gurmukhi: 0,
    arabic: 0,
    cjk: 0,
    latin: 0,
    other: 0,
  };

  for (const ch of value) {
    const code = ch.codePointAt(0);
    if (code == null) continue;
    if (code >= 0x0900 && code <= 0x097f) counts.devanagari++;
    else if (code >= 0x0b80 && code <= 0x0bff) counts.tamil++;
    else if (code >= 0x0c00 && code <= 0x0c7f) counts.telugu++;
    else if (code >= 0x0c80 && code <= 0x0cff) counts.kannada++;
    else if (code >= 0x0d00 && code <= 0x0d7f) counts.malayalam++;
    else if (code >= 0x0980 && code <= 0x09ff) counts.bengali++;
    else if (code >= 0x0a80 && code <= 0x0aff) counts.gujarati++;
    else if (code >= 0x0a00 && code <= 0x0a7f) counts.gurmukhi++;
    else if (
      (code >= 0x0600 && code <= 0x06ff) ||
      (code >= 0x0750 && code <= 0x077f)
    ) {
      counts.arabic++;
    } else if (
      (code >= 0x4e00 && code <= 0x9fff) ||
      (code >= 0x3040 && code <= 0x30ff) ||
      (code >= 0xac00 && code <= 0xd7af)
    ) {
      counts.cjk++;
    } else if (
      (code >= 0x0041 && code <= 0x005a) ||
      (code >= 0x0061 && code <= 0x007a) ||
      (code >= 0x00c0 && code <= 0x024f)
    ) {
      counts.latin++;
    }
  }

  let best: ScriptFamily = "other";
  let bestCount = 0;
  for (const [script, count] of Object.entries(counts) as Array<
    [ScriptFamily, number]
  >) {
    if (count > bestCount) {
      best = script;
      bestCount = count;
    }
  }
  return bestCount > 0 ? best : "other";
}

/** Romanized Hindi / Hinglish tokens common in Indian texting. */
const HINGLISH_TOKENS = new Set([
  "hai", "hain", "ho", "hu", "hun", "haan", "han", "nahi", "nahin", "naa",
  "kya", "kyun", "kyu", "kaise", "kaisa", "kaisi", "kab", "kahan", "kidhar",
  "tum", "tu", "tera", "teri", "tere", "tumhara", "tumhari", "main", "mein",
  "mera", "meri", "mere", "mujhe", "mujhko", "hum", "ham", "apka", "apki",
  "bhi", "bas", "bahut", "bohot", "bohot", "accha", "achha", "acha", "theek",
  "thik", "yaar", "yar", "bhai", "behen", "dost", "dil", "pyaar", "pyar",
  "ishq", "janu", "jaanu", "baby", "babe", "pls", "plz", "abt", "msg",
  "baat", "baatein", "kar", "karo", "karna", "karke", "raha", "rahi", "rahe",
  "gaya", "gayi", "gaye", "aja", "aaaja", "aaja", "ja", "jaa", "mat",
  "abhi", "kal", "aaj", "parso", "sirf", "sach", "sachme", "sachmein",
  "bhool", "bhul", "maaf", "sorry", "yaad", "miss", "karungi", "karunga",
  "dekho", "dekh", "sun", "suno", "bolo", "bol", "chup", "arey", "arre",
  "oyee", "oye", "wah", "waah", "uff", "hahaha", "hehe", "lol",
  "kitna", "kitni", "itna", "itni", "zyada", "jyada", "kam", "bilkul",
  "pakka", "promise", "yaar", "bro", "sidha", "seedha", "pagal", "idiot",
]);

type LatinVariety = "english" | "hinglish" | "neutral";

function tokenizeLatin(value: string): string[] {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9\s']/g, " ")
    .split(/\s+/)
    .filter((t) => t.length > 1);
}

function hinglishScore(value: string): number {
  const tokens = tokenizeLatin(value);
  if (tokens.length === 0) return 0;
  let hits = 0;
  for (const t of tokens) {
    if (HINGLISH_TOKENS.has(t)) hits++;
  }
  return hits / tokens.length;
}

function detectLatinVariety(value: string): LatinVariety {
  const score = hinglishScore(value);
  if (score >= 0.18) return "hinglish";
  if (score <= 0.04) return "english";
  return "neutral";
}

/** True when any reply drifted away from the source language/script. */
function languageMismatch(
  source: string,
  natural: string,
  playful: string,
): boolean {
  const sourceScript = detectScript(source);
  const replies = [natural, playful];
  const replyScripts = replies.map(detectScript);

  if (sourceScript === "other") {
    const known = replyScripts.filter((s) => s !== "other");
    return known.length >= 2 && known.some((s) => s !== known[0]);
  }

  if (sourceScript === "latin") {
    // Must stay Latin script first.
    if (replyScripts.some((s) => s !== "latin" && s !== "other")) return true;

    // Then separate English vs Hinglish (same script, different language mix).
    const sourceVariety = detectLatinVariety(source);
    if (sourceVariety === "neutral") return false;

    for (const reply of replies) {
      const replyVariety = detectLatinVariety(reply);
      if (replyVariety === "neutral") continue;
      if (replyVariety !== sourceVariety) return true;
    }
    return false;
  }

  // Non-Latin source (Tamil, Devanagari, …): every reply must match that script.
  return replyScripts.some((s) => s !== sourceScript);
}

const FORMAL_ENGLISH_PATTERNS = [
  /i can see that you/i,
  /i understand (that )?you/i,
  /i take that seriously/i,
  /i(?:'d| would) like to/i,
  /i respect your (space|feelings|boundaries)/i,
  /when you(?:'re| are) ready/i,
  /i appreciate you sharing/i,
  /that must be hard/i,
  /i hope this (message )?finds you/i,
  /please (?:do )?not hesitate/i,
  /with all due respect/i,
];

function tooFormal(natural: string, playful: string): boolean {
  return [natural, playful].some((reply) =>
    FORMAL_ENGLISH_PATTERNS.some((re) => re.test(reply))
  );
}

const SESSION_RULES = `Session isolation (critical):
- Treat THIS request as a brand-new chat with no memory of any previous request.
- Use only the screenshot / message / optional context provided in this request.
- Never carry over language, names, tone, or details from any other conversation.`;

const LANGUAGE_RULES = `Language match (critical — applies to natural AND playful equally):
- Detect the language of the latest incoming message, then match it exactly.
- natural and playful MUST BOTH be in that same language and script. No exceptions.
- Tamil (தமிழ்) in → both replies in Tamil script.
- Devanagari Hindi in → both in Devanagari Hindi (not English, not Hinglish).
- Romanized Hinglish in → both in romanized Hinglish (e.g. "arey yaar soft ho ja", "sach? dil se?").
  Do NOT rewrite Hinglish into polished English.
- English in → both in casual English (never Tamil/Hindi script, never forced Hinglish).
- Same rule for any other language/script the message uses.
- Mixed chat: follow the latest incoming message only.
- Optional context must not change the reply language.
- Also return "language" in JSON: one of english, hinglish, hindi, tamil, other.`;

const VOICE_RULES = `Voice — sound like a real text, never an email or therapist:
- Write the way people actually text in the matched language: short, casual, contractions where natural.
- Prefer 1–2 short lines. Fragments are fine. Avoid polished multi-clause sentences.
- Empathy = a brief human beat in that language — NOT clinical validation.
- English examples below are style hints only; if the chat is Hindi/Hinglish, write Hindi/Hinglish equivalents — never paste English:
  "damn that sucks" / "fair" / "okay I hear you".
- FORBIDDEN (any language): therapy/HR/coaching phrasing, essay apologies, formal openers.
- Light slang / soft emoji only if it fits — never emoji spam.
- Sound like someone they already know texting back.`;

const EMPATHY_RULES = `Empathy first (required for BOTH replies) — keep it casual:
- Notice what they shared (hurt, stress, affection, excitement, etc.) and nod to it briefly.
- Then add the tone flavor. Don't skip the human beat on heavy messages.
- Empathy without inventing how the USER feels or mirroring "I love you" / "I feel the same"
  unless the USER already clearly said that.
- You can care and acknowledge without claiming reciprocal romantic intensity.`;

const TONE_RULES = `Tone requirements (must feel meaningfully different; BOTH stay casual + empathetic + same language):
- natural: Easy, warm, low-effort text — like a chill friend.
- playful: Soft tease AFTER a small warm beat — never try-hard, never punching their feelings.`;

const SCREENSHOT_INSTRUCTIONS = `You are Gotchu, a dating reply companion that texts like a real person.

You receive ONE screenshot of a messaging conversation.
Your job:
1. Read the visible chat text carefully.
2. Decide which bubbles belong to the USER (person seeking a reply) vs the OTHER person.
   Prefer: right-aligned / outgoing / green (WhatsApp) / blue (iMessage) bubbles = USER.
   Prefer: left-aligned / incoming / gray-white bubbles = OTHER.
3. Find the chronologically latest message in the screenshot.
4. If that latest message is from the USER (they already replied, said goodnight, thanks, ok, etc.):
   Do NOT invent replies. Return needs_reply:false with a short warm title + message.
   Examples: closed with goodnight, already answered, ball is in their court.
5. Only if the latest message is from the OTHER person: write exactly two distinct replies.

${SESSION_RULES}

${LANGUAGE_RULES}

${VOICE_RULES}

${EMPATHY_RULES}

${TONE_RULES}

Hard rules:
- Never invent conversation details that are not visible.
- Avoid cheesy pickup lines, emoji spam, cold/detached one-liners, and robotic/formal phrasing.
- Keep each reply concise (usually 1–2 short sentences), copy-paste ready.
- The two replies must not be paraphrases of each other.
- If the image is not a readable chat, return readable:false with a short friendly error.

Return JSON only — one of:
{
  "readable": true,
  "needs_reply": false,
  "title": "You're all set",
  "message": "Short sweet note that they already sent the last text / nothing to reply to.",
  "latest_outgoing": "..."
}
or {
  "readable": true,
  "needs_reply": true,
  "latest_incoming": "...",
  "language": "english|hinglish|hindi|tamil|other",
  "replies": { "natural": "...", "playful": "..." }
}
or { "readable": false, "error": "..." }`;

const OPENERS_INSTRUCTIONS = `You are Gotchu, a dating opener companion that texts like a real person.

You receive ONE screenshot of someone's dating profile (Hinge, Bumble, Tinder, etc.).
Your job:
1. Read visible name, prompts, bio, interests, and photo captions carefully.
2. Pick real hooks from what is visible — never invent hobbies or details.
3. Write exactly two distinct first messages the USER can send this person.

${SESSION_RULES}

Language:
- Match the dominant language/script of the profile text (bio/prompts).
- If the profile is mostly English, write English openers.
- Hindi/Tamil/Hinglish profiles → openers in that same language/script.
- natural and playful MUST BOTH be in that same language.

Voice — sound like a real first text, never a pickup-line generator:
- Short, casual, specific to a visible hook.
- Prefer 1–2 short lines. Reference something concrete from the profile.
- Avoid generic "hey beautiful", emoji spam, and try-hard rizz.
- Empathy/warmth first when a prompt is personal; playful tease only after a human beat.

Tone requirements (must feel meaningfully different):
- natural: Easy, warm first message grounded in a real hook.
- playful: Soft tease tied to a specific prompt — never mean.

Hard rules:
- Never invent profile details that are not visible.
- The two openers must not be paraphrases of each other.
- If the image is not a readable dating profile, return readable:false with a short friendly error.

Return JSON only:
{
  "readable": true,
  "latest_incoming": "short summary of the main hook you used",
  "language": "english|hinglish|hindi|tamil|other",
  "replies": { "natural": "...", "playful": "..." }
}
or { "readable": false, "error": "..." }`;

const TEXT_INSTRUCTIONS = `You are Gotchu, a dating reply companion that texts like a real person.

The user pastes the latest message they received (from the other person), with optional context.
Your job:
1. Treat "message" as the latest incoming message to reply to.
2. Use optional context only if provided — do not invent missing details.
3. Write exactly two distinct, ready-to-send reply messages.

${SESSION_RULES}

${LANGUAGE_RULES}

${VOICE_RULES}

${EMPATHY_RULES}

${TONE_RULES}

Hard rules:
- Never invent conversation history that was not provided.
- Avoid cheesy pickup lines, emoji spam, cold/detached one-liners, and robotic/formal phrasing.
- Keep each reply concise (usually 1–2 short sentences), copy-paste ready.
- The two replies must not be paraphrases of each other.
- If the message is empty or unusable, return readable:false with a short friendly error.

Return JSON only:
{
  "readable": true,
  "latest_incoming": "...",
  "language": "english|hinglish|hindi|tamil|other",
  "replies": { "natural": "...", "playful": "..." }
}
or { "readable": false, "error": "..." }`;

function validateReplies(
  ai: Record<string, unknown>,
  languageSource: string,
  options: { skipLanguageCheck?: boolean } = {},
) {
  if (ai.readable === false) {
    const message = String(
      ai.error ??
        "Couldn't read this conversation. Try a clearer screenshot of the chat.",
    );
    return { ok: false as const, status: 422, body: { error: message, code: "unreadable" } };
  }

  // User already sent the latest message — nothing to suggest.
  if (ai.needs_reply === false) {
    const title = String(ai.title ?? "").trim() || "You're all set";
    const message = String(ai.message ?? "").trim() ||
      "You already sent the last message — nothing to reply to right now. Let them come back to you.";
    const latestOutgoing = String(ai.latest_outgoing ?? "").trim();
    return {
      ok: true as const,
      body: {
        readable: true,
        needsReply: false,
        title,
        message,
        latestOutgoing: latestOutgoing || null,
      },
    };
  }

  const repliesRaw = ai.replies;
  if (!repliesRaw || typeof repliesRaw !== "object") {
    return {
      ok: false as const,
      status: 502,
      body: { error: "Couldn't generate replies. Please try again.", code: "invalid" },
    };
  }

  const replies = repliesRaw as Record<string, unknown>;
  const natural = String(replies.natural ?? "").trim();
  const playful = String(replies.playful ?? "").trim();

  if (!natural || !playful) {
    return {
      ok: false as const,
      status: 502,
      body: { error: "Couldn't generate replies. Please try again.", code: "invalid" },
    };
  }

  if (tooSimilar(natural, playful)) {
    return {
      ok: false as const,
      status: 502,
      body: {
        error: "Couldn't generate distinct replies. Please try again.",
        code: "invalid",
      },
      distinctMismatch: true as const,
    };
  }

  const latestIncoming = String(ai.latest_incoming ?? "").trim() ||
    languageSource.trim() ||
    null;
  const mismatchSource = languageSource.trim() || latestIncoming || "";
  if (
    !options.skipLanguageCheck &&
    languageMismatch(mismatchSource, natural, playful)
  ) {
    return {
      ok: false as const,
      status: 502,
      body: {
        error: "Couldn't match reply language. Please try again.",
        code: "language",
      },
      languageMismatch: true as const,
    };
  }

  if (tooFormal(natural, playful)) {
    return {
      ok: false as const,
      status: 502,
      body: {
        error: "Couldn't generate casual replies. Please try again.",
        code: "invalid",
      },
      formalMismatch: true as const,
    };
  }

  return {
    ok: true as const,
    body: {
      readable: true,
      latestIncoming,
      replies: { natural, playful },
    },
  };
}

const LANGUAGE_RETRY_HINT =
  "RETRY: At least one reply was in the wrong language/script. " +
  "Rewrite natural AND playful — both — in the exact same language/script as the latest incoming message. " +
  "Tamil→Tamil, Hindi→Hindi, English→English, etc. Do not switch any reply to English.";

const DISTINCT_RETRY_HINT =
  "RETRY: Your two replies were too similar. Rewrite natural and playful so each feels clearly different " +
  "in wording and vibe, still in the same language/script as the latest incoming message.";

const FORMAL_RETRY_HINT =
  "RETRY: Replies sounded too formal/therapy-like. Rewrite both as casual texts a real person would send. " +
  "No 'I can see that', 'I respect your space', 'I'd like to', or essay phrasing.";

const HINGLISH_RETRY_HINT =
  "RETRY: The incoming message is Hinglish (romanized Hindi mix). Both replies must be Hinglish too — " +
  "not polished English. Example vibe: 'arey soft hoja 😅' / 'sach? dil se bol raha?'.";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization", code: "auth" }, 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();
    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized", code: "auth" }, 401);
    }

    const body = await req.json();
    const image = normalizeImageDataUrl(String(body.image ?? ""));
    const mode = String(body.mode ?? "").trim().toLowerCase();
    const isOpeners = mode === "openers";
    const message = String(body.message ?? "").trim().slice(0, MAX_MESSAGE_CHARS);
    // Drop optional context when its script disagrees with the message —
    // prevents a leftover context language from steering a new chat.
    const rawContext = String(body.context ?? "").trim().slice(0, MAX_CONTEXT_CHARS);
    const context = (() => {
      if (!rawContext || !message) return "";
      const msgScript = detectScript(message);
      const ctxScript = detectScript(rawContext);
      if (msgScript === "other" || ctxScript === "other") return rawContext;
      if (msgScript === "latin") {
        return ctxScript === "latin" ? rawContext : "";
      }
      return ctxScript === msgScript ? rawContext : "";
    })();

    let ai: Record<string, unknown>;
    let languageSource = message;
    let baseUserText: string;
    let instructions: string;
    let imageDataUrl: string | undefined;
    let skipLanguageCheck = false;

    if (isOpeners) {
      if (!image) {
        return jsonResponse(
          {
            error: "Choose a profile screenshot to continue.",
            code: "validation",
          },
          400,
        );
      }
      // Image processed in-memory only — never stored.
      instructions = OPENERS_INSTRUCTIONS;
      imageDataUrl = image;
      skipLanguageCheck = true;
      baseUserText =
        "This is a brand-new isolated request — ignore any notion of prior chats. " +
        "Analyze this dating profile screenshot. Extract real hooks from bio/prompts/interests. " +
        "Write two distinct casual first messages (natural, playful) in the profile's language. " +
        "Never invent details. Return the JSON object from your instructions.";
    } else if (image) {
      // Image processed in-memory only — never stored.
      instructions = SCREENSHOT_INSTRUCTIONS;
      imageDataUrl = image;
      baseUserText = message
        ? "This is a brand-new isolated request — ignore any notion of prior chats. " +
          "Analyze this chat screenshot for conversation context, but treat this as the latest incoming message to reply to:\n" +
          `${message}\n\n` +
          "Match language/script for BOTH replies (natural and playful) to that latest message " +
          "(Tamil→Tamil, Hindi→Hindi, Hinglish→Hinglish, English→English, or any other language as written). " +
          "Write casual texting-style replies: warm/human, never formal or therapy-speak. Do not invent the user's feelings. " +
          "Return the JSON object from your instructions. Set latest_incoming to the provided latest message."
        : "This is a brand-new isolated request — ignore any notion of prior chats. " +
          "Analyze this chat screenshot. Focus on the latest incoming message and visible prior context. " +
          "Match language/script for BOTH replies (natural and playful) " +
          "(Tamil→Tamil, Hindi→Hindi, Hinglish→Hinglish, English→English, or any other language as written). " +
          "Write casual texting-style replies: warm/human, never formal or therapy-speak. Do not invent the user's feelings. " +
          "Return the JSON object from your instructions.";
    } else if (message) {
      instructions = TEXT_INSTRUCTIONS;
      baseUserText = context
        ? `This is a brand-new isolated request — ignore any notion of prior chats.\n\nLatest incoming message:\n${message}\n\nOptional context from the user:\n${context}\n\nMatch language/script for BOTH replies (natural and playful) (Tamil→Tamil, Hindi→Hindi, English→English, or any other language as written). Write casual texting-style replies: warm/human, never formal or therapy-speak. Do not invent the user's feelings. Return the JSON object from your instructions.`
        : `This is a brand-new isolated request — ignore any notion of prior chats.\n\nLatest incoming message:\n${message}\n\nMatch language/script for BOTH replies (natural and playful) (Tamil→Tamil, Hindi→Hindi, English→English, or any other language as written). Write casual texting-style replies: warm/human, never formal or therapy-speak. Do not invent the user's feelings. Return the JSON object from your instructions.`;
    } else {
      return jsonResponse(
        {
          error: "Choose a screenshot or enter the message you received.",
          code: "validation",
        },
        400,
      );
    }

    ai = await responsesJson({
      instructions,
      userText: baseUserText,
      imageDataUrl,
      model: "gpt-4o-mini",
      temperature: 0.85,
    });

    // Prefer model-extracted latest line for screenshot language checks.
    languageSource = message ||
      String(ai.latest_incoming ?? "").trim();

    const validateOpts = { skipLanguageCheck };
    let validated = validateReplies(ai, languageSource, validateOpts);
    for (let attempt = 0; attempt < 2; attempt++) {
      if (validated.ok) break;
      const distinctFail =
        "distinctMismatch" in validated && validated.distinctMismatch;
      const languageFail =
        "languageMismatch" in validated && validated.languageMismatch;
      const formalFail =
        "formalMismatch" in validated && validated.formalMismatch;
      if (!distinctFail && !languageFail && !formalFail) break;

      const hints: string[] = [];
      if (languageFail) {
        const sourceVariety = detectScript(languageSource) === "latin"
          ? detectLatinVariety(languageSource)
          : "other";
        hints.push(
          sourceVariety === "hinglish"
            ? HINGLISH_RETRY_HINT
            : LANGUAGE_RETRY_HINT,
        );
      }
      if (distinctFail) hints.push(DISTINCT_RETRY_HINT);
      if (formalFail) hints.push(FORMAL_RETRY_HINT);

      ai = await responsesJson({
        instructions,
        userText: `${baseUserText}\n\n${hints.join("\n")}`,
        imageDataUrl,
        model: "gpt-4o-mini",
        temperature: 0.9,
      });
      languageSource = message ||
        String(ai.latest_incoming ?? "").trim() ||
        languageSource;
      validated = validateReplies(ai, languageSource, validateOpts);
    }

    if (!validated.ok) {
      return jsonResponse(validated.body, validated.status);
    }
    // Prefer the user's corrected latest line when provided with a screenshot.
    if (image && message && validated.body && typeof validated.body === "object") {
      (validated.body as Record<string, unknown>).latestIncoming = message;
    }
    return jsonResponse(validated.body);
  } catch (error) {
    const message = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`generate-replies: ${message}`);
    return jsonResponse(
      {
        error: "Something went wrong generating replies. Please try again.",
        code: "server",
      },
      500,
    );
  }
});
