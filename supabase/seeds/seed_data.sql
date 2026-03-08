-- =============================================================================
-- Seed Data for Littlewin
-- Run this in your Supabase SQL Editor.
-- =============================================================================

-- 1. Create the system user 'challenger0'
-- We use a fixed UUID for consistency.
DO $$
DECLARE
    sys_id UUID := '00000000-0000-0000-0000-000000000000';
BEGIN
    -- 1a. Insert into auth.users first (Supabase internal table)
    -- This satisfies the foreign key in public.users.
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = sys_id) THEN
        INSERT INTO auth.users (id, instance_id, email, aud, role, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, is_super_admin)
        VALUES (
            sys_id, 
            '00000000-0000-0000-0000-000000000000', 
            'challenger0@littlewin.app', 
            'authenticated', 
            'authenticated', 
            'no-password', -- Placeholder
            now(),
            '{"provider":"email","providers":["email"]}',
            '{}',
            now(),
            now(),
            '', '', '', false
        );
    END IF;

    -- 1b. Insert into public.users
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = sys_id) THEN
        INSERT INTO public.users (id, username, roles, avatar_id)
        VALUES (sys_id, 'challenger0', '{basic}', 1);
    END IF;
END $$;

-- 2. Insert initial challenges
-- Using standard UUIDs or generating them. Let's use the slugs as natural keys for upsert.
INSERT INTO public.challenges (title, description, slug, visibility, current_participant_count, image_asset)
VALUES 
('10-Minute Workout', 'No gym required — (at least) 10 minutes at home counts.', '10-minute-workout', 'public', 1, 'assets/pictures/challenge_10-minute-workout.jpg'),
('16-Hour Fasting', 'Skip breakfast or dinner, eat in an 8-hour window. One of the most researched longevity habits.', '16-hour-fasting', 'public', 1, 'assets/pictures/challenge_16-hour-fasting.jpg'),
('Cold Showers', 'Use cold water in every shower. Builds mental resilience, one day at a time.', 'cold-showers', 'public', 1, 'assets/pictures/challenge_cold-showers.jpg'),
('Zero Doomscroll', 'No mindless social media scrolling. Replace the habit with something intentional.', 'zero-doomscroll', 'public', 1, 'assets/pictures/challenge_zero-doomscroll.jpg'),
('16-Hour Offscreen', 'Keep screens off for 16 hours of the day. Reclaim your attention and your evenings.', '16-hour-offscreen', 'public', 1, 'assets/pictures/challenge_16-hour-offscreen.jpg'),
('No Screens After 9PM', 'Keep screens off after 9PM. Reclaim your attention and your evenings.', 'no-screens-after-9pm', 'public', 1, 'assets/pictures/challenge_no-screens-after-9pm.jpg'),
('Zero Coffee', 'Skip the caffeine hit. Explore what your natural energy levels feel like.', 'zero-coffee', 'public', 1, 'assets/pictures/challenge_zero-coffee.jpg'),
('No Eating Out', 'Cook every meal yourself. Save money, eat better, rediscover the kitchen.', 'no-eating-out', 'public', 1, 'assets/pictures/challenge_no-eating-out.jpg'),
('Zero Added Sugar', 'Cut all added sugars from your diet. Read labels, reset your palate.', 'zero-added-sugar', 'public', 1, 'assets/pictures/challenge_zero-added-sugar.jpg'),
('Ketogenic Diet', 'High fat, low carb, every day. A true metabolic reset.', 'ketogenic-diet', 'public', 1, 'assets/pictures/challenge_ketogenic-diet.jpg'),
('20-Minute Walk', 'Step outside and walk for 20 minutes. The simplest habit with outsized benefits.', '20-minute-walk', 'public', 1, 'assets/pictures/challenge_20-minute-walk.jpg'),
('10,000 Steps', 'Hit your daily step goal with intention. Every walk counts toward the streak.', '10000-steps', 'public', 1, 'assets/pictures/challenge_10000-steps.jpg'),
('Zero Alcohol', 'No drinks. Full clarity, better sleep, real savings — one day at a time.', 'zero-alcohol', 'public', 1, 'assets/pictures/challenge_zero-alcohol.jpg'),
('10-Minute Stretch', 'Dedicate 10 minutes to stretching every day. Your future self will thank you.', '10-minute-stretch', 'public', 1, 'assets/pictures/challenge_10-minute-stretch.jpg'),
('5-Minute Breathwork', 'Five minutes of intentional breathing. Box breath, 4-7-8, or whatever grounds you.', '5-minute-breathwork', 'public', 1, 'assets/pictures/challenge_5-minute-breathwork.jpg'),
('1-Page Journaling', 'Write one page every day. Stream of consciousness, gratitude, or goals — just write.', '1-page-journaling', 'public', 1, 'assets/pictures/challenge_1-page-journaling.jpg'),
('4x4 Norwegian Protocol', 'Do 4 sets of 4 minutes of intense exercise, with 4 minutes of rest in between.', '4x4-norwegian-protocol', 'public', 1, 'assets/pictures/challenge_4x4-norwegian-protocol.jpg'),
('90-Minute Deep Work', 'Dedicate 90 minutes to your most difficult task with zero distractions. Align with your brain''s natural ultradian rhythms.', '90-minute-deep-work', 'public', 1, 'assets/pictures/challenge_90-minute-deep-work.jpg'),
('20-Minute Ukulele', 'Spend 20 minutes actively practicing ukulele every day.', '20-minute-ukulele', 'public', 1, 'assets/pictures/challenge_20-minute-ukulele.jpg'),
('20-Minute Piano', 'Spend 20 minutes actively practicing piano every day.', '20-minute-piano', 'public', 1, 'assets/pictures/challenge_20-minute-piano.jpg'),
('20-Minute Guitar', 'Spend 20 minutes actively practicing guitar every day.', '20-minute-guitar', 'public', 1, 'assets/pictures/challenge_20-minute-guitar.jpg'),
('Up Before 6AM', 'Extend your day.', 'up-before-6am', 'public', 1, 'assets/pictures/challenge_up-before-6am.jpg'),
('No Food After 6PM', 'No food after 6PM.', 'no-food-after-6pm', 'public', 1, 'assets/pictures/challenge_no-food-after-6pm.jpg'),
('20-Minute Read', 'Read for 20 minutes every day.', '20-minute-read', 'public', 1, 'assets/pictures/challenge_20-minute-read.jpg'),
('Glucostat 10-10-10', 'Walk for exactly 10 minutes after your 3 main meals. This ''muscle sponge'' effect flattens glucose spikes and prevents the afternoon energy slump.', 'glucostat-10-10-10', 'public', 1, 'assets/pictures/challenge_glucostat-10.jpg'),
('Mammalian Dive Reset', 'Submerge your face in a bowl of ice water for 30 seconds when stressed. It triggers the Mammalian Dive Reflex, instantly slowing your heart rate and resetting your nervous system.', 'mammalian-dive-reset', 'public', 1, 'assets/pictures/challenge_mammalian-dive.jpg')
ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    image_asset = EXCLUDED.image_asset;

