-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- create types
create type app_role as enum ('basic', 'premium');

create type run_status as enum ('ongoing', 'completed');
create type visibility_type as enum ('public', 'private');
create type stake_category as enum ('plan', 'gift', 'custom');
create type bet_status as enum ('pending', 'won', 'lost');
create type notif_type as enum ('bet_won', 'bet_lost', 'checkin_reminder');
create type notif_status as enum ('pending', 'read');


-- 4.1 users
create table public.users (
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

-- 4.2 challenges
create table public.challenges (
  id uuid default uuid_generate_v4() primary key,
  title varchar(50) not null,

  description varchar(500) null,
  slug varchar(60) unique not null,
  created_at timestamp with time zone default now() not null,
  created_by uuid references public.users(id) on delete set null,
  visibility visibility_type default 'public' not null,
  current_participant_count int default 0 not null,
  total_runs_count int default 0 not null,
  top_streak int default 0 not null
);
alter table public.challenges enable row level security;

create index challenges_created_at_idx on public.challenges (created_at);
create index challenges_slug_idx on public.challenges (slug);

-- 4.3 runs
create table public.runs (
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
  recent_bet_count int default 0 not null
);
alter table public.runs enable row level security;
create index runs_user_id_idx on public.runs (user_id);
create index runs_status_idx on public.runs (status);
create index runs_challenge_id_idx on public.runs (challenge_id);
create index runs_updated_at_idx on public.runs (updated_at);
create index runs_user_status_updated_idx on public.runs (user_id, status, updated_at);


-- 4.4 checkins
create table public.checkins (
  id uuid default uuid_generate_v4() primary key,
  run_id uuid references public.runs(id) on delete cascade not null,
  check_in_day_utc date not null,
  updated_at timestamp with time zone default now() not null,
  unique(run_id, check_in_day_utc)
);
alter table public.checkins enable row level security;
create index checkins_run_id_idx on public.checkins (run_id);
create index checkins_check_in_day_utc_idx on public.checkins (check_in_day_utc);

-- 4.5 stakes
create table public.stakes (
  id uuid default uuid_generate_v4() primary key,
  title varchar(100) not null,
  category stake_category not null,
  created_at timestamp with time zone default now() not null,
  created_by uuid references public.users(id) on delete set null
);
alter table public.stakes enable row level security;

-- 4.6 bets
create table public.bets (
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
  is_self_bet boolean default false not null
);
alter table public.bets enable row level security;
create index bets_run_id_idx on public.bets (run_id);
create index bets_status_idx on public.bets (status);
create index bets_target_streak_idx on public.bets (target_streak);
create index bets_updated_at_idx on public.bets (updated_at);
create index bets_bettor_id_idx on public.bets (bettor_id);
create index bets_run_bettor_idx on public.bets (run_id, bettor_id);

-- 4.7 notifications
create table public.notifications (
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
create index notifications_user_id_idx on public.notifications (user_id);
create index notifications_created_at_idx on public.notifications (created_at);
create index notifications_type_idx on public.notifications (type);

-- 4.8 follows
create table public.follows (
  id uuid default uuid_generate_v4() primary key,
  follower_id uuid references public.users(id) on delete cascade not null,
  followed_id uuid references public.users(id) on delete cascade not null,
  created_at timestamp with time zone default now() not null,
  unique(follower_id, followed_id)
);
alter table public.follows enable row level security;
create index follows_follower_id_idx on public.follows (follower_id);
create index follows_followed_id_idx on public.follows (followed_id);

-- 4.9 dismissed_challenges
create table public.dismissed_challenges (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  challenge_id uuid references public.challenges(id) on delete cascade not null,
  created_at timestamp with time zone default now() not null,
  expires_at timestamp with time zone not null,
  unique(user_id, challenge_id)
);
alter table public.dismissed_challenges enable row level security;
create index dismissed_challenges_user_id_idx on public.dismissed_challenges (user_id);
create index dismissed_challenges_challenge_id_idx on public.dismissed_challenges (challenge_id);

-- RLS Policies
-- users
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
create policy "Users can read public profiles" on public.users for select using (true);

-- challenges
create policy "Read public challenges" on public.challenges for select using (visibility = 'public');
create policy "Creator can read own private challenges" on public.challenges for select using (created_by = auth.uid());
create policy "Premium users can create challenges" on public.challenges for insert with check (
  exists (select 1 from public.users where id = auth.uid() and 'premium' = any(roles))
);

-- runs
create policy "Users manage own runs" on public.runs for all using (user_id = auth.uid());
create policy "Read public runs" on public.runs for select using (visibility = 'public');

-- checkins
create policy "Manage own checkins via run" on public.checkins for all using (
  exists (select 1 from public.runs where id = run_id and user_id = auth.uid())
);
create policy "Read checkins of public/own runs" on public.checkins for select using (
  exists (select 1 from public.runs where id = run_id and (visibility = 'public' or user_id = auth.uid()))
);

-- bets
create policy "Users manage own bets" on public.bets for all using (bettor_id = auth.uid());
create policy "Read bets on public/own runs" on public.bets for select using (
  exists (select 1 from public.runs where id = run_id and (visibility = 'public' or user_id = auth.uid()))
);

-- stakes
create policy "Read all stakes" on public.stakes for select using (true);
create policy "Premium users create stakes" on public.stakes for insert with check (
  exists (select 1 from public.users where id = auth.uid() and 'premium' = any(roles))
);

-- notifications
create policy "Manage own notifications" on public.notifications for all using (user_id = auth.uid());

-- follows
create policy "Manage own follows" on public.follows for all using (follower_id = auth.uid());
create policy "Read own follows" on public.follows for select using (follower_id = auth.uid() or followed_id = auth.uid());

-- dismissed_challenges
create policy "Manage own dismissed" on public.dismissed_challenges for all using (user_id = auth.uid());
