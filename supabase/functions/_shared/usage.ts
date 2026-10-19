import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { jsonResponse } from "./cors.ts";

/** Billable AI actions share one daily pool (Reply, Openers, Profile Audit, People Coach). */
export const GENERATION_ACTION = "generation";

export type UsageSnapshot = {
  used: number;
  limit: number;
  remaining: number;
  isPro: boolean;
};

export type UsageGate =
  | { ok: true; snapshot: UsageSnapshot }
  | { ok: false; snapshot: UsageSnapshot; response: Response };

function readLimit(name: string, fallback: number): number {
  const raw = Number(Deno.env.get(name) ?? "");
  if (!Number.isFinite(raw) || raw < 1) return fallback;
  return Math.floor(raw);
}

/** Free default 12 matches Flutter UsageController; override via FREE_DAILY_LIMIT. */
export function dailyLimits(): { free: number; pro: number } {
  const free = readLimit("FREE_DAILY_LIMIT", 12);
  const pro = Math.max(free, readLimit("PRO_DAILY_LIMIT", 200));
  return { free, pro };
}

/** UTC calendar day start — source of truth for server + client refresh. */
export function utcDayStartIso(): string {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  ).toISOString();
}

async function resolveIsPro(
  supabase: SupabaseClient,
  userId: string,
): Promise<boolean> {
  // Temporary unlock for staging / support. TODO: RevenueCat webhook → profiles.is_pro
  if (Deno.env.get("PRO_UNLOCK_ALL") === "true") return true;

  const { data } = await supabase
    .from("profiles")
    .select("is_pro")
    .eq("id", userId)
    .maybeSingle();
  return data?.is_pro === true;
}

async function countGenerationsToday(
  supabase: SupabaseClient,
  userId: string,
): Promise<number> {
  const { count, error } = await supabase
    .from("usage_events")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("action", GENERATION_ACTION)
    .gte("created_at", utcDayStartIso());

  if (error) throw error;
  return count ?? 0;
}

function limitMessage(isPro: boolean): string {
  return isPro
    ? "You've hit today's Pro limit. Try again tomorrow."
    : "You've used today's free replies. Pro unlocks more — join the waitlist in You.";
}

/**
 * Reject with HTTP 402 when the caller is over today's generation quota.
 * Does not insert an event — call [recordGeneration] only after a successful AI response.
 */
export async function assertGenerationAllowed(
  supabase: SupabaseClient,
  userId: string,
): Promise<UsageGate> {
  const { free, pro } = dailyLimits();
  const isPro = await resolveIsPro(supabase, userId);
  const limit = isPro ? pro : free;
  const used = await countGenerationsToday(supabase, userId);
  const remaining = Math.max(0, limit - used);
  const snapshot: UsageSnapshot = { used, limit, remaining, isPro };

  if (used >= limit) {
    return {
      ok: false,
      snapshot,
      response: jsonResponse(
        {
          error: limitMessage(isPro),
          code: "usage_limit",
          usage: snapshot,
        },
        402,
      ),
    };
  }

  return { ok: true, snapshot };
}

/** Persist one billable generation. Ensures a profiles row for FK. */
export async function recordGeneration(
  supabase: SupabaseClient,
  userId: string,
): Promise<UsageSnapshot> {
  const { error: upsertError } = await supabase.from("profiles").upsert(
    {
      id: userId,
      display_name: "You",
      is_anonymous: true,
    },
    { onConflict: "id", ignoreDuplicates: true },
  );
  if (upsertError) {
    console.error(`usage upsert profile: ${upsertError.message}`);
  }

  const { error: insertError } = await supabase.from("usage_events").insert({
    user_id: userId,
    action: GENERATION_ACTION,
  });
  if (insertError) {
    console.error(`usage insert: ${insertError.message}`);
  }

  const { free, pro } = dailyLimits();
  const isPro = await resolveIsPro(supabase, userId);
  const limit = isPro ? pro : free;
  const used = await countGenerationsToday(supabase, userId);
  return {
    used,
    limit,
    remaining: Math.max(0, limit - used),
    isPro,
  };
}

export function attachUsage<T extends Record<string, unknown>>(
  body: T,
  usage: UsageSnapshot,
): T & { usage: UsageSnapshot } {
  return { ...body, usage };
}
