# LW_suggestions.md

```markdown
# Littlewin — Suggestions (Coding Guidance, Flexible)

This file is guidance. It can evolve. If anything conflicts with
LW_constraints.md, LW_constraints.md wins. If anything conflicts with
LW_brief.md scope, LW_brief.md wins.

## Hard Alignment (Must Match)

Everything below is _guidance_, but it must stay consistent with:

- **Scope boundary** in `LW_brief.md`
- **Non-negotiables** in `LW_constraints.md` (limits, enums, RLS, server rules)

When writing code or naming fields/statuses:

- Use the **exact enums/constants** from constraints (tags, statuses, limits,
  TTLs).
- If suggestions mention a different number/value/name, constraints win.

## Primary Goal for Agents

Help ship the **MLP core loop end-to-end** with the smallest coherent surface
area: Explore → Join → Check-in → (optional) Bet → Notifications → Scores.

When choosing tasks, prioritize:

1. correctness of core loop
2. low friction UX
3. simplicity of implementation
4. performance only as needed to keep the loop smooth

## Defaults to Prefer

- Prefer **defaults over configuration**.
- Prefer **simple UI** over feature completeness.
- Prefer **server-authoritative validation** (RLS + RPC) for anything that can
  be exploited.
- Prefer **small payloads** and minimal queries.
- Prefer **single responsibility** in code: clean boundaries, but avoid
  over-engineering.

## Suggested Architecture (Flexible)

- Use clean-ish layering (data / domain / presentation) if it helps clarity.
- Suggested state management: **flutter_bloc** (BLoC pattern; already in use —
  do not mix with Provider).
- Suggested caching: **Hive** with TTL semantics (add `hive` + `hive_flutter` to
  pubspec).
- Keep dependencies minimal; add only when they remove real complexity.

## Suggested Folder Layout (Flexible)

lib/ ├── main.dart ├── app.dart ├── routes.dart ├── core/ │ ├── theme/
(tokens.dart, components.dart) │ ├── di/ (providers.dart) │ ├── utils/
(logger.dart, navigation_service.dart) │ ├── extensions/ │ └── strings.dart ├──
data/ │ ├── models/ (challenge.dart, run.dart, bet.dart, user.dart, stake.dart,
custom_stake.dart, custom_avatar.dart, checkin.dart, notification.dart,
follow.dart, dismissed_challenge.dart) │ ├── datasources/ │ │ ├── local/
(hive_datasource.dart) │ │ └── remote/ (supabase_client.dart,
auth_datasource.dart) │ └── repositories_impl/ (repository_impl.dart) ├──
domain/ │ ├── repository.dart │ └── usecases/ (browse_challenges.dart,
join_challenge.dart, perform_checkin.dart, complete_run.dart,
get_active_runs.dart, get_completed_runs.dart, place_bet.dart, get_stakes.dart,
anonymous_login.dart, sign_up_and_merge_data.dart, update_profile.dart,
search_users.dart, get_user_runs.dart, follow_user.dart, unfollow_user.dart,
get_followed_users.dart, get_followers.dart, dismiss_challenge.dart,
create_challenge.dart, create_custom_avatar.dart, create_custom_stake.dart,
create_stake.dart) ├── presentation/ │ ├── screens/ (explore_screen.dart,
checkin_screen.dart, records_screen.dart, people_screen.dart,
notifications_drawer.dart, settings_drawer.dart, challenge_details_screen.dart,
run_details_screen.dart, place_bet_modal.dart, user_view_screen.dart) │ ├──
widgets/ (custom_button.dart, explore_run_card.dart, run_streak_tracker.dart,
bet_target_selector.dart, checkin_calendar.dart, notification_item.dart,
user_card.dart, user_run_card.dart, follow_button.dart, score_card.dart,
custom_avatar_upload.dart) │ └── providers/ (auth_provider.dart,
challenge_provider.dart, run_provider.dart, bet_provider.dart,
social_provider.dart, notification_provider.dart, settings_provider.dart) ├──
assets/ │ ├── icons/ (explore.svg, checkin.svg, scores.svg, people.svg,
dismiss.svg, bet.svg, menu_lines.svg, menu_dots.svg, plus.svg, notification.svg,
settings.svg, send.svg, restart.svg, add_contact.svg, streak.svg,
increase_by1.svg, increase_by10.svg, decrease_by1.svg, decrease_by10.svg,
stake_plan.svg, stake_gift.svg) │ ├── avatars/ (avatar_1.png, ...,
avatar_10.png) │ └── misc/ (littlewin_logo.svg, loop_symbol_small.png,
loop_symbol_big.png, confetti.png) └── test/ ├── unit/ (usecases:
perform_checkin_test.dart, place_bet_test.dart, ...) └── integration/ (supabase:
checkin_test.dart, bet_test.dart, ...)

## UX Direction (Not Law)

- Tone: “fun but calm”
- Gamification: light feedback (confetti/chime/badges), no competitive pressure
- Core actions should stay near **1–2 taps** where possible
- Accessibility: WCAG-minded layouts and contrast

## Suggested App Navigation & Screens (MLP)

Suggested shell:

- Bottom tabs: **Explore**, **Check-in**, **Records**, **People**
- Right drawer: **Notifications**, **Settings**

Suggested screens (keep minimal versions first):

- Explore: swipeable feed of public runs
- Create challenge: create a challenge flow only for premium users
- Check-in: list/grid of active runs with one-tap check-in
- Place Bet modal: quick bet creation UI
- Notifications drawer: list + deep-link navigation
- Records: completed runs history + retry/share
- People: user search + follow/unfollow + view profile runs
- Settings: username/avatar + auth + notification toggle

## Suggested UX Behaviors

### Onboarding

- A 4-step carousel explaining: Explore → Join → Check-in → Bet
- Default to anonymous start; prompt to sign in after first meaningful action

### Explore

- What we see: public runs from other users. We do not see our own runs.
  - **Priority 1 (Followed Users)**: Ongoing runs from users you follow.
    - _UX Rule_: Always show these, even if you are already in the challenge.
      This builds community motivation.
    - Ordered by recency and highest streak.
  - **Priority 2 (Discovery)**: Ongoing runs from strangers (non-followed
    users).
    - _UX Rule_: Hide runs for challenges you are already participating in
      (ongoing or completed) to keep discovery fresh.
    - Ordered by recency and highest streak.
  - **Priority 3 (Community Challenges - Fallback)**: Curated runs from system
    user "challenger0".
    - _UX Rule_: These are "starter ideas" for new users.
    - In common language, these are "Community Challenges".
    - Shown as completed at a 1-day streak to look active but accessible.
    - _UX Rule_: Hide runs for challenges you are already participating in
      (ongoing or completed) to keep discovery fresh.
    - **Infinite Fallback**: This category (Community Challenges) cycles
      infinitely. The feed is only empty if the user has joined all these
      challenges.
- **Dismissal**: If a user dismisses a run, hide that challenge for 14 days.
- Fetch in small batches (target 5)
- The experience of going through public challenge runs should work like:
  swiping left dismisses the challenge and swiping right joins the challenge.
  Tapping 'Join' or swiping right adds the run to the user's check-ins without
  switching screens, showing a success confirmation (Soft-Join).
- Tapping 'x' or swiping left dismisses the challenge (expires in 14 days).
- Do not leak private runs via counts, previews, or search results.
- When we join a public challenge, the run that is created is by default set to
  public.

### Create a challenge

- Only premium users can create challenges.
- They can input the following:
  - Title (required)
  - Description (optional)
  - Visibility toggle: by default it is set to public, but this can be toggled
    off. If it is toggled off, the challenge is private. Private challenges are
    only visible to the creator.
- When a user creates a challenge:
  - The image of the challenge is automatically set to challenge_default.jpg
  - The challenge is automatically joined by the creator. This creates a new run
    for the creator.

### Check-in

- One-tap check-in
- Optional milestone moments (7/14/21) with share
- Reminder concept: daily reminder near end-of-day (implementation can vary)

### Bets

- From the explore screen, if we tap on the bet button (the one with the star
  icon) on a run card, it opens the bet modal. This is a bet on the run of the
  person who's doing the run that is displayed.
- From the check-in screen, if we tap on the bet button (the one with the star
  icon) on a run card, it opens the bet modal. This is a self-bet.
- **Self-Bet Invitation**: After a user's _first_ successful check-in on a run
  (where they have no active bets), a dialogue is shown inviting them to place
  their first self-bet.
- When a user places a bet, they can select the streak at which the bet should
  be completed. The default value shown is +7 days from current streak value.
  The maximum value is the streak of 999 days in total.
- When a user places a bet, they can select a stake item. By default, the "plan"
  chip tag is selected with the preset items being: "Coffee Cup", "Brunch
  Invite", "Restaurant Dinner", "Drinks Round", "Cinema Night". We also have a
  chip tag "gift" which can be selected and this one features the preset items:
  "Chocolate Box", "Wine Bottle", "Spa Access", "Massage Session", and "Surprise
  Box". The third chip is a plus icon which is a button to create a custom stake
  (premium feature).
- Bet resolution: when a user checks in and the streak value reached triggers
  the success of a bet placed on that run, a modal is displayed showing the
  success of the bet and the list of stakes won (including from which bettors
  they are from).
  - The bettor also receives a notification of the result of the bet, inviting
    them to fulfill their bet.
  - If a bet is completed (due to a missed check-in), the bettors that had bet
    on a superior streak are also notified of the final streak of the bet. In
    this case, obviously they do not have to fulfill their bet because the
    runner did not achieve the streak they bet on.

### People

1. The "Viral" Journey (New User)

- Target: A friend who doesn't have the app yet.
- Invite: User A taps "Invite to [Habit Name]" \rightarrow Native Share Sheet
  \rightarrow Sends a link: littlew.in/join/UserA.
- The Landing Page: User B clicks the link. A clean, branded page says: "Join
  User A on Littlewin to ..."
- "The Handshake: User B taps "Accept Invite." * System: Copies ref_UserA to
  clipboard + redirects to App/Play Store.
- First Launch: User B installs and signs up via Supabase.
- The Auto-Follow: After onboarding, the app checks the clipboard. It finds
  ref_UserA, sends an insert to your follows table, and shows a celebration:
  "You are now following User A!"

2. The "Direct" Journey (Existing User)

- Target: A friend who already has the app, but you aren't connected.
- Deep Link Trigger: User B clicks the same link (littlewin.app/join/UserA) but
  already has the app.
- OS Interception: Because you set up Universal Links (iOS) or App Links
  (Android), the OS skips the browser and opens the app directly.
- Context Injection: The app receives the URL parameter /join/UserA.
- Instant Follow: The app opens directly to User A’s profile with a "Follow
  Back?" prompt or automatically performs the follow if they are already logged
  in.

3. The "Manual" Journey (Search & Discovery)

- Target: You know they are on the app, but don't want to send a text. _ Search:
  User A goes to the "People" tab.
- Live Query: As they type, you query your Supabase profiles table (using ilike
  for fuzzy matching usernames).
- UX Polish: Show the user’s avatar
- Follow: Tap "Follow." User B receives a push notification: "User A is now
  following you! Follow back?"

4. The "In-Person" Journey (Zero-Link)

- Target: You are sitting next to the person at the gym or dinner.
- QR Display: User A opens their profile and taps a small QR icon.
- Scan: User B opens their phone camera (or a scanner in your app).
- Resolution: The QR code contains the Deep Link littlewin://user/UserA.
- Result: User B’s app jumps straight to User A’s profile. This is the "Purest"
  interaction because it requires zero typing and zero external apps (no
  SMS/WhatsApp).

## Suggested Backend Implementation Approach

### What should be server-authoritative

- Check-in validity rules
- Bet validation rules (limits, streak window, run status)
- Notification creation (bet won, etc.)

### RPCs / functions (names flexible, semantics matter)

Prefer to implement these behaviors early:

- Explore query function (cursor + exclude dismissed)
- Check-in function (validate UTC day, increment streak, resolve won bets)
- Bet placement function (validate limits + self-bet flag)
- Merge anonymous user to Google account

### Notifications

- Use realtime only for notifications.
- Deep links should resolve to the relevant screen.

## Suggested Client Data Strategy

- Cache read-heavy lists (runs/challenges/bets) with TTL behavior.
- Refresh caches on write events (check-in, bet placed, follow).
- Support offline by queueing write actions; replay on reconnect.
- Keep list pagination cursor-based where possible.

## Suggested Error Handling

- Network failures: show a Snackbar + retry affordance.
- Validation errors: inline errors on the relevant control, not modal spam.
- “Critical” conflicts: use a dialog (e.g., username already taken).

## Suggested Code Organization (Keep It Light)

- Aim for clean boundaries (data/domain/presentation), but avoid excessive
  layers.
- Use a consistent state management approach; keep providers small and focused.
- Avoid heavy dependencies unless they remove meaningful complexity.

## Suggested Testing Focus (Highest ROI First)

Start with tests around core loop integrity:

- check-in validity + streak increment
- bet validation + self-bet behavior
- win → notification creation
- dismissed challenge exclusion
- merge anonymous user correctness

Widget tests only for the most complex UI parts (Explore card, bet modal,
notification item).

## Suggested Performance Guardrails (Not Premature Optimization)

- Keep queries minimal (select only needed columns).
- Keep feed fetches small.
- Avoid realtime subscriptions except notifications.
- Only optimize further if profiling reveals real problems.

## “Do Not Do” List (Anti-Drift)

Do not add:

- payments / money features
- chat / messaging
- complex scheduling/planning
- group or league systems
- content posting / comments
- heavy personalization / recommendations unless explicitly requested in the
  current task.
```
