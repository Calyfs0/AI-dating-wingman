-- Profile auto-create on auth signup + delete helper + notifications column.

alter table public.profiles
  add column if not exists notifications_enabled boolean not null default false;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, is_anonymous)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', 'You'),
    coalesce((new.raw_app_meta_data ->> 'provider') = 'anonymous', true)
  )
  on conflict (id) do nothing;

  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Client-callable wipe of app data for the current user (auth.users deleted via delete-account function).
create or replace function public.delete_user_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.generation_feedback where user_id = auth.uid();
  delete from public.usage_events where user_id = auth.uid();
  delete from public.conversations where user_id = auth.uid();
  delete from public.people where user_id = auth.uid();
  delete from public.notification_preferences where user_id = auth.uid();
  delete from public.profiles where id = auth.uid();
end;
$$;

revoke all on function public.delete_user_data() from public;
grant execute on function public.delete_user_data() to authenticated;
