import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { responsesJson } from "../_shared/openai_responses.ts";

const MAX_IMAGE_CHARS = 7_500_000;

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
    if (!image) {
      return jsonResponse(
        { error: "Upload a profile screenshot to continue.", code: "validation" },
        400,
      );
    }
    const bio = String(body.bio ?? "").trim().slice(0, 1200);

    const instructions = `You are Gotchu Profile. Analyze ONE dating-profile screenshot (Hinge/Bumble/Tinder/etc).

Return scores 0–1 for: overall, clarity, personality, approachability, conversationPotential.
Give 2–4 short photoNotes (keep / replace / reorder style advice — no mean insults).
Rewrite bio three ways: bioLikeMe (same vibe), bioFunnier, bioShorter.
Extract hook: one concrete visible detail good for an opener.
If bio text was provided, treat it as currentBio; else extract visible bio/prompts into currentBio.

Never invent photos or hobbies that are not visible.

Return JSON only:
{
  "overall": 0.0,
  "clarity": 0.0,
  "personality": 0.0,
  "approachability": 0.0,
  "conversationPotential": 0.0,
  "photoNotes": ["...", "..."],
  "currentBio": "...",
  "bioLikeMe": "...",
  "bioFunnier": "...",
  "bioShorter": "...",
  "hook": "..."
}`;

    const ai = await responsesJson({
      instructions,
      userText: bio
        ? `Optional bio from user:\n${bio}\n\nAnalyze the profile screenshot. Image processed in-memory only — never stored.`
        : "Analyze this dating profile screenshot. Image processed in-memory only — never stored.",
      imageDataUrl: image,
      model: "gpt-4o-mini",
      temperature: 0.7,
    });

    const notes = Array.isArray(ai.photoNotes)
      ? ai.photoNotes.map((n) => String(n).trim()).filter(Boolean).slice(0, 4)
      : [];

    return jsonResponse({
      overall: Number(ai.overall ?? 0.65),
      clarity: Number(ai.clarity ?? 0.65),
      personality: Number(ai.personality ?? 0.65),
      approachability: Number(ai.approachability ?? 0.65),
      conversationPotential: Number(ai.conversationPotential ?? 0.65),
      photoNotes: notes,
      currentBio: String(ai.currentBio ?? bio).trim(),
      bioLikeMe: String(ai.bioLikeMe ?? "").trim(),
      bioFunnier: String(ai.bioFunnier ?? "").trim(),
      bioShorter: String(ai.bioShorter ?? "").trim(),
      hook: String(ai.hook ?? "").trim() || null,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`profile-audit: ${message}`);
    return jsonResponse(
      {
        error: "Something went wrong auditing this profile. Please try again.",
        code: "server",
      },
      500,
    );
  }
});
