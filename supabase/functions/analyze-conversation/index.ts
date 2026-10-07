import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { chatJson, type ChatContentPart } from "../_shared/openai.ts";

const FREE_ANALYSIS_LIMIT = 3;
const MAX_IMAGES = 8;

function normalizeImageDataUrl(raw: string): string | null {
  const value = raw.trim();
  if (!value) return null;
  if (value.startsWith("data:image/")) return value;
  // Assume jpeg base64 if no prefix.
  if (/^[A-Za-z0-9+/=\s]+$/.test(value) && value.length > 100) {
    return `data:image/jpeg;base64,${value.replace(/\s/g, "")}`;
  }
  return null;
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
    const pastedText = String(body.pastedText ?? "").trim();
    const personName = String(body.personName ?? "Someone").trim() || "Someone";
    const mode = String(body.mode ?? "analyze");
    const imagesRaw = Array.isArray(body.images) ? body.images : [];
    const images = imagesRaw
      .map((item: unknown) => normalizeImageDataUrl(String(item ?? "")))
      .filter((item: string | null): item is string => item != null)
      .slice(0, MAX_IMAGES);

    if (mode === "interpret") {
      const message = String(body.message ?? "").trim();
      if (!message) {
        return jsonResponse({ error: "message required", code: "validation" }, 400);
      }
      const result = await chatJson({
        system:
          "You are Wingman, a private dating coach. Return JSON only with keys: interpretation (string), guidance (string). Be concise and practical. Never invent messages they did not send.",
        user: `Interpret this message from the other person:\n${message}`,
      });
      return jsonResponse({
        message,
        interpretation: String(result.interpretation ?? ""),
        guidance: String(result.guidance ?? ""),
      });
    }

    if (mode === "review") {
      const draft = String(body.draft ?? "").trim();
      if (!draft) {
        return jsonResponse({ error: "draft required", code: "validation" }, 400);
      }
      const result = await chatJson({
        system:
          "You are Wingman, a private dating coach. Return JSON only with keys: verdict (string), why (string), better (string), send_worthiness (number 0-10). Improve drafts without being cheesy.",
        user: `Review this draft before send:\n${draft}`,
      });
      return jsonResponse({
        original: draft,
        verdict: String(result.verdict ?? "I'd tweak it."),
        why: String(result.why ?? ""),
        better: String(result.better ?? draft),
        sendWorthiness: Number(result.send_worthiness ?? 7),
      });
    }

    if (!pastedText && images.length === 0) {
      return jsonResponse(
        {
          error: "Add a screenshot or paste the conversation text.",
          code: "validation",
        },
        400,
      );
    }

    const { count, error: countError } = await supabase
      .from("usage_events")
      .select("*", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("action", "conversationAnalysis");

    if (countError) {
      return jsonResponse({ error: countError.message, code: "usage" }, 500);
    }
    if ((count ?? 0) >= FREE_ANALYSIS_LIMIT) {
      return jsonResponse(
        {
          error: "You've reached your free limit. Go Pro to continue.",
          code: "usage_limit",
        },
        402,
      );
    }

    const system = `You are Wingman, a premium private AI dating coach.
You receive dating-app chat screenshots and/or pasted text from the USER's phone.
Read every visible message carefully. Do not invent messages that are not visible.
"user" = the app user seeking advice (usually messages on the right / "me").
"other" = the match (usually left side).
Use "unknown" only if speaker is unclear.
Detect the dating app if visible (Hinge, Bumble, Tinder, iMessage, WhatsApp, etc.).
Return JSON with this exact shape:
{
  "person_name": string,
  "platform": string,
  "participants": string[],
  "messages": [{"id": string, "text": string, "speaker": "user"|"other"|"unknown"}],
  "topics": string[],
  "conversation_state": "active"|"stalled"|"cooling"|"escalating",
  "interest_signals": {"interest": 0-1, "energy": 0-1, "momentum": 0-1, "reciprocity": 0-1},
  "recommended_strategy": {"read": string, "dos": string[], "donts": string[]},
  "confidence": 0-1,
  "key_facts": string[],
  "transcript": string
}
"transcript" should be a readable plain-text reconstruction of the chat (Them:/You: lines).
Be specific to these screenshots/text. No generic demo filler.`;

    const userParts: ChatContentPart[] = [
      {
        type: "text",
        text: `Person name hint: ${personName}
${pastedText ? `\nOptional pasted text:\n${pastedText}\n` : ""}
${images.length > 0 ? `There are ${images.length} screenshot(s). Read them in order (top to bottom of the chat).` : "No screenshots — use pasted text only."}`,
      },
      ...images.map((url) => ({
        type: "image_url" as const,
        image_url: { url, detail: "high" as const },
      })),
    ];

    const ai = await chatJson({
      system,
      user: userParts,
      model: "gpt-4o-mini",
    });

    const transcript = String(ai.transcript ?? pastedText ?? "");
    const structured = {
      person_name: String(ai.person_name ?? personName),
      platform: String(ai.platform ?? "Unknown"),
      participants: Array.isArray(ai.participants) ? ai.participants : ["You", personName],
      messages: Array.isArray(ai.messages) ? ai.messages : [],
      topics: Array.isArray(ai.topics) ? ai.topics : [],
      conversation_state: String(ai.conversation_state ?? "active"),
      interest_signals: ai.interest_signals ?? {},
      recommended_strategy: ai.recommended_strategy ?? {},
      confidence: Number(ai.confidence ?? 0.5),
      key_facts: Array.isArray(ai.key_facts) ? ai.key_facts : [],
      pasted_text: transcript,
      from_screenshots: images.length > 0,
    };

    const { data: row, error: insertError } = await supabase
      .from("conversations")
      .insert({
        user_id: user.id,
        structured,
      })
      .select("id, structured, created_at")
      .single();

    if (insertError || !row) {
      return jsonResponse(
        { error: insertError?.message ?? "Failed to save conversation", code: "db" },
        500,
      );
    }

    await supabase.from("usage_events").insert({
      user_id: user.id,
      action: "conversationAnalysis",
    });

    return jsonResponse({
      id: row.id,
      personName: structured.person_name,
      platform: structured.platform,
      participants: structured.participants,
      messages: structured.messages,
      topics: structured.topics,
      conversationState: structured.conversation_state,
      interestSignals: structured.interest_signals,
      recommendedStrategy: structured.recommended_strategy,
      confidence: structured.confidence,
      keyFacts: structured.key_facts,
      pastedText: transcript,
    });
  } catch (error) {
    console.error(error);
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Analysis failed",
        code: "analysis",
      },
      500,
    );
  }
});
