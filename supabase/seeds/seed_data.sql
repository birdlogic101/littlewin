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
('5AM Club', 'The most impactful work happens in silence. Waking at 5:00 AM secures the only hour of the day guaranteed to be free from external demands. It is the tactical advantage required to move from a reactive state to a position of leadership over your own schedule.', '5am-club', 'public', 1, 'assets/pictures/challenge_5am-club.jpg'),
('6AM Breakfast', 'Metabolic performance is dictated by timing. Finishing your first meal by 6:00 AM signals your body to activate its daytime energy systems immediately. This daily synchronization ensures your peak alertness coincides with your most important tasks.', '6am-breakfast', 'public', 1, 'assets/pictures/challenge_6am-breakfast.jpg'),
('10PM Bedtime', 'Recovery is a time-sensitive process. By 10:00 PM, your brain begins its most efficient cycle of cognitive repair and hormone reset. Protecting this window daily is a requirement for maintaining high capacity as your streak grows.', '10pm-bedtime', 'public', 1, 'assets/pictures/challenge_10pm-bedtime.jpg'),
('6PM Dinner', 'Sleep should be for repair, not digestion. Finishing your final meal by 6:00 PM allows your system to process intake before you sleep, lowering your resting heart rate and deepening your recovery cycles. It is the foundation of waking up truly refreshed.', '6pm-dinner', 'public', 1, 'assets/pictures/challenge_6pm-dinner.jpg'),
('Skip Dinner', 'The body heals most effectively in the absence of food. Omission of dinner extends your fast into the window of deep cellular cleanup that standard intermittent fasting never reaches. This daily reset is the most direct path to maintaining a lean, high-functioning system.', 'skip-dinner', 'public', 1, 'assets/pictures/challenge_skip-dinner.jpg'),
('Cold Shower', 'Resilience is built through intentional stress. Two minutes of cold exposure is the exact point where the body’s shock response shifts into a state of sustained alertness and dopamine release. It is the daily practice that ensures your mind remains steady under pressure.', 'cold-shower', 'public', 1, 'assets/pictures/challenge_cold-shower.jpg'),
('Zero Scroll', 'Algorithmic feeds are designed to fracture your focus. Total elimination of short-form scrolling is the only way to restore your brain’s capacity for deep, sustained concentration. Protecting your attention daily is the prerequisite for achieving anything of significance.', 'zero-scroll', 'public', 1, 'assets/pictures/challenge_zero-scroll.jpg'),
('Zero Gluten', 'Systemic inflammation is a silent killer of performance. Removing gluten entirely is the only way to verify its impact on your cognitive clarity and energy levels. Even trace amounts reset the inflammatory clock, masking the true potential of your physiology.', 'zero-gluten', 'public', 1, 'assets/pictures/challenge_zero-gluten.jpg'),
('Zero Alcohol', 'Alcohol is the most common disruptor of restorative sleep. Total abstinence ensures your brain completes its full architectural recovery every night, maintaining the high-fidelity focus required to sustain a long-term streak without burnout.', 'zero-alcohol', 'public', 1, 'assets/pictures/challenge_zero-alcohol.jpg'),
('Full Keto', 'Biological energy should be stable, not volatile. Strict nutritional ketosis shifts your brain to a fuel source that eliminates energy crashes and hunger spikes. Constant adherence is the only way to remain in the high-performance state of fat-adaptation.', 'full-keto', 'public', 1, 'assets/pictures/challenge_full-keto.jpg'),
('Stretch 10', 'Movement longevity is won in ten-minute increments. This specific duration is required for your nervous system to accept a deeper range of motion and for connective tissues to adapt. It is the daily investment that prevents the cumulative stiffness of a modern lifestyle.', 'stretch-10', 'public', 1, 'assets/pictures/challenge_stretch-10.jpg'),
('Read 20', 'Depth of thought requires depth of focus. Reading for at least 20 minutes allows your mind to settle into a single concept, moving past superficial skimming into deep comprehension. It is how you build a world-class mental library, one day at a time.', 'read-20', 'public', 1, 'assets/pictures/challenge_read-20.jpg'),
('Workout 30', 'Thirty minutes is the definitive threshold for a meaningful physical adaptation. It is the volume required to stimulate your metabolism and maintain lean muscle mass without overtaxing your recovery. It is long enough to rebuild you, but short enough to never miss.', 'workout-30', 'public', 1, 'assets/pictures/challenge_workout-30.jpg'),
('Create 20', 'The hardest part of creation is the first ten minutes. Committing to a full 20 minutes ensures you push through the initial resistance and enter the work itself. This daily habit transforms you from a consumer into a person who builds things that last.', 'create-20', 'public', 1, 'assets/pictures/challenge_create-20.jpg'),
('Learn 20', 'World-class skills are built through daily, deliberate practice. Twenty minutes of focused learning is the optimal window to absorb new information without reaching the point of diminishing returns. It is the rhythm of steady, unstoppable progress.', 'learn-20', 'public', 1, 'assets/pictures/challenge_learn-20.jpg'),
('Walk 30', 'A 30-minute brisk walk is the physiological limit where cortisol levels begin to drop and the mind resets. It is the simplest tool for clearing mental fog and maintaining the emotional stability needed for a long-term performance streak.', 'walk-30', 'public', 1, 'assets/pictures/challenge_walk-30.jpg'),
('Hydrate 2', 'Hydration is the foundation of cognitive speed. Two liters of water daily is the reliable standard for maintaining cellular function and preventing the subtle fatigue that undermines your focus. It is the literal fuel for every chemical reaction in your body.', 'hydrate-2', 'public', 1, 'assets/pictures/challenge_hydrate-2.jpg'),
('Shake 10', 'Tension accumulates in the nervous system throughout the day. Shaking for ten minutes is the required duration to physically release stored stress and move stagnant fluids. It is a daily reset that leaves you feeling alert and physically unburdened.', 'shake-10', 'public', 1, 'assets/pictures/challenge_shake-10.jpg'),
('Bounce 10', 'The lymphatic system requires movement to function. Ten minutes on a rebounder uses gravity to flush every cell in your body, strengthening your immune defense and increasing energy levels. It is the most efficient daily practice for total biological cleanup.', 'bounce-10', 'public', 1, 'assets/pictures/challenge_bounce-10.jpg')
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
  ('PUSH_FUNCTION_URL', 'https://jibfozleqgpfutcwgbrw.supabase.co/functions/v1/push-notifier'),
  ('SERVICE_ROLE_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppYmZvemxlcWdwZnV0Y3dnYnJ3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE4MDY5MSwiZXhwIjoyMDg2NzU2NjkxfQ.yDhY0olwd8NCySUFVO6Tv6RFKXb8YI8moi-_Jj0IWEw')
ON CONFLICT (key) DO NOTHING;
