import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const PRO_ENTITLEMENT = "pro";
const MONTHLY_PRODUCT_ID = "kehlo_pro_monthly";

type RcSubRow = {
  expires_date?: string | null;
  unsubscribe_detected_at?: string | null;
  period_type?: string | null;
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

function isFuture(raw: string | null | undefined): boolean {
  if (raw == null || raw === "") return true;
  const t = Date.parse(raw);
  return Number.isFinite(t) && t > Date.now();
}

function subscriptionRowActive(sub: RcSubRow | undefined): boolean {
  if (!sub) return false;
  return isFuture(sub.expires_date);
}

/** Monthly wins even if the `pro` entitlement still names the Boost product. */
function hasSubscriptionPro(payload: RcSubscriber | null): boolean {
  if (!payload) return false;
  const subs = payload.subscriber?.subscriptions ?? {};
  if (subscriptionRowActive(subs[MONTHLY_PRODUCT_ID])) return true;
  for (const [productId, row] of Object.entries(subs)) {
    if (isBoostProductId(productId)) continue;
    if (subscriptionRowActive(row)) return true;
  }
  const ent = payload.subscriber?.entitlements?.[PRO_ENTITLEMENT];
  if (!ent) return false;
  if (isBoostProductId(ent.product_identifier)) return false;
  return isFuture(ent.expires_date);
}

async function fetchSubscriber(
  secret: string,
  appUserId: string,
): Promise<RcSubscriber | null> {
  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    {
      headers: {
        Authorization: `Bearer ${secret}`,
        "Content-Type": "application/json",
      },
    },
  );
  if (res.status === 404) return null;
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`RC ${res.status}: ${body.slice(0, 180)}`);
  }
  return await res.json() as RcSubscriber;
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

    let expectSubscription = false;
    let storeOwnsMonthly = false;
    let rcAppUserId = "";
    try {
      if (req.method === "POST") {
        const raw = await req.json();
        if (raw && typeof raw === "object") {
          const body = raw as {
            expectSubscription?: unknown;
            storeOwnsMonthly?: unknown;
            rcAppUserId?: unknown;
          };
          expectSubscription = body.expectSubscription === true;
          storeOwnsMonthly = body.storeOwnsMonthly === true;
          rcAppUserId = typeof body.rcAppUserId === "string"
            ? body.rcAppUserId.trim()
            : "";
        }
      }
    } catch {
      // empty body is a normal quiet sync
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
        { error: "Entitlement sync is not configured.", code: "config" },
        503,
      );
    }
    const admin = createClient(Deno.env.get("SUPABASE_URL") ?? "", serviceKey);
    const rcSecret = Deno.env.get("REVENUECAT_SECRET_KEY")?.trim() ?? "";

    const ids = [user.id];
    if (rcAppUserId && rcAppUserId !== user.id) ids.push(rcAppUserId);

    let subscriptionPro = false;
    let sawExpiredMonthly = false;
    if (rcSecret) {
      const attempts = expectSubscription ? 6 : 1;
      for (let attempt = 0; attempt < attempts && !subscriptionPro; attempt++) {
        if (attempt > 0) await new Promise((r) => setTimeout(r, 500));
        for (const id of ids) {
          try {
            const payload = await fetchSubscriber(rcSecret, id);
            if (hasSubscriptionPro(payload)) {
              subscriptionPro = true;
              break;
            }
            const row = payload?.subscriber?.subscriptions?.[MONTHLY_PRODUCT_ID];
            if (row && !subscriptionRowActive(row)) sawExpiredMonthly = true;
          } catch (e) {
            console.error(`sync-entitlement fetch ${id}: ${e}`);
          }
        }
      }
    }
    if (!subscriptionPro && storeOwnsMonthly && !sawExpiredMonthly) {
      // StoreKit already says this Apple ID owns Monthly (purchase or
      // "already subscribed"). Clear Boost. REST often lags that dialog.
      subscriptionPro = true;
    }

    const { data: existing, error: readError } = await admin
      .from("profiles")
      .select("id, is_pro, pro_expires_at")
      .eq("id", user.id)
      .maybeSingle();
    if (readError) {
      return jsonResponse({ error: "Could not save entitlement.", code: "server" }, 500);
    }

    const boostRaw = existing?.pro_expires_at as string | null | undefined;
    const boostMs = boostRaw ? Date.parse(boostRaw) : NaN;
    const boostActive = Number.isFinite(boostMs) && boostMs > Date.now();
    const alreadyMonthly = existing?.is_pro === true &&
      (boostRaw == null || boostRaw === "");

    let isPro = false;
    let proExpiresAt: string | null = null;
    let kind: "subscription" | "boost" | "none" = "none";

    if (subscriptionPro || (alreadyMonthly && !sawExpiredMonthly)) {
      isPro = true;
      proExpiresAt = null;
      kind = "subscription";
    } else if (boostActive) {
      isPro = true;
      proExpiresAt = boostRaw ?? null;
      kind = "boost";
    }

    if (existing) {
      const { error } = await admin
        .from("profiles")
        .update({ is_pro: isPro, pro_expires_at: proExpiresAt })
        .eq("id", user.id);
      if (error) {
        return jsonResponse({ error: "Could not save entitlement.", code: "server" }, 500);
      }
    } else {
      const { error } = await admin.from("profiles").insert({
        id: user.id,
        display_name: "You",
        is_anonymous: user.is_anonymous ?? true,
        is_pro: isPro,
        pro_expires_at: proExpiresAt,
      });
      if (error) {
        return jsonResponse({ error: "Could not save entitlement.", code: "server" }, 500);
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
