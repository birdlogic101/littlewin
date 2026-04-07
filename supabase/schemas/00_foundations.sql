-- =============================================================================
-- 00_foundations.sql
-- Foundational schema for Littlewin: Types, Tables, Indexes, and RLS.
-- WARNING = This file is exactly the file that is in Supabase. Every modification must be updated in Supabase.
-- =============================================================================

-- Enable necessary extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_net";

-- 1. Create Types
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM ('basic', 'premium');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'run_status') THEN
        CREATE TYPE public.run_status AS ENUM ('ongoing', 'completed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'visibility_type') THEN
        CREATE TYPE public.visibility_type AS ENUM ('public', 'private');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'stake_category') THEN
        CREATE TYPE public.stake_category AS ENUM ('plan', 'gift', 'custom');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bet_status') THEN
        CREATE TYPE public.bet_status AS ENUM ('pending', 'won', 'lost');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notif_type') THEN
        CREATE TYPE public.notif_type AS ENUM ('bet_won', 'bet_lost', 'bet_received', 'checkin_reminder', 'new_follower');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notif_status') THEN
        CREATE TYPE public.notif_status AS ENUM ('pending', 'read');
    END IF;
END $$;

-- 2. Create Tables

-- 2.1 users
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  username varchar(20) unique not null,
  email varchar(255) null,
  avatar_id int null check (avatar_id between 1 and 10),
  roles app_role[] default '{basic}',
  created_at timestamp with time zone default now() not null,
  fcm_token varchar(255) null,
  anonymous_id varchar(255) unique null
);
alter table public.users enable row level security;

-- 2.2 challenges
create table if not exists public.challenges (
  id uuid default uuid_generate_v4() primary key,
  title varchar(50) not null,
  description varchar(500) null,
  slug varchar(60) unique not null,
  created_at timestamp with time zone default now() not null,
  created_by uuid references public.users(id) on delete set null,
  visibility visibility_type default 'public' not null,
  current_participant_count int default 0 not null,
  total_runs_count int default 0 not null,
  top_streak int default 0 not null,
  image_asset varchar(255) null
);
alter table public.challenges enable row level security;

-- Ensure image_asset column exists for existing tables
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name='challenges' and column_name='image_asset') then
    alter table public.challenges add column image_asset varchar(255);
  end if;
end $$;

create index if not exists challenges_created_at_idx on public.challenges (created_at);
create index if not exists challenges_slug_idx on public.challenges (slug);

-- 2.3 runs
create table if not exists public.runs (
  id uuid default uuid_generate_v4() primary key,
  challenge_id uuid references public.challenges(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  visibility visibility_type default 'public' not null,
  start_date date not null, -- UTC day
  current_streak int default 0 not null,
  final_score int null,
  status run_status default 'ongoing' not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  recent_bet_count int default 0 not null,
  last_checkin_day date -- denormalized for performance
);
alter table public.runs enable row level security;
create index if not exists runs_user_id_idx on public.runs (user_id);
create index if not exists runs_status_idx on public.runs (status);
create index if not exists runs_challenge_id_idx on public.runs (challenge_id);
create index if not exists runs_updated_at_idx on public.runs (updated_at);
create index if not exists runs_user_status_updated_idx on public.runs (user_id, status, updated_at);

-- 2.4 checkins
create table if not exists public.checkins (
  id uuid default uuid_generate_v4() primary key,
  run_id uuid references public.runs(id) on delete cascade not null,
  check_in_day_utc date not null,
  updated_at timestamp with time zone default now() not null,
  unique(run_id, check_in_day_utc)
);
alter table public.checkins enable row level security;
create index if not exists checkins_run_id_idx on public.checkins (run_id);
create index if not exists checkins_check_in_day_utc_idx on public.checkins (check_in_day_utc);

-- Maintenance: and Ensure the new last_checkin_day column is populated for existing runs.
do $$ 
begin
  if not exists (select 1 from information_schema.columns where table_name='runs' and column_name='last_checkin_day') then
    alter table public.runs add column last_checkin_day date;
    update public.runs r set last_checkin_day = (select max(check_in_day_utc) from public.checkins c where c.run_id = r.id);
  end if;
end $$;

-- 2.5 stakes
create table if not exists public.stakes (
  id uuid default uuid_generate_v4() primary key,
  title varchar(100) not null,
  category stake_category not null,
  emoji varchar(10) null,
  created_at timestamp with time zone default now() not null,
  created_by uuid references public.users(id) on delete set null
);
alter table public.stakes enable row level security;

-- 2.6 bets
create table if not exists public.bets (
  id uuid default uuid_generate_v4() primary key,
  run_id uuid references public.runs(id) on delete cascade not null,
  bettor_id uuid references public.users(id) on delete cascade not null,
  target_streak int not null,
  stake_id uuid references public.stakes(id) on delete set null,
  status bet_status default 'pending' not null,
  created_at timestamp with time zone default now() not null,
  won_at timestamp with time zone null,
  lost_at timestamp with time zone null,
  updated_at timestamp with time zone default now() not null,
  is_self_bet boolean default false not null,
  notified_in_app boolean default false not null,
  custom_stake_title varchar(100) null
);
alter table public.bets enable row level security;
create index if not exists bets_run_id_idx on public.bets (run_id);
create index if not exists bets_status_idx on public.bets (status);
create index if not exists bets_target_streak_idx on public.bets (target_streak);
create index if not exists bets_updated_at_idx on public.bets (updated_at);
create index if not exists bets_bettor_id_idx on public.bets (bettor_id);
create index if not exists bets_run_bettor_idx on public.bets (run_id, bettor_id);

-- 2.7 notifications
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  message varchar(255) not null,
  type notif_type not null,
  deep_link varchar(255) null,
  unique_hash varchar(64) unique null,
  created_at timestamp with time zone default now() not null,
  read_at timestamp with time zone null,
  status notif_status default 'pending' not null
);
alter table public.notifications enable row level security;
create index if not exists notifications_user_id_idx on public.notifications (user_id);
create index if not exists notifications_created_at_idx on public.notifications (created_at);
create index if not exists notifications_type_idx on public.notifications (type);

