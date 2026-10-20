-- Practice "Keep going" hour. Does not touch is_pro / pro_expires_at.

alter table public.profiles
  add column if not exists practice_expires_at timestamptz null;

comment on column public.profiles.practice_expires_at is
  'When set and in the future, the current user can continue practice past the free turn cap until this time.';

create table if not exists public.practice_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  store_transaction_id text not null,
  product_id text not null,
  granted_until timestamptz not null,
  created_at timestamptz not null default now(),
  unique (store_transaction_id)
);

alter table public.practice_redemptions enable row level security;

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
    if new.practice_expires_at is distinct from old.practice_expires_at then
      new.practice_expires_at := old.practice_expires_at;
    end if;
  end if;
  return new;
end;
$$;
