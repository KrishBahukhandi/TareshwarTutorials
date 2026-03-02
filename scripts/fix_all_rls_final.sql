-- ============================================================
-- ALL-IN-ONE RLS FIX – Run this to fix everything at once
-- Supabase SQL Editor:
-- https://supabase.com/dashboard/project/cyfwcgsfdlecnkycpjsk/sql/new
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- STEP 1: Create a security-definer helper function
-- This avoids infinite recursion in any policy that needs
-- to check the current user's role.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- ────────────────────────────────────────────────────────────
-- STEP 2: Fix profiles table
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Add missing columns
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

UPDATE public.profiles SET is_active = true WHERE is_active IS NULL;

-- Drop ALL existing policies (cleans up any broken ones)
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

-- Simple non-recursive policies:
-- All authenticated users can read all profiles
CREATE POLICY "profiles_select"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can update only their own profile
CREATE POLICY "profiles_update"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Users can insert only their own profile row
CREATE POLICY "profiles_insert"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- ────────────────────────────────────────────────────────────
-- STEP 3: Fix enrollments policies (use helper function)
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'enrollments' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.enrollments', pol);
  END LOOP;
END;
$$;

CREATE POLICY "enrollments_select"
  ON public.enrollments FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid()
    OR public.get_my_role() IN ('admin', 'teacher')
  );

CREATE POLICY "enrollments_insert"
  ON public.enrollments FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role() = 'admin');

CREATE POLICY "enrollments_update"
  ON public.enrollments FOR UPDATE
  TO authenticated
  USING (public.get_my_role() = 'admin');

CREATE POLICY "enrollments_delete"
  ON public.enrollments FOR DELETE
  TO authenticated
  USING (public.get_my_role() = 'admin');

-- ────────────────────────────────────────────────────────────
-- STEP 4: Fix courses policies
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'courses' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.courses', pol);
  END LOOP;
END;
$$;

-- Everyone authenticated can read published courses; admins/teachers see all
CREATE POLICY "courses_select"
  ON public.courses FOR SELECT
  TO authenticated
  USING (
    is_published = true
    OR public.get_my_role() IN ('admin', 'teacher')
  );

CREATE POLICY "courses_insert"
  ON public.courses FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role() = 'admin');

CREATE POLICY "courses_update"
  ON public.courses FOR UPDATE
  TO authenticated
  USING (public.get_my_role() = 'admin');

CREATE POLICY "courses_delete"
  ON public.courses FOR DELETE
  TO authenticated
  USING (public.get_my_role() = 'admin');

-- ────────────────────────────────────────────────────────────
-- STEP 5: Fix batches policies
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'batches' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.batches', pol);
  END LOOP;
END;
$$;

CREATE POLICY "batches_select"
  ON public.batches FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "batches_insert"
  ON public.batches FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role() = 'admin');

CREATE POLICY "batches_update"
  ON public.batches FOR UPDATE
  TO authenticated
  USING (public.get_my_role() IN ('admin', 'teacher'));

CREATE POLICY "batches_delete"
  ON public.batches FOR DELETE
  TO authenticated
  USING (public.get_my_role() = 'admin');

-- ────────────────────────────────────────────────────────────
-- STEP 6: Fix recorded_videos policies
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.recorded_videos ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'recorded_videos' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.recorded_videos', pol);
  END LOOP;
END;
$$;

CREATE POLICY "recorded_videos_select"
  ON public.recorded_videos FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "recorded_videos_insert"
  ON public.recorded_videos FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role() IN ('teacher', 'admin'));

CREATE POLICY "recorded_videos_update"
  ON public.recorded_videos FOR UPDATE
  TO authenticated
  USING (uploaded_by = auth.uid() OR public.get_my_role() = 'admin');

CREATE POLICY "recorded_videos_delete"
  ON public.recorded_videos FOR DELETE
  TO authenticated
  USING (uploaded_by = auth.uid() OR public.get_my_role() = 'admin');

-- ────────────────────────────────────────────────────────────
-- STEP 7: Fix notes policies
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'notes' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.notes', pol);
  END LOOP;
END;
$$;

CREATE POLICY "notes_select"
  ON public.notes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "notes_insert"
  ON public.notes FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role() IN ('teacher', 'admin'));

CREATE POLICY "notes_update"
  ON public.notes FOR UPDATE
  TO authenticated
  USING (uploaded_by = auth.uid() OR public.get_my_role() = 'admin');

CREATE POLICY "notes_delete"
  ON public.notes FOR DELETE
  TO authenticated
  USING (uploaded_by = auth.uid() OR public.get_my_role() = 'admin');

-- ────────────────────────────────────────────────────────────
-- Done! Verify with:
-- SELECT tablename, policyname, cmd FROM pg_policies
-- WHERE schemaname = 'public' ORDER BY tablename, policyname;
-- ────────────────────────────────────────────────────────────
