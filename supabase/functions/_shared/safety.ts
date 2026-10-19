/**
 * Shared safety guardrails for Gotchu Edge Functions.
 * Keep flirty/friendly adult dating OK; block clear harm.
 */

/** Inject into system / instructions prompts (all AI surfaces). */
export const SAFETY_RULES = `Safety & consent (critical — stay natural, never preachy):
- Help with respectful, consensual dating chat only.
- Refuse: non-consensual pressure, stalking/harassment, revenge porn, under-18 sexual content, scams, or clear intent to harm.
- If asked for manipulative / coercive / "negging" tactics, soft-refuse and offer a kinder alternative in the same casual voice — do not lecture or moralize.
- Flirty, romantic, adult content between consenting adults is OK.
- Never roleplay as a minor or invent underage characters.
- Do not invent consent or feelings the other person did not express.`;

/** Obvious high-risk patterns — heuristic only; prompts still carry soft refusals. */
const BLOCK_PATTERNS: Array<{ re: RegExp; reason: string }> = [
  {
    re: /\b(csam|child\s*porn|under[\s-]*(?:1[0-7]|age)|rape\s*her|rape\s*him|drug\s*(?:them|her|him)|roofie|revenge\s*porn)\b/i,
    reason: "That request isn't something Gotchu can help with.",
  },
  {
    re: /\b(how\s+to\s+(stalk|doxx|blackmail)|track\s+(their|her|his)\s+(phone|location)\s+without)\b/i,
    reason: "That request isn't something Gotchu can help with.",
  },
];

export type SafetyCheck =
  | { ok: true }
  | { ok: false; message: string; code: "safety" };

/** Fast local check before calling the model. */
export function checkUserTextSafety(...parts: Array<string | undefined | null>): SafetyCheck {
  const text = parts.filter(Boolean).join("\n").trim();
  if (!text) return { ok: true };
  for (const { re, reason } of BLOCK_PATTERNS) {
    if (re.test(text)) {
      return { ok: false, message: reason, code: "safety" };
    }
  }
  return { ok: true };
}

/**
 * Optional OpenAI Moderations pass for severe categories only.
 * Skips when OPENAI_API_KEY missing or text is tiny. Never blocks ordinary flirting
 * solely on "sexual" — dating apps are flirty by nature.
 */
export async function moderateIfConfigured(
  text: string,
): Promise<SafetyCheck> {
  const trimmed = text.trim();
  if (trimmed.length < 24) return { ok: true };

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return { ok: true };

  // Opt-in: set SAFETY_MODERATION=true to enable network moderation.
  if (Deno.env.get("SAFETY_MODERATION") !== "true") return { ok: true };

  try {
    const response = await fetch("https://api.openai.com/v1/moderations", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "omni-moderation-latest",
        input: trimmed.slice(0, 4000),
      }),
    });
    if (!response.ok) return { ok: true };

    const payload = await response.json();
    const result = payload?.results?.[0];
    if (!result) return { ok: true };

    const categories = result.categories ?? {};
    const severe =
      categories["sexual/minors"] === true ||
      categories["violence/graphic"] === true ||
      categories["illicit/violent"] === true;

    if (severe) {
      return {
        ok: false,
        message: "That request isn't something Gotchu can help with.",
        code: "safety",
      };
    }
  } catch (e) {
    console.error(`moderation skipped: ${e instanceof Error ? e.message : e}`);
  }
  return { ok: true };
}

export async function assertSafeUserText(
  ...parts: Array<string | undefined | null>
): Promise<SafetyCheck> {
  const local = checkUserTextSafety(...parts);
  if (!local.ok) return local;
  return moderateIfConfigured(parts.filter(Boolean).join("\n"));
}
