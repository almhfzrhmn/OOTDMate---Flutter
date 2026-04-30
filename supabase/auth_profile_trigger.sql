-- Run this in Supabase SQL Editor.
-- It makes public.users follow auth.users automatically, including when
-- email confirmation is enabled and the client has no authenticated session yet.

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  username text,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists "Users can read own profile" on public.users;
drop policy if exists "Users can insert own profile" on public.users;
drop policy if exists "Users can update own profile" on public.users;

create policy "Users can read own profile"
  on public.users
  for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.users
  for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.users
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create index if not exists idx_users_email on public.users(email);
create index if not exists idx_users_username on public.users(username);

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    email,
    username,
    full_name,
    avatar_url,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.email,
    nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'avatar_url'), ''),
    coalesce(new.created_at, now()),
    now()
  )
  on conflict (id) do update
  set
    email = excluded.email,
    username = coalesce(excluded.username, public.users.username),
    full_name = coalesce(excluded.full_name, public.users.full_name),
    avatar_url = coalesce(excluded.avatar_url, public.users.avatar_url),
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Backfill profiles for users that already exist in Authentication.
insert into public.users (
  id,
  email,
  username,
  full_name,
  avatar_url,
  created_at,
  updated_at
)
select
  id,
  email,
  nullif(trim(raw_user_meta_data ->> 'username'), ''),
  nullif(trim(raw_user_meta_data ->> 'full_name'), ''),
  nullif(trim(raw_user_meta_data ->> 'avatar_url'), ''),
  coalesce(created_at, now()),
  now()
from auth.users
on conflict (id) do update
set
  email = excluded.email,
  username = coalesce(excluded.username, public.users.username),
  full_name = coalesce(excluded.full_name, public.users.full_name),
  avatar_url = coalesce(excluded.avatar_url, public.users.avatar_url),
  updated_at = now();
