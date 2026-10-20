import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const BOOST_PRODUCT_ID = "kehlo_boost_1h";
const MONTHLY_PRODUCT_ID = "kehlo_pro_monthly";
const BOOST_HOURS = 1;

type RcNonSubPurchase = {
  id?: string;
  purchase_date?: string;
  store_transaction_id?: string;
};

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
    non_subscriptions?: Record<string, RcNonSubPurchase[]>;
  };
};

function isBoostProductId(id: string | undefined | null): boolean {
  if (!id) return false;
  const n = id.trim().toLowerCase();
  return n === BOOST_PRODUCT_ID || n.includes("boost");
}

function entitlementActive(
  entitlements: Record<string, { expires_date?: string | null }> | undefined,
  id: string,
): boolean {
  if (!entitlements) return false;
  const ent = entitlements[id];
  if (!ent) return false;
  const expires = ent.expires_date;
  if (expires == null || expires === "") return true;
  const t = Date.parse(expires);
  if (!Number.isFinite(t)) return false;
  return t > Date.now();
}

function subscriptionRowActive(sub: RcSubRow | undefined): boolean {
  if (!sub) return false;
  const exp = sub.expires_date;
  if (!exp || exp === "") return !sub.unsubscribe_detected_at;
  const t = Date.parse(exp);
  return Number.isFinite(t) && t > Date.now();
}

/** Same rules as sync-entitlement: live Monthly wins over Boost-only entitlement. */
function hasSubscriptionPro(payload: RcSubscriber | null): boolean {
  if (!payload) return false;
  const subs = payload.subscriber?.subscriptions ?? {};
  if (subscriptionRowActive(subs[MONTHLY_PRODUCT_ID])) return true;
  for (const [productId, row] of Object.entries(subs)) {
    if (isBoostProductId(productId)) continue;
    if (subscriptionRowActive(row)) return true;
  }
  const entitlements = payload.subscriber?.entitlements;
  if (!entitlementActive(entitlements, "pro")) return false;
  const entProduct = entitlements?.pro?.product_identifier;
  if (isBoostProductId(entProduct)) return false;
  return true;
}

function collectBoostPurchases(
  nonSubs: Record<string, RcNonSubPurchase[]> | undefined,
): Array<RcNonSubPurchase & { productId: string }> {
  if (!nonSubs) return [];
  const out: Array<RcNonSubPurchase & { productId: string }> = [];
  for (const [productId, list] of Object.entries(nonSubs)) {
    if (!isBoostProductId(productId)) continue;
    for (const p of list ?? []) {
      out.push({ ...p, productId });
    }
  }
  return out.sort((a, b) => {
    const ta = Date.parse(a.purchase_date ?? "") || 0;
    const tb = Date.parse(b.purchase_date ?? "") || 0;
    return tb - ta;
  });
}

function txMatches(
  purchase: RcNonSubPurchase,
  hintedTx: string,
): boolean {
  const a = (purchase.store_transaction_id ?? "").trim();
  const b = (purchase.id ?? "").trim();
  return a === hintedTx || b === hintedTx;
}

