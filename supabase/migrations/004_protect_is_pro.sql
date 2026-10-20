-- Prevent clients from self-granting Pro. Only service_role may flip is_pro.
-- Edge sync-entitlement uses the service role after RevenueCat verification.

create or replace function public.protect_profiles_is_pro()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and new.is_pro is distinct from old.is_pro
     and coalesce(auth.role(), '') <> 'service_role' then
    new.is_pro := old.is_pro;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_profiles_is_pro on public.profiles;
create trigger trg_protect_profiles_is_pro
  before update on public.profiles
  for each row
  execute function public.protect_profiles_is_pro();

comment on function public.protect_profiles_is_pro is
  'Blocks JWT clients from changing profiles.is_pro; sync-entitlement (service_role) may update.';
