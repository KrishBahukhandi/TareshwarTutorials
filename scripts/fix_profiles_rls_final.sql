-- ============================================================
-- DEFINITIVE FIX: Profiles RLS – no infinite recursion
-- ============================================================
-- The previous policy queried `profiles` inside the policy on
-- `profiles`, causing infinite recursion → 500 errors on login.
-- 
-- Fix: use auth.jwt() to read the role claim, OR simply allow
-- all authenticated users to read all profiles (safe for this app).
--
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/cyfwcgsfdlecnkycpjsk/sql/new
-- ============================================================

-- Step 1: Drop ALL existing policies on profiles
DO $$
DECLARE pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'profiles' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol);
  END LOOP;
END;
$$;

-- Step 2: Simple, non-recursive policies
-- Any authenticated user can read any profile (no self-join needed)
CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can only update their own profile
CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Insert is only via trigger (new user signup) or service role
-- Allow authenticated to insert only their own row
CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- No authenticated user can delete profiles (admin uses service role)
-- (leave no DELETE policy = no deletes via anon/authenticated)

-- Step 3: Add missing columns if they don't exist yet
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Step 4: Ensure all existing profiles are marked active
UPDATE public.profiles SET is_active = true WHERE is_active IS NULL;
