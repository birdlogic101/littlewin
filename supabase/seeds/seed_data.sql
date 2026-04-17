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
('5AM Club', 'Taking control of your first hour allows you to harness the 500% productivity multiplier of the flow state before the world demands your attention. Waking at 5:00 AM provides a rare window of silence for deep focus, transforming your perspective from reactive to intentional and helping you lead your day rather than following it.', '5am-club', 'public', 1, 'assets/pictures/challenge_5am-club.jpg', 90),
('Hydrate 2', 'Even mild dehydration (2% body mass loss) is linked to significant impairments in attention, executive function, and a 5% drop in cognitive speed. 75% of adults are in a state of chronic cellular desiccation. Drinking 2 liters daily is the simplest way to ensure your brain is operating at its natural baseline.', 'hydrate-2', 'public', 1, 'assets/pictures/challenge_hydrate-2.jpg', 30),
('6AM Breakfast', 'Aligning your nutrition with your circadian rhythm improves insulin sensitivity and metabolic efficiency, countering the 1-in-3 trend of pre-metabolic failure. Consistency in meal timing is a primary defense against metabolic disturbances. Finishing your first meal by 6:00 AM helps synchronize your systems for a productive day.', '6am-breakfast', 'public', 1, 'assets/pictures/challenge_6am-breakfast.jpg', 10),
('10PM Bedtime', 'Sleep deprivation is a classified carcinogen; missing the 10:00 PM window literally stops your brain from washing away the neurotoxic beta-amyloid that eventually drives neurodegenerative decay. Sleep is the brain''s essential maintenance window. Aiming for a steady 7-8 hours starting at 10:00 PM is the most reliable way to protect your long-term health.', '10pm-bedtime', 'public', 1, 'assets/pictures/challenge_10pm-bedtime.jpg', 140),
('6PM Dinner', 'Digesting food during sleep is a form of "Recovery Bankruptcy" that forces your heart rate to remain elevated when it should be repairing your tissues. Finishing your last meal by 6:00 PM allows your heart rate to lower deeply before you sleep. Achieving a 15% weight loss through such windows has been shown to have a disease-modifying effect.', '6pm-dinner', 'public', 1, 'assets/pictures/challenge_6pm-dinner.jpg', 50),
('Zero Scroll', 'Digital feeds are training the human brain for "shallow skimming," a mode of processing that causes the measurable atrophy of neural circuits required for critical thinking and empathy. With the average adult losing 11 years to a screen and showing gray matter volume reduction, this architectural shift is an invisible epidemic.', 'zero-scroll', 'public', 1, 'assets/pictures/challenge_zero-scroll.jpg', 40),
('Cold Showers', 'Cold exposure is a trigger for hormesis—a stressor that stimulates mitochondrial biogenesis (creating new cellular powerhouses) and activates Cold Shock Proteins for DNA repair. This results in a massive 530% surge in norepinephrine and a 29% reduction in sick days, building immediate mental resilience.', 'cold-showers', 'public', 1, 'assets/pictures/challenge_cold-showers.jpg', 190),
('Zero Alcohol', 'Large-scale studies show that moving from only one to two drinks a day correlates with structural brain changes equivalent to aging by an extra two years. Alcohol is a primary disruptor of REM sleep and mitochondrial repair. Total abstinence ensures your brain performs its full nightly recovery, keeping your mind sharp.', 'zero-alcohol', 'public', 1, 'assets/pictures/challenge_zero-alcohol.jpg', 170),
('Workout 30', 'With 31% of the global adult population (1.8 billion people) now physically inactive, the "Sedentary Death Spiral" is a quiet epidemic. Replacing 30 minutes of sitting with activity reduces mortality risk by up to 45%. Thirty minutes is the biological requirement for stimulating your metabolism and supporting your muscles.', 'workout-30', 'public', 1, 'assets/pictures/challenge_workout-30.jpg', 20),
('Walk 30', 'Exposure to green space is associated with cognitive function equivalent to being 1.2 years younger, while up to 45% of dementia cases could be delayed by addressing lifestyle factors like physical activity. A simple 30-minute brisk walk is one of the most effective ways to lower systemic cortisol.', 'walk-30', 'public', 1, 'assets/pictures/challenge_walk-30.jpg', 100),
('Stretch 10', 'Sedentary fascial rigidity is a hidden driver of chronic pain, as connective tissues literally fuse together without daily movement. This stiffness is a primary driver of the global chronic pain epidemic. Stretching for ten minutes is a baseline investment in your future mobility and nervous system health.', 'stretch-10', 'public', 1, 'assets/pictures/challenge_stretch-10.jpg', 110),
('Read 20', 'Deep reading (vs. skimming) corresponds with measurable increases in neural connectivity in the left temporal cortex, supporting superior comprehension and complexity. Unlike digital skimming, deep reading builds the sustained neural circuits necessary for analysis and long-term retention.', 'read-20', 'public', 1, 'assets/pictures/challenge_read-20.jpg', 160),
('Learn 20', 'Compound learning via spaced repetition improves long-term recall accuracy by 200% compared to traditional study methods. Twenty minutes of focused learning is a manageable window to absorb new info without feeling overwhelmed. Over time, these sessions compound into deep expertise and a significant edge.', 'learn-20', 'public', 1, 'assets/pictures/challenge_learn-20.jpg', 130),
('Create 20', 'Entering a creator''s flow state results in a potential 500% increase in productivity compared to the passive consumption of other people''s ideas. Committing to 20 minutes of creation helps you push past resistance and enters a state of flow, transforming you into someone who actively shapes their world.', 'create-20', 'public', 1, 'assets/pictures/challenge_create-20.jpg', 80),
('Skip Dinner', 'Trigger the biological miracle of autophagy, allowing your body to clear out damaged cells and protein aggregates for natural longevity. This internal "cell recycling" process is a direct path to metabolic health and cellular maintenance. It’s a simple physiological reset that also reclaims significant daily time.', 'skip-dinner', 'public', 1, 'assets/pictures/challenge_skip-dinner.jpg', 150),
('Full Keto', 'With up to 59% of adults facing "Type 3 Diabetes"—insulin resistance in the brain—high-sugar diets are effectively starving neural cells of energy. Nutritional ketosis provides a factual alternative by shifting your brain to BHB, a super-fuel that restores energy while triggering mitophagy to clear out damaged cellular machinery.', 'full-keto', 'public', 1, 'assets/pictures/challenge_full-keto.jpg', 120),
('Zero Gluten', 'Eliminating systemic triggers can reveal a new baseline of cognitive clarity and reduce inflammatory markers (CRP) that mask your true energy levels. Removing gluten is a straightforward way to test how it affects your unique chemistry and inflammatory baseline, revealing what your physiology is truly capable of.', 'zero-gluten', 'public', 1, 'assets/pictures/challenge_zero-gluten.jpg', 60),
('Shake 10', 'With 90% of doctor visits being stress-related, shaking provides an immediate somatic reset to clear unreleased cortisol from your nervous system. Tension often accumulates as a response to daily stress. Ten minutes of shaking is a natural way to release that stored somatic trauma and move stagnant fluids.', 'shake-10', 'public', 1, 'assets/pictures/challenge_shake-10.jpg', 180),
('Rebound 10', 'Rebounding can increase lymphatic circulation by 15 to 30 times compared to rest; without it, your immune defense lives in a state of toxic load. Ten minutes on a rebounder uses gravity to help your body’s natural cleanup process, supporting your immune system and your energy levels. It is a highly efficient way to maintain your biological health.', 'rebound-10', 'public', 1, 'assets/pictures/challenge_rebound-10.jpg', 70)
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
