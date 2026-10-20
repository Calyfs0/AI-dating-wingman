-- Timed Pro (Boost): profiles.pro_expires_at + one-time redemption log.
-- Monthly subscription: is_pro=true, pro_expires_at=null.
-- Boost: is_pro=true, pro_expires_at = now + 1h (stacked from max(now, existing)).

alter table public.profiles
  add column if not exists pro_expires_at timestamptz null;

comment on column public.profiles.pro_expires_at is
  'When set, Pro ends at this time (Boost). Null means subscription / non-expiring Pro.';

create table if not exists public.boost_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  store_transaction_id text not null,
  product_id text not null,
  granted_until timestamptz not null,
  created_at timestamptz not null default now(),
  unique (store_transaction_id)
);

create index if not exists boost_redemptions_user_idx
  on public.boost_redemptions (user_id, created_at desc);

alter table public.boost_redemptions enable row level security;

-- Clients cannot read/write redemptions; only service_role (Edge) does.
drop policy if exists "boost_redemptions_none" on public.boost_redemptions;

comment on table public.boost_redemptions is
  'Idempotent Boost grants keyed by App Store / RC transaction id.';

-- Block clients from changing Pro expiry (same as is_pro).
create or replace function public.protect_profiles_is_pro()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and coalesce(auth.role(), '') <> 'service_role' then
    if new.is_pro is distinct from old.is_pro then
      new.is_pro := old.is_pro;
    end if;
    if new.pro_expires_at is distinct from old.pro_expires_at then
      new.pro_expires_at := old.pro_expires_at;
    end if;
  end if;
  return new;
end;
$$;

comment on function public.protect_profiles_is_pro is
  'Blocks JWT clients from changing is_pro / pro_expires_at; Edge (service_role) may update.';