-- 2.8 follows
create table if not exists public.follows (
  id uuid default uuid_generate_v4() primary key,
  follower_id uuid references public.users(id) on delete cascade not null,
  followed_id uuid references public.users(id) on delete cascade not null,
  created_at timestamp with time zone default now() not null,
  unique(follower_id, followed_id),
  check (follower_id != followed_id)
);
alter table public.follows enable row level security;
create index if not exists follows_follower_id_idx on public.follows (follower_id);
create index if not exists follows_followed_id_idx on public.follows (followed_id);

-- 2.9 dismissed_challenges
create table if not exists public.dismissed_challenges (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  challenge_id uuid references public.challenges(id) on delete cascade not null,
  created_at timestamp with time zone default now() not null,
  expires_at timestamp with time zone not null,
  unique(user_id, challenge_id)
);
alter table public.dismissed_challenges enable row level security;
create index if not exists dismissed_challenges_user_id_idx on public.dismissed_challenges (user_id);
create index if not exists dismissed_challenges_challenge_id_idx on public.dismissed_challenges (challenge_id);

-- 2.10 dismissed_runs
create table if not exists public.dismissed_runs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  run_id uuid references public.runs(id) on delete cascade not null,
  created_at timestamp with time zone default now() not null,
  expires_at timestamp with time zone not null,
  unique(user_id, run_id)
);
alter table public.dismissed_runs enable row level security;
create index if not exists dismissed_runs_user_id_idx on public.dismissed_runs (user_id);
create index if not exists dismissed_runs_run_id_idx on public.dismissed_runs (run_id);

-- 2.11 app_config
create table if not exists public.app_config (
  key   text primary key,
  value text not null
);
alter table public.app_config enable row level security;
-- No RLS policies means only service_role/postgres can access it.

-- 3. RLS Policies

-- users
drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);

drop policy if exists "Users can read public profiles" on public.users;
create policy "Users can read public profiles" on public.users for select using (true);

-- challenges
drop policy if exists "Read public challenges" on public.challenges;
create policy "Read public challenges" on public.challenges for select using (visibility = 'public');

drop policy if exists "Creator can read own private challenges" on public.challenges;
create policy "Creator can read own private challenges" on public.challenges for select using (created_by = auth.uid());

drop policy if exists "Premium users can create challenges" on public.challenges;
create policy "Premium users can create challenges" on public.challenges for insert with check (
  exists (select 1 from public.users where id = auth.uid() and 'premium' = any(roles))
);

-- runs
drop policy if exists "Users manage own runs" on public.runs;
create policy "Users manage own runs" on public.runs for all using (user_id = auth.uid());

drop policy if exists "Read public runs" on public.runs;
create policy "Read public runs" on public.runs for select using (visibility = 'public');

-- checkins
drop policy if exists "Manage own checkins via run" on public.checkins;
create policy "Manage own checkins via run" on public.checkins for all using (
  exists (select 1 from public.runs where id = run_id and user_id = auth.uid())
);

drop policy if exists "Read checkins of public/own runs" on public.checkins;
create policy "Read checkins of public/own runs" on public.checkins for select using (
  exists (select 1 from public.runs where id = run_id and (visibility = 'public' or user_id = auth.uid()))
);

-- bets
drop policy if exists "Users manage own bets" on public.bets;
create policy "Users manage own bets" on public.bets for all using (bettor_id = auth.uid());

drop policy if exists "Read bets on public/own runs" on public.bets;
create policy "Read bets on public/own runs" on public.bets for select using (
  exists (select 1 from public.runs where id = run_id and (visibility = 'public' or user_id = auth.uid()))
);

