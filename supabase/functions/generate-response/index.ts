import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { chatJson } from "../_shared/openai.ts";

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
    const style = body.style ?? {};
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

    const priorText = String(body.priorText ?? "");
    const conversationBlob = JSON.stringify(structured);

    let system =
      "You are Wingman, a private AI dating coach. Write replies the USER can send themselves. Never claim you sent the message. Return JSON only.";
    let userPrompt = "";

    if (mode === "humanize") {
      system +=
        " Return {\"text\": string, \"alternatives\": string[2], \"why_it_works\": string, \"send_worthiness\": number}. Soften robotic wording; keep meaning.";
      userPrompt =
        `Tone: ${tone}\nStyle: ${JSON.stringify(style)}\nConversation: ${conversationBlob}\nCurrent draft:\n${priorText}\nMake it sound more human and like the user.`;
    } else if (mode === "regenerate") {
      system +=
        " Return {\"text\": string, \"alternatives\": string[2], \"why_it_works\": string, \"send_worthiness\": number}.";
      userPrompt =
        `Tone: ${tone}\nStyle: ${JSON.stringify(style)}\nDirection: ${direction || "fresh take"}\nConversation: ${conversationBlob}\nPrevious reply:\n${priorText}\nRegenerate a better reply.`;
    } else {
      system +=
        ` Write in a ${tone} tone. Return JSON: {"text": string, "alternatives": string[2], "why_it_works": string, "send_worthiness": number 0-10}. Match the user's likely voice from style when tone is yourStyle.`;
      userPrompt =
        `Tone: ${tone}\nCommunication style: ${JSON.stringify(style)}\nConversation JSON:\n${conversationBlob}\nSuggest the next message the user should send.`;
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