async function fetchSubscriber(
  rcSecret: string,
  userId: string,
): Promise<RcSubscriber | null> {
  const rcRes = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
    {
      headers: {
        Authorization: `Bearer ${rcSecret}`,
        "Content-Type": "application/json",
      },
    },
  );
  if (rcRes.status === 404) return null;
  if (!rcRes.ok) {
    const body = await rcRes.text();
    throw new Error(`RC ${rcRes.status}: ${body.slice(0, 200)}`);
  }
  return await rcRes.json() as RcSubscriber;
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

    let body: {
      storeTransactionId?: string;
      productId?: string;
    } = {};
    try {
      if (req.method === "POST") {
        const raw = await req.json();
        if (raw && typeof raw === "object") {
          body = raw as typeof body;
        }
      }
    } catch {
      // empty body ok
    }

    const hintedTx = (body.storeTransactionId ?? "").trim();
    const hintedProduct = (body.productId ?? BOOST_PRODUCT_ID).trim();

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
    const rcSecret = Deno.env.get("REVENUECAT_SECRET_KEY")?.trim() ?? "";
    if (!serviceKey || !rcSecret) {
      return jsonResponse(
        { error: "Boost is not configured.", code: "config" },
        503,
      );
    }

    // One quick RC read for Monthly. Do not poll — Apple already confirmed,
    // and REST indexing is what made Boost feel stuck for 10s+ then fail.
    let payload: RcSubscriber | null = null;
    try {
      payload = await fetchSubscriber(rcSecret, user.id);
    } catch (e) {
      console.error(`activate-boost fetch: ${e}`);
    }
    let purchases = collectBoostPurchases(payload?.subscriber?.non_subscriptions);

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      serviceKey,
    );

    await admin.from("profiles").upsert(
      {
        id: user.id,
        display_name: "You",
        is_anonymous: user.is_anonymous ?? true,
      },
      { onConflict: "id", ignoreDuplicates: true },
    );

    // Active Monthly → Pro without timed Boost. Do not redeem Boost against Monthly.
    if (hasSubscriptionPro(payload)) {
      const { error: subErr } = await admin
        .from("profiles")
        .update({ is_pro: true, pro_expires_at: null })
        .eq("id", user.id);
      if (subErr) {
        console.error(`activate-boost sub: ${subErr.message}`);
        return jsonResponse(
          { error: "Could not save Pro status.", code: "server" },
          500,
        );
      }
      return jsonResponse({
        ok: true,
        isPro: true,
        kind: "subscription",
        proExpiresAt: null,
        message: "You’re already on Pro via subscription.",
      });
    }

    // SDK transaction from a completed StoreKit purchase. RC REST often
    // doesn't list it yet — redeem this id once (idempotent). Cap new grants
    // so a made-up id can't farm unlimited hours.
    if (hintedTx) {
      const hit = purchases.find((p) => txMatches(p, hintedTx));
      if (!hit) {
        const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        const { count } = await admin
          .from("boost_redemptions")
          .select("id", { count: "exact", head: true })
          .eq("user_id", user.id)
          .gte("created_at", since);
        if ((count ?? 0) >= 20) {
          return jsonResponse(
            {
              error: "You’ve hit today’s Boost limit. Try again tomorrow.",
              code: "rate_limit",
            },
            429,
          );
        }
        purchases = [{
          id: hintedTx,
          store_transaction_id: hintedTx,
          purchase_date: new Date().toISOString(),
          productId: isBoostProductId(hintedProduct)
            ? hintedProduct
            : BOOST_PRODUCT_ID,
        }];
      } else {
        purchases = [hit];
      }
    }

    if (purchases.length === 0) {
      return jsonResponse(
        {
          error: "No Boost purchase found. Buy Boost first, then try again.",
          code: "not_found",
        },
        404,
      );
    }

    const { data: profile } = await admin
      .from("profiles")
      .select("pro_expires_at")
      .eq("id", user.id)
      .maybeSingle();

    let grantedUntil: string | null = null;
    let redeemedTx: string | null = null;

    for (const purchase of purchases) {
      const txId = (purchase.store_transaction_id ?? purchase.id ?? "").trim();
      if (!txId) continue;

      const { data: existing } = await admin
        .from("boost_redemptions")
        .select("id, granted_until")
        .eq("store_transaction_id", txId)
        .maybeSingle();

      if (existing) {
        if (!grantedUntil && existing.granted_until) {
          const t = Date.parse(existing.granted_until);
          if (Number.isFinite(t) && t > Date.now()) {
            grantedUntil = existing.granted_until;
            redeemedTx = txId;
          }
        }
        continue;
      }

      const baseMs = (() => {
        const raw = profile?.pro_expires_at as string | null | undefined;
        const existingExp = raw ? Date.parse(raw) : NaN;
        const now = Date.now();
        if (Number.isFinite(existingExp) && existingExp > now) return existingExp;
        return now;
      })();
      const until = new Date(baseMs + BOOST_HOURS * 60 * 60 * 1000);
      const untilIso = until.toISOString();

      const { error: redErr } = await admin.from("boost_redemptions").insert({
        user_id: user.id,
        store_transaction_id: txId,
        product_id: purchase.productId || BOOST_PRODUCT_ID,
        granted_until: untilIso,
      });
      if (redErr) {
        if (redErr.code === "23505") continue;
        console.error(`activate-boost redeem: ${redErr.message}`);
        return jsonResponse(
          { error: "Could not activate Boost.", code: "server" },
          500,
        );
      }

      const { error: updErr } = await admin
        .from("profiles")
        .update({ is_pro: true, pro_expires_at: untilIso })
        .eq("id", user.id);
      if (updErr) {
        console.error(`activate-boost profile: ${updErr.message}`);
        return jsonResponse(
          { error: "Could not activate Boost.", code: "server" },
          500,
        );
      }

      grantedUntil = untilIso;
      redeemedTx = txId;
      break;
    }

    if (!grantedUntil) {
      const exp = profile?.pro_expires_at as string | null | undefined;
      const expMs = exp ? Date.parse(exp) : NaN;
      if (Number.isFinite(expMs) && expMs > Date.now()) {
        return jsonResponse({
          ok: true,
          isPro: true,
          kind: "boost",
          proExpiresAt: exp,
          message: "Boost is already active.",
        });
      }
      return jsonResponse(
        {
          error:
            "This Boost was already used. Buy another hour when you’re ready.",
          code: "already_redeemed",
        },
        409,
      );
    }

    return jsonResponse({
      ok: true,
      isPro: true,
      kind: "boost",
      proExpiresAt: grantedUntil,
      transactionId: redeemedTx,
      hours: BOOST_HOURS,
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message.slice(0, 180) : "unknown";
    console.error(`activate-boost: ${msg}`);
    return jsonResponse(
      { error: "Something went wrong activating Boost.", code: "server" },
      500,
    );
  }
});
