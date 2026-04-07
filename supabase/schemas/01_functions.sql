-- =============================================================================
-- 01_functions.sql
-- Consolidated RPC functions for Littlewin.
-- WARNING = This file is exactly the file that is in Supabase. Every modification must be updated in Supabase.
-- =============================================================================

-- 1. get_explore_feed
-- -----------------------------------------------------------------------------
-- =============================================================================
-- get_explore_feed(p_user_id uuid, p_limit int, p_offset int)
-- =============================================================================
-- Fetches public runs for the Explore screen in a specific priority order.
-- =============================================================================

drop function if exists public.get_explore_feed(uuid, int, int);

create or replace function public.get_explore_feed(
  p_user_id uuid,
  p_limit int default 5,
  p_offset int default 0
)
returns table (
  run_id uuid,
  challenge_id uuid,
  challenge_title text,
  challenge_slug text,
  user_id uuid,
  username text,
  avatar_id int,
  current_streak int,
  recent_bet_count int,
  is_completed boolean,
  image_url text,
  challenge_description text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Return P1-P3 content (respects dismissals).
  -- P1: Followed users (Always show).
  -- P2: Strangers (Hide if already joined).
  -- P3: Community Challenges (Hide if already joined).
  return query
  with followed_ongoing as (
    select r.id, r.challenge_id, c.title, c.slug, r.user_id, u.username, u.avatar_id, r.current_streak, r.recent_bet_count, false as is_completed, r.created_at as recency, 1 as priority, c.image_asset, c.description
    from public.runs r
    join public.challenges c on r.challenge_id = c.id
    join public.users u on r.user_id = u.id
    join public.follows f on f.followed_id = r.user_id
    where f.follower_id = p_user_id
      and r.status = 'ongoing'
      and r.user_id != p_user_id
      and r.visibility = 'public'
      and not exists (select 1 from public.dismissed_runs dr where dr.user_id = p_user_id and dr.run_id = r.id and dr.expires_at > now())
      -- Hide if user already has an ongoing or completed run for this challenge
      and not exists (select 1 from public.runs r2 where r2.user_id = p_user_id and r2.challenge_id = r.challenge_id)
  ),
  unfollowed_ongoing as (
    select r.id, r.challenge_id, c.title, c.slug, r.user_id, u.username, u.avatar_id, r.current_streak, r.recent_bet_count, false as is_completed, r.created_at as recency, 2 as priority, c.image_asset, c.description
    from public.runs r
    join public.challenges c on r.challenge_id = c.id
    join public.users u on r.user_id = u.id
    left join public.follows f on f.followed_id = r.user_id and f.follower_id = p_user_id
    where f.id is null
      and r.status = 'ongoing'
      and r.user_id != p_user_id
      and r.visibility = 'public'
      and u.username != 'challenger0'
      and not exists (select 1 from public.dismissed_runs dr where dr.user_id = p_user_id and dr.run_id = r.id and dr.expires_at > now())
      -- Hide if user already has an ongoing or completed run for this challenge
      and not exists (select 1 from public.runs r2 where r2.user_id = p_user_id and r2.challenge_id = r.challenge_id)
  ),
  -- P3: challenger0 runs (Community Challenges)
  c0_runs as (
    select r.id, r.challenge_id, c.title, c.slug, r.user_id, u.username, u.avatar_id, 1 as current_streak, r.recent_bet_count, true as is_completed, r.created_at as recency, 3 as priority, c.image_asset, c.description
    from public.runs r
    join public.challenges c on r.challenge_id = c.id
    join public.users u on r.user_id = u.id
    where u.username = 'challenger0'
      and c.created_by is null
      and (r.user_id != p_user_id or p_user_id is null)
      -- Hide if user already has an ongoing or completed run for this challenge
      and not exists (select 1 from public.runs r2 where r2.user_id = p_user_id and r2.challenge_id = r.challenge_id)
  ),
  unified as (
    select * from followed_ongoing
    union all
    select * from unfollowed_ongoing
    union all
    select * from c0_runs
  ),
  distinct_challenges as (
    select distinct on (u.challenge_id) u.*
    from unified u
    order by u.challenge_id, u.priority asc, u.recency desc
  )
  select
    d.id::uuid as run_id,
    d.challenge_id::uuid,
    d.title::text as challenge_title,
    d.slug::text as challenge_slug,
    d.user_id::uuid,
    d.username::text,
    d.avatar_id::int,
    d.current_streak::int,
    d.recent_bet_count::int,
    d.is_completed::boolean,
    coalesce(d.image_asset, 'assets/pictures/challenge_default_1080.jpg')::text as image_url,
    d.description::text as challenge_description
  from distinct_challenges d
  order by d.priority asc, d.recency desc
  limit p_limit offset p_offset;
end;
$$;

grant execute on function public.get_explore_feed(uuid, int, int) to authenticated, anon;


-- 2. settle_runs
-- -----------------------------------------------------------------------------
-- Idempotent function that closes any ongoing run where the owner missed a
-- check-in deadline, then resolves all pending bets on those runs.
--
-- Called by:
--   1. The Flutter app on every cold-start / resume (via Supabase RPC).
--   2. The pg_cron job nightly at 00:05 UTC — handles inactive users whose
--      app was never opened.
--
-- Idempotency guarantees:
--   • Runs already status='completed' are never touched (WHERE status='ongoing').
--   • Bet resolution uses WHERE status='pending' and updates both status + timestamp.
--   • pg_cron firing twice on the same day is safe.
--
-- Day-1 rule (mirrors client-side logic in RunsRepository):
--   A run that started TODAY is never settled — the user's first check-in
--   window is still open.
--
-- Security:
--   SECURITY DEFINER so the pg_cron job (postgres role) can execute it without
--   needing RLS bypass on the calling role.
--   GRANT to 'authenticated' so the Flutter client can call it via RPC.
-- -----------------------------------------------------------------------------

drop function if exists public.settle_runs(date);
create or replace function public.settle_runs(today_utc date)
returns table(settled_run_id uuid, final_score int)
language plpgsql
security definer
set search_path = public
as $$
declare
  -- Grace window: we only settle runs that missed "yesterday" if it is currently 
  -- past 4 AM UTC of today.
  v_effective_today DATE := (NOW() AT TIME ZONE 'UTC' - interval '4 hours')::DATE;
  v_yesterday_utc date := v_effective_today - interval '1 day';
  r             record;
begin
  -- ── 1. Find and settle all runs that missed yesterday's deadline ────────────

  for r in
    select
      runs.id          as run_id,
      runs.user_id,
      runs.challenge_id,
      runs.current_streak
    from public.runs
    where runs.status = 'ongoing'
      -- Day-1 rule: never settle a run that started on or after the effective today
      and runs.start_date < v_effective_today
      -- Missed rule: no check-in record for effective yesterday
      and not exists (
        select 1
        from public.checkins
        where checkins.run_id  = runs.id
          and checkins.check_in_day_utc = v_yesterday_utc
      )
  loop
    -- Mark run as completed
    update public.runs
    set
      status      = 'completed',
      final_score = r.current_streak,
      updated_at  = now()
    where id = r.run_id
      and status = 'ongoing';   -- guard: never double-complete

    -- ── 2. Resolve pending bets on this run ───────────────────────────────────

    -- Bets where the target streak was reached → WON
    update public.bets
    set
      status     = 'won',
      won_at     = now(),
      updated_at = now()
    where run_id = r.run_id
      and status = 'pending'
      and target_streak <= r.current_streak;

    -- Bets where the target streak was NOT reached → LOST
    update public.bets
    set
      status     = 'lost',
      lost_at    = now(),
      updated_at = now()
    where run_id = r.run_id
      and status = 'pending'
      and target_streak > r.current_streak;

    -- ── 2b. Notify bettors ───────────────────────────────────────────────────

    -- Notify Winners
    insert into public.notifications (user_id, message, type, deep_link, unique_hash)
    select 
      b.bettor_id,
      'You won a ' || coalesce(b.custom_stake_title, s.title, 'Reward') || '! ' || u_runner.username || ' reached Day ' || b.target_streak || '.',
      'bet_won',
      '/records',
      'bet_won_' || b.id
    from public.bets b
    join public.runs run on b.run_id = run.id
    join public.challenges c on run.challenge_id = c.id
    join public.users u_runner on u_runner.id = run.user_id
    left join public.stakes s on s.id = b.stake_id
    where b.run_id = r.run_id 
      and b.status = 'won' 
      and b.won_at >= now() - interval '1 minute' -- only just resolved
    on conflict (unique_hash) do nothing;

    -- Notify Losers
    insert into public.notifications (user_id, message, type, deep_link, unique_hash)
    select 
      b.bettor_id,
      'Bet lost: ' || u_runner.username || ' ended at Day ' || r.current_streak || '.',
      'bet_lost',
      '/records',
      'bet_lost_' || b.id
    from public.bets b
    join public.runs run on b.run_id = run.id
    join public.challenges c on run.challenge_id = c.id
    join public.users u_runner on u_runner.id = run.user_id
    where b.run_id = r.run_id 
      and b.status = 'lost' 
      and b.lost_at >= now() - interval '1 minute'
    on conflict (unique_hash) do nothing;

    -- ── 3. Decrement challenge participant count ───────────────────────────────

    update public.challenges
    set current_participant_count = greatest(0, current_participant_count - 1)
    where id = r.challenge_id;

    -- Return each settled run for logging / debugging
    settled_run_id := r.run_id;
    final_score    := r.current_streak;
    return next;
  end loop;
end;
$$;

-- Grant to authenticated so the Flutter app can call it via supabase.rpc()
grant execute on function public.settle_runs(date) to authenticated;

-- =============================================================================
-- pg_cron: Nightly job at 00:05 UTC
-- =============================================================================
-- Runs settle_runs for users who never opened the app that day.
-- Runs 5 minutes after midnight to ensure all UTC-day check-ins have landed.
--
-- To verify the job was scheduled:
--   select * from cron.job;
--
-- To unschedule:
--   select cron.unschedule('settle-runs-nightly');
-- =============================================================================

select cron.schedule(
  'settle-runs-nightly',
  '5 0 * * *',
  $$ select public.settle_runs((now() at time zone 'UTC')::date); $$
);


-- 3. increment_participant_count
-- -----------------------------------------------------------------------------
-- Safely increment the participant count and total runs count for a challenge
-- cid: The UUID of the challenge to update.
drop function if exists public.increment_participant_count(uuid);
CREATE OR REPLACE FUNCTION public.increment_participant_count(cid UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.challenges
  SET 
    current_participant_count = current_participant_count + 1,
    total_runs_count = total_runs_count + 1
  WHERE id = cid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_participant_count(UUID) TO authenticated;


-- 4. perform_checkin
-- -----------------------------------------------------------------------------
-- Atomic function to record a check-in, update streak, and settle won bets.
-- p_run_id: The UUID of the run to check into.
-- p_day_utc: The UTC day the client intended to check into.
drop function if exists public.perform_checkin(uuid);
drop function if exists public.perform_checkin(uuid, date);
CREATE OR REPLACE FUNCTION public.perform_checkin(p_run_id UUID, p_day_utc DATE)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_streak INT;
  v_today DATE := (NOW() AT TIME ZONE 'UTC')::DATE;
  -- Grace window: if it's before 4 AM UTC, we are more lenient with "yesterday's" missed window.
  v_effective_today DATE := (NOW() AT TIME ZONE 'UTC' - interval '4 hours')::DATE;
  v_won_bets JSON;
BEGIN
  -- 0. Validation: Ensure the run is still ongoing and the streak hasn't expired.
  -- A streak is expired if the user missed their last check-in window (plus grace).
  IF EXISTS (
    SELECT 1 FROM public.runs r
    WHERE r.id = p_run_id
      AND r.status = 'ongoing'
      AND (
        -- Expired if last check-in was before the effective "yesterday"
        (r.last_checkin_day IS NOT NULL AND r.last_checkin_day < v_effective_today - interval '1 day')
        OR
        -- Expired if started before effective "yesterday" and never checked in
        (r.last_checkin_day IS NULL AND r.start_date < v_effective_today - interval '1 day')
      )
  ) THEN
    RAISE EXCEPTION 'STREAK_EXPIRED';
  END IF;

  -- 1. Insert check-in record (authoritatively uses server's UTC day to avoid clock skew issues)
  -- If p_day_utc was slightly off (e.g. 23:59 vs 00:01), the server's day wins.
  INSERT INTO public.checkins (run_id, check_in_day_utc)
  VALUES (p_run_id, v_today);

  -- 2. Increment streak and update timestamp in runs table.
  UPDATE public.runs
  SET 
    current_streak = current_streak + 1,
    last_checkin_day = v_today,
    updated_at = NOW()
  WHERE id = p_run_id
  RETURNING current_streak INTO v_new_streak;

  -- 3. Resolve and collect any bets that were won by reaching this new streak.
  WITH settled_bets AS (
    UPDATE public.bets
    SET 
      status = 'won',
      won_at = NOW(),
      updated_at = NOW(),
      notified_in_app = is_self_bet
    WHERE run_id = p_run_id
      AND status = 'pending'
      AND target_streak <= v_new_streak
    RETURNING 
      id, 
      bettor_id, 
      is_self_bet,
      target_streak,
      stake_id,
      custom_stake_title
  )
  SELECT json_agg(
    json_build_object(
      'id', sb.id,
      'bettor_id', sb.bettor_id,
      'is_self_bet', sb.is_self_bet,
      'target_streak', sb.target_streak,
      'stake_title', coalesce(sb.custom_stake_title, s.title),
      'stake_category', s.category,
      'bettor_username', u.username,
      'bettor_avatar_id', u.avatar_id
    )
  ) INTO v_won_bets
  FROM settled_bets sb
  LEFT JOIN public.stakes s ON sb.stake_id = s.id
  LEFT JOIN public.users u ON sb.bettor_id = u.id;

  -- 3b. Create notifications for won bets (Bettor Impact)
  INSERT INTO public.notifications (user_id, message, type, deep_link, unique_hash)
  SELECT 
    b.bettor_id,
    'You won a ' || coalesce(b.custom_stake_title, s.title, 'Reward') || '! ' || u_runner.username || ' reached Day ' || b.target_streak || '.',
    'bet_won',
    '/records',
    'bet_won_' || b.id
  FROM public.bets b
  JOIN public.runs r ON r.id = p_run_id
  JOIN public.users u_runner ON u_runner.id = r.user_id
  LEFT JOIN public.stakes s ON s.id = b.stake_id
  WHERE b.run_id = p_run_id 
    AND b.status = 'won'
    AND b.target_streak <= v_new_streak
    AND b.won_at >= NOW() - interval '1 minute'
  ON CONFLICT (unique_hash) DO NOTHING;

  -- 4. Return summary JSON
  RETURN json_build_object(
    'new_streak', v_new_streak,
    'triggered_bets', COALESCE(v_won_bets, '[]'::JSON)
  );

EXCEPTION WHEN UNIQUE_VIOLATION THEN
  -- Conflict Handling: If already checked in today (e.g. network retry), 
  -- return the current state INCLUDING any bets won in the last 10 mins.
  -- This ensures the client still gets the celebration even on a retry.
  SELECT current_streak INTO v_new_streak FROM public.runs WHERE id = p_run_id;
  
  SELECT json_agg(
    json_build_object(
      'id', b.id,
      'bettor_id', b.bettor_id,
      'is_self_bet', b.is_self_bet,
      'target_streak', b.target_streak,
      'stake_title', coalesce(b.custom_stake_title, s.title),
      'stake_category', s.category,
      'bettor_username', u.username,
      'bettor_avatar_id', u.avatar_id
    )
  ) INTO v_won_bets
  FROM public.bets b
  LEFT JOIN public.stakes s ON b.stake_id = s.id
  LEFT JOIN public.users u ON b.bettor_id = u.id
  WHERE b.run_id = p_run_id
    AND b.status = 'won'
    AND b.won_at >= NOW() - interval '10 minutes';

  RETURN json_build_object(
    'new_streak', v_new_streak,
    'triggered_bets', COALESCE(v_won_bets, '[]'::JSON)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.perform_checkin(UUID, DATE) TO authenticated;
-- 5. create_challenge
-- -----------------------------------------------------------------------------
drop function if exists public.create_challenge(text, text, text, text);
drop function if exists public.create_challenge(text, text, text, text, text);
create or replace function public.create_challenge(
  p_title text,
  p_description text,
  p_visibility text,
  p_slug text,
  p_image_asset text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_challenge_id uuid;
  v_run_id uuid;
  v_today date := (now() at time zone 'UTC')::date;
begin
  -- Only premium users may create challenges (enforced in RLS too)
  if not exists (
    select 1 from public.users where id = auth.uid() and 'premium' = any(roles)
  ) then
    raise exception 'NOT_PREMIUM';
  end if;

  insert into public.challenges (title, description, slug, visibility, created_by, image_asset)
  values (p_title, p_description, p_slug, p_visibility::public.visibility_type, auth.uid(), p_image_asset)
  returning id into v_challenge_id;

  insert into public.runs (challenge_id, user_id, start_date, current_streak, status, visibility)
  values (v_challenge_id, auth.uid(), v_today, 0, 'ongoing', p_visibility::public.visibility_type)
  returning id into v_run_id;

  update public.challenges
  set current_participant_count = 1, total_runs_count = 1
  where id = v_challenge_id;

  return json_build_object('challenge_id', v_challenge_id, 'run_id', v_run_id);
end;
$$;

grant execute on function public.create_challenge(text, text, text, text, text) to authenticated;


-- 5b. create_custom_stake
-- -----------------------------------------------------------------------------
-- Atomic creation of a custom stake for a premium user.
drop function if exists public.create_custom_stake(text);
create or replace function public.create_custom_stake(
  p_title text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stake_id uuid;
  v_result json;
begin
  -- Only premium users may create stakes (enforced in RLS too)
  if not exists (
    select 1 from public.users where id = auth.uid() and 'premium' = any(roles)
  ) then
    raise exception 'NOT_PREMIUM';
  end if;

  insert into public.stakes (title, category, created_by)
  values (p_title, 'custom'::public.stake_category, auth.uid())
  returning id into v_stake_id;

  select json_build_object(
    'id', id,
    'title', title,
    'category', category,
    'emoji', emoji
  ) into v_result
  from public.stakes
  where id = v_stake_id;

  return v_result;
end;
$$;

grant execute on function public.create_custom_stake(text) to authenticated;


-- 6. get_followed_users
-- -----------------------------------------------------------------------------
-- Returns users followed by the current user, including their ongoing run count.
drop function if exists public.get_followed_users();
create or replace function public.get_followed_users()
returns table (
  user_id uuid,
  username text,
  avatar_id int,
  ongoing_count bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select 
    u.id as user_id,
    u.username::text,
    u.avatar_id,
    count(r.id) as ongoing_count
  from public.follows f
  join public.users u on f.followed_id = u.id
  left join public.runs r on r.user_id = u.id and r.status = 'ongoing'
  where f.follower_id = auth.uid()
  group by u.id, u.username, u.avatar_id;
end;
$$;

grant execute on function public.get_followed_users() to authenticated;


-- 7. place_bet
-- -----------------------------------------------------------------------------
-- Atomic betting with validation. Returns JSON matching BetModel.fromJson.
-- -----------------------------------------------------------------------------
drop function if exists public.place_bet(uuid, int, uuid, boolean);
drop function if exists public.place_bet(uuid, int, uuid, boolean, text);
create or replace function public.place_bet(
  p_run_id uuid,
  p_target_streak int,
  p_stake_id uuid default null,
  p_is_self_bet boolean default false,
  p_custom_stake_title text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bet_id uuid;
  v_current_streak int;
  v_run_status public.run_status;
  v_result json;
  v_bet_count_run int;
  v_bet_count_day int;
  v_runner_id uuid;
  v_bettor_name text;
  v_stake_title text;
begin
  -- 1. Validation: Run existence and status
  select user_id, current_streak, status 
  into v_runner_id, v_current_streak, v_run_status
  from public.runs 
  where id = p_run_id;

  if v_run_status is null then
    raise exception 'RUN_NOT_FOUND';
  end if;

  if v_run_status != 'ongoing' then
    raise exception 'RUN_NOT_ACTIVE';
  end if;

  -- 2. Validation: Streak logic
  if p_target_streak <= v_current_streak then
    raise exception 'STREAK_TOO_LOW';
  end if;

  if p_target_streak > v_current_streak + 90 then
    raise exception 'STREAK_TOO_HIGH';
  end if;

  -- 3. Validation: Limits (Anti-spam/Business rules)
  
  -- Max bets per run (e.g., 50)
  select count(*) into v_bet_count_run
  from public.bets
  where run_id = p_run_id;

  if v_bet_count_run >= 50 then
    raise exception 'MAX_BETS_PER_RUN';
  end if;

  -- Max bets per user per day (e.g., 20)
  select count(*) into v_bet_count_day
  from public.bets
  where bettor_id = auth.uid()
    and created_at >= (now() at time zone 'UTC')::date;

  if v_bet_count_day >= 20 then
    raise exception 'MAX_BETS_PER_DAY';
  end if;

  -- 4. Insert
  insert into public.bets (run_id, bettor_id, target_streak, stake_id, is_self_bet, custom_stake_title)
  values (p_run_id, auth.uid(), p_target_streak, p_stake_id, p_is_self_bet, p_custom_stake_title)
  returning id into v_bet_id;

  -- 5. Update run's recent_bet_count for feed priority
  update public.runs
  set recent_bet_count = recent_bet_count + 1,
      updated_at = now()
  where id = p_run_id;

  -- 6. Return joined record for BetModel.fromJson
  select json_build_object(
    'id', b.id,
    'run_id', b.run_id,
    'bettor_id', b.bettor_id,
    'target_streak', b.target_streak,
    'stake_id', b.stake_id,
    'status', b.status,
    'is_self_bet', b.is_self_bet,
    'created_at', b.created_at,
    'custom_stake_title', b.custom_stake_title,
    'users', json_build_object('username', u.username),
    'stakes', case when s.id is not null then json_build_object('title', s.title) else null end
  ) into v_result
  from public.bets b
  left join public.users u on b.bettor_id = u.id
  left join public.stakes s on b.stake_id = s.id
  where b.id = v_bet_id;

  -- 7. Notify Runner (Social Awareness)
  if v_runner_id != auth.uid() then
    select username into v_bettor_name from public.users where id = auth.uid();
    -- Use custom title if provided, otherwise fetch stake title
    v_stake_title := coalesce(p_custom_stake_title, (select title from public.stakes where id = p_stake_id));
    
    insert into public.notifications (user_id, message, type, deep_link, unique_hash)
    values (
      v_runner_id,
      coalesce(v_bettor_name, 'Someone') || ' bet a ' || coalesce(v_stake_title, 'Reward') || ' that you''ll reach Day ' || p_target_streak || '!',
      'bet_received',
      '/runs/' || p_run_id,
      'bet_received_' || v_bet_id
    )
    on conflict (unique_hash) do nothing;
  end if;

  return v_result;
end;
$$;

grant execute on function public.place_bet(uuid, int, uuid, boolean, text) to authenticated;


-- 8. grant_premium
-- -----------------------------------------------------------------------------
-- Upgrades a user to premium role.
drop function if exists public.grant_premium(uuid);
create or replace function public.grant_premium(uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
  set roles = array_append(roles, 'premium')
  where id = uid 
    and not ('premium' = any(roles));
end;
$$;

grant execute on function public.grant_premium(uuid) to authenticated;


-- 9. join_challenge
-- -----------------------------------------------------------------------------
-- Atomic join: inserts run and increments participant count.
drop function if exists public.join_challenge(uuid);
create or replace function public.join_challenge(p_challenge_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run_id uuid;
  v_today date := (now() at time zone 'UTC')::date;
begin
  -- Don't allow multiple ongoing runs for the same challenge
  if exists (
    select 1 from public.runs 
    where user_id = auth.uid() 
      and challenge_id = p_challenge_id 
      and status = 'ongoing'
  ) then
    raise exception 'ALREADY_JOINED';
  end if;

  -- Create the run
  insert into public.runs (challenge_id, user_id, start_date, status, current_streak, visibility)
  values (p_challenge_id, auth.uid(), v_today, 'ongoing', 0, 'public'::public.visibility_type)
  returning id into v_run_id;

  -- Update participant counts
  update public.challenges
  set 
    current_participant_count = current_participant_count + 1,
    total_runs_count = total_runs_count + 1
  where id = p_challenge_id;

  return v_run_id;
end;
$$;

grant execute on function public.join_challenge(uuid) to authenticated;


-- 10. get_unseen_won_bets
-- -----------------------------------------------------------------------------
drop function if exists public.get_unseen_won_bets();
create or replace function public.get_unseen_won_bets()
returns json
language plpgsql
security definer
set search_path = public
as $$
begin
  return (
    select json_agg(
      json_build_object(
        'bet_id', b.id,
        'run_id', b.run_id,
        'target_streak', b.target_streak,
        'stake_title', coalesce(b.custom_stake_title, s.title),
        'stake_category', s.category,
        'challenge_title', c.title,
        'runner_username', u_runner.username,
        'runner_avatar_id', u_runner.avatar_id
      )
    )
    from public.bets b
    join public.runs r on b.run_id = r.id
    join public.challenges c on r.challenge_id = c.id
    join public.users u_runner on r.user_id = u_runner.id
    left join public.stakes s on b.stake_id = s.id
    where b.bettor_id = auth.uid()
      and b.status = 'won'
      and b.notified_in_app = false
  );
end;
$$;

grant execute on function public.get_unseen_won_bets() to authenticated;


-- 11. acknowledge_won_bets
-- -----------------------------------------------------------------------------
drop function if exists public.acknowledge_won_bets(uuid[]);
create or replace function public.acknowledge_won_bets(p_bet_ids uuid[])
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.bets
  set notified_in_app = true
  where id = any(p_bet_ids)
    and bettor_id = auth.uid();
end;
$$;

grant execute on function public.acknowledge_won_bets(uuid[]) to authenticated;


-- 12. push_notifier_trigger
-- -----------------------------------------------------------------------------
-- This trigger invokes the 'push-notifier' Edge Function whenever a new 
-- record is inserted into the notifications table.
-- Requires the 'pg_net' extension.
-- -----------------------------------------------------------------------------

create or replace function public.handle_new_notification()
returns trigger
language plpgsql
security definer
as $$
declare
  v_payload json;
begin
  v_payload := json_build_object('record', row_to_json(new));
  
  -- Invoke the Edge Function via pg_net
  -- Note: The URL assumes the local/hosted Supabase convention.
  -- The auth header uses the SERVICE_ROLE_KEY which must be set in the database vault or passed securely.
  perform net.http_post(
    url := (select value from public.app_config where key = 'PUSH_FUNCTION_URL')::text,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select value from public.app_config where key = 'SERVICE_ROLE_KEY')
    )::jsonb,
    body := v_payload::json
  );
  
  return new;
end;
$$;

-- Note: We only create the trigger if the extension exists and the user has setup the settings.
-- For the walkthrough, we'll provide the manual SQL to enable this once the user has their keys.

-- 12b. Attach the trigger
drop trigger if exists on_notification_created on public.notifications;
create trigger on_notification_created
  after insert on public.notifications
  for each row execute procedure public.handle_new_notification();

-- -----------------------------------------------------------------------------
-- 13. merge_anonymous_account
-- -----------------------------------------------------------------------------
-- Transfers all progress and social data from an old anonymous account to the
-- currently signed-in permanent account (auth.uid()).
-- -----------------------------------------------------------------------------
create or replace function public.merge_anonymous_account(p_anonymous_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  -- Guard: don't merge into self or if no user is authenticated
  if auth.uid() is null or auth.uid() = p_anonymous_id then
    return;
  end if;

  -- 1. Transfer progress: Runs and Checkins
  -- (Checkins cascade via fk or are linked to runs, which we re-assign)
  update public.runs
  set user_id = auth.uid()
  where user_id = p_anonymous_id;

  -- 2. Transfer Bets
  update public.bets
  set bettor_id = auth.uid()
  where bettor_id = p_anonymous_id;

  -- 3. Transfer Social: Follows
  -- As follower
  update public.follows
  set follower_id = auth.uid()
  where follower_id = p_anonymous_id
    and not exists (
      select 1 from public.follows f2 
      where f2.follower_id = auth.uid() and f2.followed_id = public.follows.followed_id
    );
  
  -- As followed (rare for anon, but possible)
  update public.follows
  set followed_id = auth.uid()
  where followed_id = p_anonymous_id
    and not exists (
      select 1 from public.follows f2 
      where f2.followed_id = auth.uid() and f2.follower_id = public.follows.follower_id
    );

  -- 4. Transfer Notifications
  update public.notifications
  set user_id = auth.uid()
  where user_id = p_anonymous_id;

  -- 5. Transfer Dismissals
  update public.dismissed_challenges
  set user_id = auth.uid()
  where user_id = p_anonymous_id
    and not exists (
      select 1 from public.dismissed_challenges d2
      where d2.user_id = auth.uid() and d2.challenge_id = public.dismissed_challenges.challenge_id
    );

  update public.dismissed_runs
  set user_id = auth.uid()
  where user_id = p_anonymous_id
    and not exists (
      select 1 from public.dismissed_runs d2
      where d2.user_id = auth.uid() and d2.run_id = public.dismissed_runs.run_id
    );

  -- 6. Cleanup the old anonymous public profile
  delete from public.users
  where id = p_anonymous_id;
  
  -- Note: we don't delete auth.users(p_anonymous_id) here as we might not have 
  -- permission to manage auth schema from this function.
end;
$$;
