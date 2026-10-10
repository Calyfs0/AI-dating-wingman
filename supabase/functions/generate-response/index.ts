import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { chatJson } from "../_shared/openai.ts";

const QUALITY_RULES = `You write the next message the USER should send.
STRICT RULES:
- Use ONLY the messages provided. Do not invent prior topics, plans, coffee, travel, or anything not in those messages.
- If messages are empty, return text explaining you need a chat screenshot (do not invent a chat).
- Sound like a real person texting: short, natural, 1–2 sentences.
- Reference something concrete that appears in the provided messages.
- Never cheesy pickup lines. Never mention Wingman or AI.
Return JSON only: {"text": string, "alternatives": string[2], "why_it_works": string, "send_worthiness": number 0-10}.`;

function messagesOnly(structured: Record<string, unknown>): unknown[] {
  return Array.isArray(structured.messages) ? structured.messages : [];
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
    const mode = String(body.mode ?? "generate");
    const tone = String(body.tone ?? "natural");
    const direction = String(body.direction ?? "");
    let structured = body.structured as Record<string, unknown> | null;

    if (!structured && body.conversationId) {
      const { data, error } = await supabase
        .from("conversations")
        .select("structured")
        .eq("id", body.conversationId)
        .eq("user_id", user.id)
        .maybeSingle();
      if (error || !data) {
        return jsonResponse({ error: "Conversation not found", code: "db" }, 404);
      }
      structured = data.structured as Record<string, unknown>;
    }

    if (!structured) {
      return jsonResponse(
        { error: "structured or conversationId required", code: "validation" },
        400,
      );
    }

    const messages = messagesOnly(structured);
    if (messages.length === 0) {
      return jsonResponse(
        {
          error:
            "No chat messages found. Upload a conversation screenshot first.",
          code: "validation",
        },
        400,
      );
    }

    const priorText = String(body.priorText ?? "");
    const messagesBlob = JSON.stringify(messages);
    const system = `You are Wingman. ${QUALITY_RULES}`;
    let userPrompt = "";

    if (mode === "humanize") {
      userPrompt =
        `Tone: natural\nMessages only:\n${messagesBlob}\nCurrent draft:\n${priorText}\nRewrite more naturally. Still only use facts from these messages.`;
    } else if (mode === "regenerate") {
      userPrompt =
        `Tone: ${tone}\nDirection: ${direction || "different but still grounded"}\nMessages only:\n${messagesBlob}\nPrevious reply:\n${priorText}\nWrite another reply based only on these messages.`;
    } else {
      userPrompt =
        `Tone: ${tone}\nMessages only (speaker user = me, other = them):\n${messagesBlob}\nWrite the best next message for me to send, based only on these messages.`;
    }

    const ai = await chatJson({ system, user: userPrompt });
    const id = crypto.randomUUID();

    return jsonResponse({
      id,
      text: String(ai.text ?? ""),
      tone,
      alternatives: Array.isArray(ai.alternatives)
        ? ai.alternatives.map((a) => String(a))
        : [],
      whyItWorks: String(ai.why_it_works ?? ""),
      sendWorthiness: Number(ai.send_worthiness ?? 7.5),
    });
  } catch (error) {
    console.error(error);
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Generation failed",
        code: "generation",
      },
      500,
    );
  }
});
