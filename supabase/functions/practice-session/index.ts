import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { assertSafeUserText, SAFETY_RULES } from "../_shared/safety.ts";

const TOPIC_LABELS: Record<string, string> = {
  firstMessage: "they just matched — user is sending / continuing the first texts",
  keepingAlive: "keeping a casual chat alive",
  flirting: "light flirting",
  askingOut: "nudging toward hanging out",
  rejection: "interest cooling / soft rejection",
  firstDate: "sitting together on a first date",
  confidence: "nervous energy, staying natural",
};

async function chatJson(args: {
  system: string;
  user: string;
}): Promise<Record<string, unknown>> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY is not configured");

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      temperature: 0.9,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: args.system },
        { role: "user", content: args.user },
      ],
    }),
  });

  if (!response.ok) {
    const errText = (await response.text()).slice(0, 200);
    throw new Error(`OpenAI error ${response.status}: ${errText}`);
  }

  const payload = await response.json();
  const text = payload?.choices?.[0]?.message?.content;
  if (typeof text !== "string" || !text.trim()) {
    throw new Error("Empty OpenAI response");
  }
  return JSON.parse(text) as Record<string, unknown>;
}

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
    const topic = String(body.topic ?? "firstMessage");
    const topicLabel = TOPIC_LABELS[topic] ?? "casual dating chat";
    const personaName = String(body.personaName ?? "Alex").trim().slice(0, 40) ||
      "Alex";
    const personaStyle = String(body.personaStyle ?? "")
      .trim()
      .slice(0, 280);
    const message = String(body.message ?? "").trim().slice(0, 800);
    if (!message) {
      return jsonResponse(
        { error: "Say something to continue practice.", code: "validation" },
        400,
      );
    }

    const safety = await assertSafeUserText(message);
    if (!safety.ok) {
      return jsonResponse(
        { error: safety.message, code: safety.code },
        422,
      );
    }

    const history = Array.isArray(body.history) ? body.history : [];
    const userTurns =
      history.filter((h: { role?: string }) => h?.role === "user").length + 1;
    const forceDone = userTurns >= 4;

    const transcript = history
      .slice(-10)
      .map((h: { role?: string; text?: string }) => {
        const role = h?.role === "user" ? "YOU" : personaName.toUpperCase();
        return `${role}: ${String(h?.text ?? "").slice(0, 400)}`;
      })
      .join("\n");

    const styleLine = personaStyle
      ? `\nPersona vibe: ${personaStyle}`
      : "";

    const system = `You are ${personaName} — a real person the user matched with. Scene: ${topicLabel}.${styleLine}

CRITICAL:
- Reply ONLY as ${personaName} texting. Match the persona vibe above.
- Sound human: short, casual enough for this persona, imperfect.
- NEVER coach, teach, grade, or ask "what would you send".
- NEVER say you are an AI, Gotchu, or practice mode.
- React to what THEY just said like a real match would.
- 1–2 short lines max. Fragments OK. Emoji only if it fits this persona.
- After about 3–4 user messages, or if they clearly land a plan / close the loop, end the scene.

${SAFETY_RULES}
- If their message is clearly harmful / non-consensual, end the scene (done:true) with a short in-character deflection and feedback that notes the line crossed — still no lecture.

Return JSON only:
Continuing: {"personaLine":"${personaName.toLowerCase()} text","done":false}
Ending: {"personaLine":"optional last ${personaName} text","done":true,"feedback":{"summary":"one honest, non-hype observation of this rehearsal only","tips":["concrete notice","concrete notice"]}}

When ending — feedback rules (critical):
- Do NOT cheerlead, praise as “great”, or imply they’ll succeed in real life.
- Do NOT invent scores or ratings.
- Summary: 1 neutral sentence about what this practice chat felt like.
- Tips: 1–2 concrete notices (what was short/vague/clear) — not pep talk.`;

    const userPrompt =
      `Chat so far:\n${transcript || "(nothing yet — they may be opening)"}\n\n` +
      `They just sent:\n${message}\n\n` +
      (forceDone
        ? "End the scene now (done:true) with honest non-hype rehearsal notes only."
        : `Reply as ${personaName}. Stay in character.`);

    const ai = await chatJson({ system, user: userPrompt });

    let personaLine = String(ai.personaLine ?? "").trim();
    const done = ai.done === true || forceDone;
    if (!personaLine && !done) {
      personaLine = "haha wait say more";
    }

    let feedback = null;
    if (done) {
      const fb = (ai.feedback && typeof ai.feedback === "object")
        ? ai.feedback as Record<string, unknown>
        : {};
      const tips = Array.isArray(fb.tips)
        ? fb.tips.map((t) => String(t).trim()).filter(Boolean).slice(0, 2)
        : [];
      feedback = {
        summary: String(
          fb.summary ??
            "That was one rehearsal with one persona — real people react differently.",
        ).trim(),
        tips: tips.length > 0
          ? tips
          : [
            "This was practice, not a prediction",
            "Try another scene if you want more reps",
          ],
      };
    }

    return jsonResponse({
      personaLine: done && !String(ai.personaLine ?? "").trim() ? "" : personaLine,
      done,
      feedback,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`practice-session: ${message}`);
    return jsonResponse(
      {
        error: "Couldn't keep the chat going. Try again in a sec.",
        code: "server",
      },
      500,
    );
  }
});
