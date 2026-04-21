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
INSERT INTO public.challenges (title, description, slug, visibility, current_participant_count, image_asset, sort_order)
VALUES 
('5AM Club', 'Commit to being up by 5:00 AM to harness your peak cognitive window. The average person loses 3 hours of productivity every day to reactive mornings, but starting early gives you access to a massive focus state that most people never experience consciously. Reclaim your focus before the world demands your attention.', '5am-club', 'public', 1, 'assets/pictures/challenge_5am-club.jpg', 90),
('Hydrate 2', 'Drink 2 liters of water today to protect your cognitive speed. When you feel thirst, you are already facing up to a 20% performance impairment and temporary brain volume loss. Staying hydrated matches your brain to its natural baseline, ensuring you operate at peak levels of energy and daily focus.', 'hydrate-2', 'public', 1, 'assets/pictures/challenge_hydrate-2.jpg', 30),
('6AM Breakfast', 'Have breakfast at 6:00 AM to take advantage of your metabolic peak. Your insulin sensitivity is twice as high in the morning as it is in the evening, making early fueling nearly 100% more efficient at stabilizing your system. Start your day with the metabolic clarity required for high performance.', '6am-breakfast', 'public', 1, 'assets/pictures/challenge_6am-breakfast.jpg', 10),
('10PM Bedtime', 'Be in bed by 10:00 PM to avoid a 30% increase in mortality risk linked to chronic sleep deprivation. Losing sleep impairs your cognition as much as alcohol, whereas protecting the 10:00 PM window aligns your biology with melatonin cycles to balance hormones and ensure deep memory consolidation.', '10pm-bedtime', 'public', 1, 'assets/pictures/challenge_10pm-bedtime.jpg', 140),
('6PM Dinner', 'Have dinner at 6:00 PM to give your metabolism a total reset. Digestion efficiency drops dramatically in the evening, and identical meals produce a worse metabolic response at night. An earlier cutoff improves sleep quality and ensures your body focuses on repair rather than storage.', '6pm-dinner', 'public', 1, 'assets/pictures/challenge_6pm-dinner.jpg', 50),
('Zero Scroll', 'Avoid all social media and news feeds today to recover your focus. Task-switching between digital feeds can reduce your total productivity by up to 40%, while constant novelty hijacks your dopamine loops. Cutting the scroll restores your baseline motivation and lowers daily digital anxiety.', 'zero-scroll', 'public', 1, 'assets/pictures/challenge_zero-scroll.jpg', 40),
('Cold Showers', 'Take one fully cold shower today to trigger a 5x surge in norepinephrine. Modern comfort weakens your adaptive capacity, but brief cold exposure activates brown fat and builds mental resilience. It’s a powerful controlled stressor that provides an immediate, natural mood boost for the rest of your day.', 'cold-showers', 'public', 1, 'assets/pictures/challenge_cold-showers.jpg', 190),
('Zero Alcohol', 'Consume no alcohol at all to ensure your liver and brain perform their full nightly recovery. Because alcohol is a neurotoxin, your body pauses 100% of other metabolism just to prioritize detoxing. Staying dry ensures your REM sleep is deep and your mind remains sharp for the next day.', 'zero-alcohol', 'public', 1, 'assets/pictures/challenge_zero-alcohol.jpg', 170),
('Workout 30', 'Complete 30 minutes of physical activity to lower your mortality risk by up to 30%. Inactivity is now considered as hazardous to your health as smoking, whereas just 30 minutes of stimulus releases endorphins and BDNF, building the muscle mass that predicted your long-term longevity.', 'workout-30', 'public', 1, 'assets/pictures/challenge_workout-30.jpg', 20),
('Walk 30', 'Take a 30-minute walk to ''complete'' your stress response cycle. Inactivity is associated with a 30% higher mortality risk, and a short walk can measurably lower cortisol within just 10 minutes. Doing nothing physically means staying stressed longer biologically; movement is your release.', 'walk-30', 'public', 1, 'assets/pictures/challenge_walk-30.jpg', 100),
('Stretch 10', 'Invest 10 minutes in stretching to reverse the ''sitting posture'' that is becoming the default human shape. Sitting for more than 6 hours a day causes your mobility to decay rapidly as tissues begin to stiffen. A short daily session restores your circulation and protects your future posture.', 'stretch-10', 'public', 1, 'assets/pictures/challenge_stretch-10.jpg', 110),
('Read 20', 'Read for 20 minutes to reduce your stress levels by up to 60%. Deep reading—at this pace, you''ll absorb nearly 1.8 million words a year—measurably increases neural connectivity in the brain. It is an active way to build a sharper mind and actively slow cognitive decline over time.', 'read-20', 'public', 1, 'assets/pictures/challenge_read-20.jpg', 160),
('Learn 20', 'Spend 20 minutes on focused learning to fight the brain’s forgetting curve. Without active reinforcement, your brain prunes 70% of new information within 24 hours. A short session using spaced repetition can improve your recall by up to 3 times, turning consistency into exponential expertise.', 'learn-20', 'public', 1, 'assets/pictures/challenge_learn-20.jpg', 130),
('Create 20', 'Dedicate 20 minutes to a creative activity to shift from consumption to output. Most people consume ten times more than they create, leading to a passive illusion of competence. Creating something new builds a more powerful identity and helps you enter a state of flow that boosts productivity.', 'create-20', 'public', 1, 'assets/pictures/challenge_create-20.jpg', 80),
('Skip Dinner', 'Fast between lunch and breakfast (12–16 hours) to trigger the miracle of autophagy. Constant feeding keeps your body in permanent ''storage mode,'' but an absence of fasting results in minimal cellular repair signaling. A skip reset clears out damaged cells for total metabolic health.', 'skip-dinner', 'public', 1, 'assets/pictures/challenge_skip-dinner.jpg', 150),
('Full Keto', 'Restrict your intake to under 50g of carbs today—roughly the equivalent of one bagel. While glucose reliance causes metabolic rigidity and energy crashes, shifting to ketones provides your brain with a super-fuel that stabilizes energy. This shift has such a deep impact that it reduced seizures by 50% in clinical studies.', 'full-keto', 'public', 1, 'assets/pictures/challenge_full-keto.jpg', 120),
('Zero Gluten', 'Eat no gluten today to reveal a new baseline of cognitive clarity. Removing inflammatory triggers—which up to 1% are celiac and a larger percentage are sensitive to—can reduce markers that mask your true energy levels. It’s a simple elimination test to see what your physiology is truly capable of.', 'zero-gluten', 'public', 1, 'assets/pictures/challenge_zero-gluten.jpg', 60),
('Shake 10', 'Spend 10 minutes shaking to address the 90% of doctor visits that are stress-related. Your lymphatic system has no central pump and relies entirely on somatic movement to clear metabolic waste. It’s a natural way to shed stored tension and release unreleased cortisol from your nervous system.', 'shake-10', 'public', 1, 'assets/pictures/challenge_shake-10.jpg', 180),
('Rebound 10', 'Spend 10 minutes on a rebounder or jumping rope to drive lymphatic drainage. NASA noted the extreme efficiency of rebounding for conditioning, as internal fluid movement is amplified by gravity shifts. It is a highly efficient way to clear toxic loads and maintain your biological health.', 'rebound-10', 'public', 1, 'assets/pictures/challenge_rebound-10.jpg', 70)
ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    image_asset = EXCLUDED.image_asset,
    sort_order = EXCLUDED.sort_order;

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
  ('PUSH_FUNCTION_URL', 'https://jibfozleqgpfutcwgbrw.supabase.co/functions/v1/push-notifier'),
  ('SERVICE_ROLE_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppYmZvemxlcWdwZnV0Y3dnYnJ3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE4MDY5MSwiZXhwIjoyMDg2NzU2NjkxfQ.yDhY0olwd8NCySUFVO6Tv6RFKXb8YI8moi-_Jj0IWEw')
ON CONFLICT (key) DO NOTHING;