-- 3. Seed default stakes
INSERT INTO public.stakes (id, title, category)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Coffee Cup',         'plan'),
  ('a0000000-0000-0000-0000-000000000002', 'Brunch Invite',      'plan'),
  ('a0000000-0000-0000-0000-000000000003', 'Restaurant Dinner',  'plan'),
  ('a0000000-0000-0000-0000-000000000004', 'Drinks Round',       'plan'),
  ('a0000000-0000-0000-0000-000000000005', 'Cinema Night',       'plan'),
  ('a0000000-0000-0000-0000-000000000006', 'Chocolate Box',      'gift'),
  ('a0000000-0000-0000-0000-000000000007', 'Wine Bottle',        'gift'),
  ('a0000000-0000-0000-0000-000000000008', 'Spa Access',         'gift'),
  ('a0000000-0000-0000-0000-000000000009', 'Massage Session',    'gift'),
  ('a0000000-0000-0000-0000-00000000000a', 'Surprise Box',       'gift')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  category = EXCLUDED.category;

-- 4. Create initial runs for 'challenger0'
-- This ensures the Priority 4 fallback in get_explore_feed has something to show.
DO $$
DECLARE
    sys_id UUID := '00000000-0000-0000-0000-000000000000';
    ch RECORD;
    today DATE := CURRENT_DATE;
BEGIN
    FOR ch IN SELECT id, slug FROM public.challenges WHERE created_by IS NULL LOOP
        -- Seeded completed runs (Priority 4 fallback)
        -- Only insert if not already present
        IF NOT EXISTS (SELECT 1 FROM public.runs WHERE challenge_id = ch.id AND user_id = sys_id) THEN
            INSERT INTO public.runs (challenge_id, user_id, start_date, current_streak, final_score, status, visibility, recent_bet_count)
            VALUES (ch.id, sys_id, today - 1, 1, 1, 'completed', 'public', floor(random() * 5)::int);
        END IF;
    END LOOP;
END $$;
-- 5. Seeding for Edge Function configuration
INSERT INTO public.app_config (key, value)
VALUES 
  ('PUSH_FUNCTION_URL', 'http://localhost:54321/functions/v1/push-notifier'),
  ('SERVICE_ROLE_KEY', 'your-service-role-key-here')
ON CONFLICT (key) DO NOTHING;