-- stakes
drop policy if exists "Read all stakes" on public.stakes;
create policy "Read all stakes" on public.stakes for select using (true);

drop policy if exists "Premium users create stakes" on public.stakes;
create policy "Premium users create stakes" on public.stakes for insert with check (
  exists (select 1 from public.users where id = auth.uid() and 'premium' = any(roles))
);

-- notifications
drop policy if exists "Manage own notifications" on public.notifications;
create policy "Manage own notifications" on public.notifications for all using (user_id = auth.uid());

-- follows
drop policy if exists "Manage own follows" on public.follows;
create policy "Manage own follows" on public.follows for all using (follower_id = auth.uid());

drop policy if exists "Read own follows" on public.follows;
create policy "Read own follows" on public.follows for select using (follower_id = auth.uid() or followed_id = auth.uid());

-- dismissed_challenges
drop policy if exists "Manage own dismissed" on public.dismissed_challenges;
create policy "Manage own dismissed" on public.dismissed_challenges for all using (user_id = auth.uid());
-- dismissed_runs
drop policy if exists "Manage own dismissed runs" on public.dismissed_runs;
create policy "Manage own dismissed runs" on public.dismissed_runs for all using (user_id = auth.uid());

-- 4.1. handle_new_user
-- Automatically creates a profile in public.users when a new user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_username text;
begin
  -- Use metadata username if available (e.g. from Google login)
  v_username := coalesce(
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'full_name',
    'user_' || substring(new.id::text, 1, 8)
  );

  insert into public.users (id, username, email)
  values (new.id, v_username, new.email)
  on conflict (id) do nothing;
  
  return new;
end;
$$;

-- Trigger on auth.users (requires superuser or postgres role)
-- Note: In Supabase, this is usually managed via the Dashboard or a Migration.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 4.2. handle_follow_notification
-- Automatically creates a notification for the followed user.
create or replace function public.handle_follow_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_follower_name text;
begin
  select username into v_follower_name from public.users where id = new.follower_id;

  insert into public.notifications (user_id, message, type, deep_link, unique_hash)
  values (
    new.followed_id,
    v_follower_name || ' followed you!',
    'new_follower',
    '/people',
    'follow_' || new.follower_id || '_' || new.followed_id
  )
  on conflict (unique_hash) do nothing;
  
  return new;
end;
$$;

drop trigger if exists on_follow_created on public.follows;
create trigger on_follow_created
  after insert on public.follows
  for each row execute procedure public.handle_follow_notification();

-- 5. Grants
grant usage on schema public to authenticated, anon;
grant all on all tables in schema public to authenticated;
grant all on all sequences in schema public to authenticated;
grant all on all functions in schema public to authenticated;

-- 6. Row Level Security (RLS) Policies
-- Essential for enabling client-side joined queries!

-- 6.1 Users
create policy "Users can read all profiles" on public.users
  for select using (true);
create policy "Users can update their own profile" on public.users
  for update using (auth.uid() = id);

-- 6.2 Challenges
create policy "Challenges are readable by all" on public.challenges
  for select using (true);

-- 6.3 Runs
create policy "Runs are readable by all" on public.runs
  for select using (true);
create policy "Users can update their own runs" on public.runs
  for update using (auth.uid() = user_id);

-- 6.4 Stakes
create policy "Stakes are readable by all" on public.stakes
  for select using (true);

-- 6.5 Bets
create policy "Bets are readable by all" on public.bets
  for select using (true);
create policy "Users can place bets" on public.bets
  for insert with check (auth.uid() = bettor_id);

-- 7. Seed Default Stakes
insert into public.stakes (id, title, category, emoji)
values
  ('a0000000-0000-0000-0000-000000000001', 'Coffee Cup', 'plan', '☕'),
  ('a0000000-0000-0000-0000-000000000002', 'Brunch Invite', 'plan', '🥐'),
  ('a0000000-0000-0000-0000-000000000003', 'Restaurant Dinner', 'plan', '🍽️'),
  ('a0000000-0000-0000-0000-000000000004', 'Drinks Round', 'plan', '🍻'),
  ('a0000000-0000-0000-0000-000000000005', 'Cinema Night', 'plan', '🍿'),
  ('a0000000-0000-0000-0000-000000000006', 'Chocolate Box', 'gift', '🍫'),
  ('a0000000-0000-0000-0000-000000000007', 'Wine Bottle', 'gift', '🍷'),
  ('a0000000-0000-0000-0000-000000000008', 'Spa Access', 'gift', '🧘'),
  ('a0000000-0000-0000-0000-000000000009', 'Massage Session', 'gift', '💆'),
  ('a0000000-0000-0000-0000-00000000000a', 'Surprise Box', 'gift', '🎁')
on conflict (id) do nothing;
