import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const PRO_ENTITLEMENT = "pro";
const MONTHLY_PRODUCT_ID = "kehlo_pro_monthly";

type RcSubRow = {
  expires_date?: string | null;
  unsubscribe_detected_at?: string | null;
};

type RcSubscriber = {
  subscriber?: {
    entitlements?: Record<
      string,
      { expires_date?: string | null; product_identifier?: string }
    >;
    subscriptions?: Record<string, RcSubRow>;
  };
};

function isBoostProductId(id: string | undefined | null): boolean {
  if (!id) return false;
  const n = id.trim().toLowerCase();
  return n === "kehlo_boost_1h" || n.includes("boost");
}

function entitlementActive(
  entitlements: Record<string, { expires_date?: string | null }> | undefined,
  id: string,
): boolean {
  if (!entitlements) return false;
  const ent = entitlements[id];
  if (!ent) return false;
  const expires = ent.expires_date;
  if (expires == null || expires === "") return true; // lifetime / non-expiring
  const t = Date.parse(expires);
  if (!Number.isFinite(t)) return false;
  return t > Date.now();
}

/**
 * Paid access lasts until expires_date.
 * Cancel (unsubscribe_detected_at) does not end Pro early.
 */
function subscriptionRowActive(sub: RcSubRow | undefined): boolean {
  if (!sub) return false;
  const exp = sub.expires_date;
  if (!exp || exp === "") return !sub.unsubscribe_detected_at;
  const t = Date.parse(exp);
  return Number.isFinite(t) && t > Date.now();
}

/**
 * Monthly (or any non-Boost) subscription wins over timed Boost.
 * Never demote an active monthly just because `pro` entitlement still
 * points at a Boost product_identifier from an earlier grant.
 */
function hasSubscriptionPro(payload: RcSubscriber): boolean {
  const subs = payload.subscriber?.subscriptions ?? {};
  if (subscriptionRowActive(subs[MONTHLY_PRODUCT_ID])) return true;
  for (const [productId, row] of Object.entries(subs)) {
    if (isBoostProductId(productId)) continue;
    if (subscriptionRowActive(row)) return true;
  }

  const entitlements = payload.subscriber?.entitlements;
  if (!entitlementActive(entitlements, PRO_ENTITLEMENT)) return false;
  const entProduct = entitlements?.[PRO_ENTITLEMENT]?.product_identifier;
  // Boost-only entitlement ≠ Monthly Pro.
  if (isBoostProductId(entProduct)) return false;
  return true;
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
      return jsonResponse(
        {
          error: "Entitlement sync is not configured.",
          code: "config",
        },
        503,
      );
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      serviceKey,
    );

    let expectSubscription = false;
    let rcAppUserId = "";
    try {
      if (req.method === "POST") {
        const raw = await req.json();
        if (raw && typeof raw === "object") {
          const body = raw as {
            expectSubscription?: unknown;
            rcAppUserId?: unknown;
          };
          expectSubscription = body.expectSubscription === true;
          rcAppUserId = typeof body.rcAppUserId === "string"
            ? body.rcAppUserId.trim()
            : "";
        }
      }
    } catch {
      // no body — normal sync
    }

    const rcSecret = Deno.env.get("REVENUECAT_SECRET_KEY")?.trim() ?? "";
    let subscriptionPro = false;

    if (rcSecret) {
      // After Monthly is bought on top of Boost, REST lags the Store sheet.
      // Poll here so one purchase call can clear the Boost timer.
      const attempts = expectSubscription ? 8 : 1;
      for (let attempt = 0; attempt < attempts; attempt++) {
        if (attempt > 0) {
          await new Promise((r) => setTimeout(r, 700));
        }
        const ids = [user.id];
        if (rcAppUserId && rcAppUserId !== user.id) ids.push(rcAppUserId);
        let sawError = false;
        for (const id of ids) {
          const rcRes = await fetch(
            `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(id)}`,
            {
              headers: {
                Authorization: `Bearer ${rcSecret}`,
                "Content-Type": "application/json",
              },
            },
          );
          if (rcRes.status === 404) continue;
          if (!rcRes.ok) {
            const body = await rcRes.text();
            console.error(`RC subscriber ${rcRes.status}: ${body.slice(0, 200)}`);
            sawError = true;
            continue;
          }
          const payload = await rcRes.json() as RcSubscriber;
          if (hasSubscriptionPro(payload)) {
            subscriptionPro = true;
            break;
          }
        }
        if (subscriptionPro) break;
        if (sawError && attempt === attempts - 1 && !subscriptionPro) {
          return jsonResponse(
            {
              error: "Could not verify subscription. Try again.",
              code: "revenuecat",
            },
            502,
          );
        }
        if (expectSubscription && attempt === attempts - 1) {
          const keys = Object.keys(payload.subscriber?.subscriptions ?? {});
          console.error(
            `sync-entitlement: monthly not visible yet. subKeys=[${keys.join(",")}]`,
          );
        }
      }
    } else {
      subscriptionPro = false;
      console.warn("sync-entitlement: REVENUECAT_SECRET_KEY unset; is_pro=false");
    }

    const { data: existing, error: readError } = await admin
      .from("profiles")
      .select("id, pro_expires_at")
      .eq("id", user.id)
      .maybeSingle();
    if (readError) {
      console.error(`sync-entitlement read: ${readError.message}`);
      return jsonResponse(
        { error: "Could not save entitlement.", code: "server" },
        500,
      );
    }

    const boostExpiresRaw = existing?.pro_expires_at as string | null | undefined;
    const boostMs = boostExpiresRaw ? Date.parse(boostExpiresRaw) : NaN;
    const boostActive = Number.isFinite(boostMs) && boostMs > Date.now();

    // Subscription wins (clear timed Boost). Else keep active Boost. Else free.
    let isPro = false;
    let proExpiresAt: string | null = null;
    let kind: "subscription" | "boost" | "none" = "none";

    if (subscriptionPro) {
      isPro = true;
      proExpiresAt = null;
      kind = "subscription";
    } else if (boostActive) {
      isPro = true;
      proExpiresAt = boostExpiresRaw ?? null;
      kind = "boost";
    } else {
      isPro = false;
      proExpiresAt = null;
      kind = "none";
    }

    if (existing) {
      const { error: updateError } = await admin
        .from("profiles")
        .update({ is_pro: isPro, pro_expires_at: proExpiresAt })
        .eq("id", user.id);
      if (updateError) {
        console.error(`sync-entitlement update: ${updateError.message}`);
        return jsonResponse(
          { error: "Could not save entitlement.", code: "server" },
          500,
        );
      }
    } else {
      const { error: insertError } = await admin.from("profiles").insert({
        id: user.id,
        display_name: "You",
        is_anonymous: user.is_anonymous ?? true,
        is_pro: isPro,
        pro_expires_at: proExpiresAt,
      });
      if (insertError) {
        console.error(`sync-entitlement insert: ${insertError.message}`);
        return jsonResponse(
          { error: "Could not save entitlement.", code: "server" },
          500,
        );
      }
    }

    return jsonResponse({
      ok: true,
      isPro,
      kind,
      proExpiresAt,
      entitlement: PRO_ENTITLEMENT,
      source: rcSecret ? "revenuecat" : "none",
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`sync-entitlement: ${msg}`);
    return jsonResponse(
      { error: "Something went wrong syncing Pro.", code: "server" },
      500,
    );
  }
});
