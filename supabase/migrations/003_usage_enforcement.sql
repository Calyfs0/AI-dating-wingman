-- P0: Server-side daily generation limits
-- Reuses usage_events; tightens RLS so clients cannot wipe their quota.
-- Adds profiles.is_pro for future RevenueCat sync (env PRO_UNLOCK_ALL also supported).

alter table public.profiles
  add column if not exists is_pro boolean not null default false;

create index if not exists usage_events_user_created_idx
  on public.usage_events (user_id, created_at desc);

create index if not exists usage_events_user_action_created_idx
  on public.usage_events (user_id, action, created_at desc);

-- Replace open "for all" policy: users may read/insert own events, not update/delete.
drop policy if exists "usage_own" on public.usage_events;

create policy "usage_select_own" on public.usage_events
  for select using (auth.uid() = user_id);

create policy "usage_insert_own" on public.usage_events
  for insert with check (auth.uid() = user_id);

comment on column public.profiles.is_pro is
  'Pro entitlement flag. Sync from RevenueCat webhook when wired; Edge also honors PRO_UNLOCK_ALL env.';
