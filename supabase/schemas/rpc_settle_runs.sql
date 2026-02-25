-- =============================================================================
-- settle_runs(today_utc date)
-- =============================================================================
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
-- =============================================================================

create or replace function public.settle_runs(today_utc date)
returns table(settled_run_id uuid, final_score int)
language plpgsql
security definer
set search_path = public
as $$
declare
  yesterday_utc date := today_utc - interval '1 day';
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
      -- Day-1 rule: never settle a run that started today
      and runs.start_date < today_utc
      -- Missed rule: no check-in record for yesterday
      and not exists (
        select 1
        from public.checkins
        where checkins.run_id  = runs.id
          and checkins.check_in_day_utc = yesterday_utc
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
