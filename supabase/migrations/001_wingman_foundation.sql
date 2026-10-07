-- Wingman foundation schema (Supabase-ready)
-- RLS: every row scoped to auth.uid(). Service role never ships in the Flutter client.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'You',
  is_anonymous boolean not null default true,
  onboarding_completed boolean not null default false,
  dating_goal text,
  flirting_level double precision not null default 0.5,
  focus_areas text[] not null default '{}',
  communication_styles text[] not null default '{}',
  learned_style jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  platform text not null default 'Hinge',
  status text not null default 'active',
  latest_context text,
  key_facts text[] not null default '{}',
  timeline jsonb not null default '[]'::jsonb,
  last_activity_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  person_id uuid references public.people (id) on delete set null,
  structured jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.generation_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  generation_id text not null,
  is_positive boolean not null,
  issues text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  action text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  enabled boolean not null default false,
  conversation_reminders boolean not null default true,
  date_briefings boolean not null default true,
  insights boolean not null default true
);

alter table public.profiles enable row level security;
alter table public.people enable row level security;
alter table public.conversations enable row level security;
alter table public.generation_feedback enable row level security;
alter table public.usage_events enable row level security;
alter table public.notification_preferences enable row level security;

create policy "profiles_own" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "people_own" on public.people
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "conversations_own" on public.conversations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "feedback_own" on public.generation_feedback
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "usage_own" on public.usage_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "notif_own" on public.notification_preferences
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Temporary screenshot objects should live in a private bucket with short-lived signed URLs.
-- Prefer deleting raw images after structured extraction unless the user explicitly retains them.
