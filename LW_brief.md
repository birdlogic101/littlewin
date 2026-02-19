# LW_brief.md

```markdown
# Littlewin — Brief
aka LW_brief.md

## Mission
Build a mobile app that makes daily habits easy to stick to by using **streaks + social visibility + symbolic bets**.

## Target user (who this is for)
Busy people who want accountability and a simple, motivating habit loop; they do not want complex planning, spreadsheets, or heavy community features.

## Product promise (what the user gets)
In under 30 seconds, a user can:
1) join an existing public challenge,
2) create a challenge (only if they are a premium user),
3) do a daily check in on an ongoing run
4) optionally bet on themselves or others,
5) view progress for themselves or the people they follow.

## Current phase
**MLP (Minimum Lovable Product)**: ship a cohesive core loop with delightful feedback, not a feature-rich platform.

## Core loop (must stay intact)
Explore → Join challenge (start run) → Daily check-in → Streak grows → Bets resolve → Scores → Repeat.

## Scope (IN)
- Runs with daily check-ins and streaks
- Explore feed for discovering public challenge runs (ongoing or completed)
- Create a challenge flow screen (for premium users).
- Challenges are created by admins or premium users. Challenges are reusable templates; runs are per-user.
- Symbolic bets (including self-bets)
- Scores defined as highest final streaks reached on completed runs. A run completes automatically on first missed day
- Record defines as the highest score achieved by a user on a given challenge
- Lightweight social: following + viewing runs
- Notifications needed to support the loop (bet outcomes + reminders)
- Basic profile (username + random preset avatar)
- Premium is assumed to be an existing user flag; acquisition and pricing are out of scope for MLP.

## Scope (OUT) — do not design or build now
- Real money, payments, wallets, gambling-like mechanics
- Complex habit planning (calendars, schedules, custom routines, coaching)
- Messaging/DMs, group chats, comment threads
- Team challenges, leagues, tournaments, leaderboards beyond basic karma
- Content creation tools, long posts, feeds of text/media
- Marketplace, creators, monetization systems (except “future-ready” notes)
- Multi-frequency habits (weekly/monthly) unless explicitly requested
- Deep social graphs (mutual friends, recommendations, etc.)

## Success criteria for MLP (definition of done)
- A first-time user can complete the core loop with minimal friction:
  - join a challenge
  - check in
  - place a bet (on another user's run or self-betting)
  - receive and act on a bet outcome notification
  - view their score/history
- The experience feels “fun but calm” (light gamification, not chaotic).

## Decision rules (how to avoid drift)
- Prefer the smallest feature that makes the core loop work end-to-end.
- Prefer defaults over configuration.
- When unsure, ask: “Does this directly strengthen the loop?” If not, drop it.

## Working rules for agents
- Treat this Brief as the scope boundary.
- LW_constraints.md contains non-negotiables; follow it.
- LW_suggestions.md contains flexible direction; use it only if helpful.
- If you must invent details, make the smallest assumption and flag it.
```