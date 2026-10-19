import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { responsesJson } from "../_shared/openai_responses.ts";
import { assertSafeUserText, SAFETY_RULES } from "../_shared/safety.ts";
import {
  assertGenerationAllowed,
  attachUsage,
  recordGeneration,
} from "../_shared/usage.ts";

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

    const usageGate = await assertGenerationAllowed(supabase, user.id);
    if (!usageGate.ok) return usageGate.response;

    const body = await req.json();
    const mode = String(body.mode ?? "briefing").toLowerCase();
    const name = String(body.name ?? "them").trim().slice(0, 80);
    const note = String(body.note ?? "").trim().slice(0, 400);
    const status = String(body.status ?? "").trim().slice(0, 40);
    const historySnippets = Array.isArray(body.historySnippets)
      ? body.historySnippets.map((s: unknown) => String(s).slice(0, 200)).slice(0, 5)
      : [];
    const debrief = String(body.debrief ?? "").trim().slice(0, 800);

    const safety = await assertSafeUserText(note, debrief, ...historySnippets);
    if (!safety.ok) {
      return jsonResponse(
        { error: safety.message, code: safety.code },
        422,
      );
    }

    const instructions = mode === "debrief"
      ? `You are Gotchu. User just debriefed a date/chat with someone. Give one warm tip and 2 short next-move suggestions. Casual. JSON only:
{ "tip": "...", "nextMoves": ["...", "..."] }

${SAFETY_RULES}`
      : `You are Gotchu. Prep a quick date/chat briefing from local notes only. Do not invent biography. JSON only:
{ "whatYouKnow": ["..."], "goodTopics": ["..."], "avoid": ["..."], "challenge": "one short line" }

${SAFETY_RULES}`;

    const userText = mode === "debrief"
      ? `Person: ${name}\nNote: ${note}\nStatus: ${status}\nDebrief: ${debrief}\nRecent lines:\n${historySnippets.join("\n")}`
      : `Person: ${name}\nNote: ${note}\nStatus: ${status}\nRecent lines:\n${historySnippets.join("\n") || "(none)"}`;

    const ai = await responsesJson({
      instructions,
      userText,
      model: "gpt-4o-mini",
      temperature: 0.75,
    });

    const usage = await recordGeneration(supabase, user.id);

    if (mode === "debrief") {
      const moves = Array.isArray(ai.nextMoves)
        ? ai.nextMoves.map((m) => String(m).trim()).filter(Boolean).slice(0, 3)
        : [];
      return jsonResponse(attachUsage({
        tip: String(ai.tip ?? "Be kind to yourself and keep it light.").trim(),
        nextMoves: moves,
      }, usage));
    }

    return jsonResponse(attachUsage({
      whatYouKnow: Array.isArray(ai.whatYouKnow)
        ? ai.whatYouKnow.map((x) => String(x).trim()).filter(Boolean).slice(0, 4)
        : [],
      goodTopics: Array.isArray(ai.goodTopics)
        ? ai.goodTopics.map((x) => String(x).trim()).filter(Boolean).slice(0, 4)
        : [],
      avoid: Array.isArray(ai.avoid)
        ? ai.avoid.map((x) => String(x).trim()).filter(Boolean).slice(0, 3)
        : [],
      challenge: String(ai.challenge ?? "").trim(),
    }, usage));
  } catch (error) {
    const message = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`people-coach: ${message}`);
    return jsonResponse(
      { error: "Couldn't build that coaching note. Try again.", code: "server" },
      500,
    );
  }
});
