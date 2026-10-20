import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const PRODUCT_ID = "kehlo_practice_1h";
const HOURS = 1;
const DAILY_CAP = 20;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization", code: "auth" }, 401);
    }

    let hintedTx = "";
    try {
      const raw = await req.json();
      if (raw && typeof raw === "object") {
        hintedTx = String(
          (raw as { storeTransactionId?: string }).storeTransactionId ?? "",
        ).trim();
      }
    } catch {
      // empty body
    }
    if (!hintedTx) {
      return jsonResponse(
        { error: "Practice purchase wasn’t found. Try again.", code: "not_found" },
        400,
      );
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized", code: "auth" }, 401);
    }

    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!serviceKey) {
      return jsonResponse({ error: "Practice isn’t configured.", code: "config" }, 503);
    }
    const admin = createClient(Deno.env.get("SUPABASE_URL") ?? "", serviceKey);

    await admin.from("profiles").upsert(
      { id: user.id, display_name: "You", is_anonymous: user.is_anonymous ?? true },
      { onConflict: "id", ignoreDuplicates: true },
    );

    const { data: existing } = await admin
      .from("practice_redemptions")
      .select("granted_until")
      .eq("store_transaction_id", hintedTx)
      .maybeSingle();

    const { data: profile } = await admin
      .from("profiles")
      .select("practice_expires_at")
      .eq("id", user.id)
      .maybeSingle();

    const now = Date.now();
    const currentRaw = profile?.practice_expires_at as string | null | undefined;
    const currentMs = currentRaw ? Date.parse(currentRaw) : NaN;
    const base = Number.isFinite(currentMs) && currentMs > now ? currentMs : now;

    let untilIso: string;
    if (existing?.granted_until) {
      untilIso = existing.granted_until as string;
    } else {
      const since = new Date(now - 24 * 60 * 60 * 1000).toISOString();
      const { count } = await admin
        .from("practice_redemptions")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .gte("created_at", since);
      if ((count ?? 0) >= DAILY_CAP) {
        return jsonResponse(
          { error: "You’ve hit today’s practice limit. Try again tomorrow.", code: "rate_limit" },
          429,
        );
      }
      untilIso = new Date(base + HOURS * 60 * 60 * 1000).toISOString();
      const { error: redErr } = await admin.from("practice_redemptions").insert({
        user_id: user.id,
        store_transaction_id: hintedTx,
        product_id: PRODUCT_ID,
        granted_until: untilIso,
      });
      if (redErr && redErr.code !== "23505") {
        console.error(`activate-practice: ${redErr.message}`);
        return jsonResponse({ error: "Couldn’t start the hour.", code: "server" }, 500);
      }
    }

    const untilMs = Date.parse(untilIso);
    const savedUntil = Number.isFinite(untilMs) && untilMs > base
      ? untilIso
      : new Date(base + HOURS * 60 * 60 * 1000).toISOString();

    const { error: updErr } = await admin
      .from("profiles")
      .update({ practice_expires_at: savedUntil })
      .eq("id", user.id);
    if (updErr) {
      return jsonResponse({ error: "Couldn’t start the hour.", code: "server" }, 500);
    }

    return jsonResponse({
      ok: true,
      practiceExpiresAt: savedUntil,
      hours: HOURS,
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`activate-practice: ${msg}`);
    return jsonResponse({ error: "Something went wrong.", code: "server" }, 500);
  }
});
