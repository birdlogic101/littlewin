# LW_constraints.md

```markdown
# Littlewin — Constraints (Non-Negotiable)
aka LW_constraints.md

If anything in this file conflicts with LW_suggestions.md, this file wins.

## 0) Stack & Runtime Requirements
- Mobile app built in Flutter.
- Backend is Supabase (PostgreSQL + Auth + Edge Functions + Storage).
- Notifications use FCM for server-driven notifications; local notifications for reminders.
- Data uses UUID primary keys and UTC timestamps.

## 1) Core Domain Definitions (Code Must Match)
These are the canonical meanings of entities.

- **User**: identified by UUID; anonymous or Google-auth; has `username`, avatar.
- **Challenge**: a daily habit template; can only created by premium users; can be public/private.
- **Run**: a user’s instance of a challenge; has streak; can be public/private; has `status`.
- **Check-in canonical day**: A check-in belongs to a single **UTC day**; the app must enforce **max 1 check-in per run per UTC day**.
- **Stake**: symbolic reward; can only created by premium users.
- **Bet**: placed on a run’s target streak.
- **Follow**: one-way; no consent needed in MVP.
- **Notification**: system alert (bet won, reminders, etc.).
- **Dismissed Challenge**: user-banned challenge; expires after a defined duration.

## 2) Global Limits & Constants
These values must be enforced either in DB constraints, RPC validation, or client validation (prefer server-side).

| Constant | Value |
|---|---|
| Max Runs per User | 99 |
| Max Bets per Day | 99 |
| Max Bets per Run | 99 |
| Max Target Streak | current streak + 90 |
| Username Length | 3–20 chars, unique |
| Challenge Title Length | 3–50 chars |
| Stake Title Length | 3–100 chars |
| Avatar File Size | <= 500KB |
| Background File Size | <= 500KB |
| Cache TTL | 48h |
| Dismissal Expiration | 14 days |
| Notification TTL | 7 days |
| Explore Fetch Limit | 5 |
| Polling Fetch Limit | 5 |
| Run Visibility | public, private |
| Bet Statuses | pending, won, lost |
| Notification Types | bet_won, bet_lost | checkin_reminder |
| Notification Statuses | pending, read |
| Retry Delays | 500ms, 1s, 2s |
| App Storage Limit | < 200MB |

## 3) Data Integrity & Persistence Rules
- Timestamps stored in UTC; presented locally.
- Conflict resolution uses `updated_at` and last-write-wins.
- Realtime is allowed only for `notifications` (user channel).

## 4) Database Schema (Authoritative)
PostgreSQL tables + fields + constraints are authoritative.

### 4.1 users
- Fields:
  - `id` UUID PK
  - `username` varchar(20) UNIQUE
  - `email` varchar(255) NULL
  - `avatar_id` int (1–10) NULL
  - `roles` varchar(20)[] ('basic', 'premium')
  - `created_at` timestamp
  - `fcm_token` varchar(255) NULL
  - `anonymous_id` varchar(255) UNIQUE NULL
- Indexes: `username` UNIQUE, `fcm_token`

### 4.2 challenges
- Fields:
  - `id` UUID PK
  - `title` varchar(50)
  - `description` varchar(500) NULL
  - `slug` varchar(60) UNIQUE
  - `created_at` timestamp
  - `created_by` UUID NULL
  - `visibility` varchar(20)[] = ('public', 'private')
  - `current_participant_count` int default 0
  - `total_runs_count` int default 0
  - `top_streak` int default 0
- Indexes: `created_at`, `slug`

### 4.3 runs
- Fields:
  - `id` UUID PK
  - `challenge_id` UUID FK
  - `user_id` UUID FK
  - `visibility` varchar(20)[] = ('public', 'private')
  - `start_date` date (UTC day; the first eligible check-in day)
  - `current_streak` int default 0
  - `final_score` int NULL
  - `status` varchar(20) ('ongoing'|'completed')
  - `created_at` timestamp
  - `updated_at` timestamp
  - `recent_bet_count` int default 0
- Indexes: `user_id`, `status`, `challenge_id`, `updated_at`, `(user_id, status, updated_at)`

### 4.4 checkins
- Fields: 
	- `id` UUID PK
	- `run_id` UUID FK
	- `check_in_day_utc` date NOT NULL
	- `updated_at` timestamp
- Constraints:
  - UNIQUE (`run_id`, `check_in_day_utc`)	
- Indexes: 
	- `run_id`
	- `check_in_day_utc`
- Notes:
  - A check-in row represents completion for `check_in_day_utc`; `updated_at` tracks the last time that day's check-in was recorded/modified.

### 4.5 stakes
- Fields: 
	- `id` UUID PK
	- `title` varchar(100)
	- `category` varchar(20) ('plan'|'gift'|'custom')
	- `created_at` timestamp
	- `created_by` UUID NULL

### 4.6 bets
- Fields:
  - `id` UUID PK
  - `run_id` UUID FK
  - `bettor_id` UUID FK
  - `target_streak` int
  - `stake_id` UUID NULL
  - `status` varchar(20)
  - `created_at` timestamp
  - `won_at` timestamp NULL
  - `lost_at` timestamp NULL
  - `updated_at` timestamp
  - `is_self_bet` boolean default false
- Constraints:
  - `status` IN (pending, won, lost)
- Indexes: `run_id`, `status`, `target_streak`, `updated_at`, `bettor_id`, `(run_id, bettor_id)`

### 4.7 notifications
- Fields: `id` UUID PK, `user_id` UUID FK, `message` varchar(255), `type` varchar(20), `deep_link` varchar(255) NULL, `unique_hash` varchar(64) UNIQUE, `created_at` timestamp, `read_at` timestamp NULL, `status` varchar(20)
- Indexes: `user_id`, `created_at`, `type`, `unique_hash` UNIQUE

### 4.8 follows
- Fields: `id` UUID PK, `follower_id` UUID FK, `followed_id` UUID FK, `created_at` timestamp
- Indexes: `follower_id`, `followed_id`, `(follower_id, followed_id)` UNIQUE

### 4.9 dismissed_challenges
- Fields: `id` UUID PK, `user_id` UUID FK, `challenge_id` UUID FK, `created_at` timestamp, `expires_at` timestamp
- Indexes: `user_id`, `challenge_id`, `(user_id, challenge_id)` UNIQUE

## 5) RLS Policies (Authoritative)
- users: update own (`id=auth.uid()`); read public (`true`); hide email
- challenges: read if visibility='public' OR created_by = auth.uid(); create only for premium users
- runs: manage own; read if public or own
- checkins: manage if owns run; read if run public or own
- bets: manage own; read if run public or own
- stakes: read all; create only for premium users
- notifications: manage own
- follows: manage own; read own relationships
- dismissed_challenges: manage own

## 6) Server-Side Rules (Must Hold)
### Check-in validity
- Check-in window is **current UTC day** (not local day). Display locally, validate in UTC.

### Bet validity
- Run must be ongoing.
- `target_streak > current_streak`
- `target_streak <= current_streak + 90`
- Self-bets allowed.

### Run lifecycle (authoritative)
- A **Run** is `ongoing` until the first missed **UTC day** after its start.
- Define `start_day_utc = runs.start_date` (interpreted as a UTC date).
- A run is considered **missed** when:
  - `today_utc_day > start_day_utc`, and
  - there exists at least one UTC day `d` in `[start_day_utc, today_utc_day - 1]` with **no** check-in row in `checkins` for that run where `check_in_day_utc = d`.
- When a run becomes missed, the server must:
  1) set `runs.status = 'completed'`
  2) set `runs.final_score = runs.current_streak` (see scoring rules below)
  3) set `runs.updated_at = now()` (UTC)
  4) resolve all `bets` on that run that are still `pending` (see Bet resolution)

### Scoring rules (authoritative)
- `runs.current_streak` = count of **consecutive** UTC days with check-ins ending at the most recent checked-in UTC day.
- `runs.final_score` is set **once** when the run is completed and equals the final `current_streak` at completion time.
- A run’s score does not change after completion.

### Bet resolution (authoritative)
- A bet is created with `status='pending'`.
- A `pending` bet becomes `won` immediately when `runs.current_streak >= bets.target_streak` (after a valid check-in updates streak).
- A `pending` bet becomes `lost` when the run is completed and `runs.final_score < bets.target_streak`.
- `bets.updated_at` must be updated on any status change; `bets.won_at` is set only when status becomes `won`.

### Where/when the server enforces lifecycle
- The server must enforce run completion and bet settlement via an RPC/Edge Function that is called:
  - after every successful check-in, and
  - on app open (or Explore/Run fetch) for the current user’s ongoing runs (idempotent).
- The function must be idempotent: repeated calls produce the same final state.

### Error handling requirements
- Network retries: 3 attempts with delays 500ms, 1s, 2s.
- Validation errors returned in a consistent code form (e.g., `CHECKIN_INVALID_WINDOW`, bet limit exceeded, run not active, self-bet cannot fulfill).

### Offline behavior
- Must queue pending actions and retry when reconnecting.

```