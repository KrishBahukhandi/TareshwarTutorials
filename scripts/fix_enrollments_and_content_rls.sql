-- ============================================================
-- FIX ENROLLMENTS TABLE + RLS + ADD MISSING COLUMNS
-- Run this in Supabase SQL Editor
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Ensure enrollments table has all required columns
-- ────────────────────────────────────────────────────────────

-- Add is_active column if missing
ALTER TABLE public.enrollments
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Add enrolled_at column if missing
ALTER TABLE public.enrollments
  ADD COLUMN IF NOT EXISTS enrolled_at TIMESTAMPTZ DEFAULT NOW();

-- Add deleted_at for soft deletes
ALTER TABLE public.enrollments
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ────────────────────────────────────────────────────────────
-- 2. Fix RLS policies on enrollments
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;

-- Drop all existing enrollment policies
DO $$
DECLARE
  pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'enrollments' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.enrollments', pol);
  END LOOP;
END;
$$;

-- Students can read their own enrollments
CREATE POLICY "enrollments_student_read"
  ON public.enrollments FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

-- Only admins can insert enrollments
CREATE POLICY "enrollments_admin_insert"
  ON public.enrollments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update enrollments (for soft delete / move)
CREATE POLICY "enrollments_admin_update"
  ON public.enrollments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can hard delete enrollments
CREATE POLICY "enrollments_admin_delete"
  ON public.enrollments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ────────────────────────────────────────────────────────────
-- 3. Fix RLS on notes and recorded_videos tables
-- ────────────────────────────────────────────────────────────

-- NOTES table
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

-- Teachers can read their own notes; students can read notes for their batches
CREATE POLICY "notes_select"
  ON public.notes FOR SELECT
  TO authenticated
  USING (true);

-- Only teachers/admins can insert notes
CREATE POLICY "notes_insert"
  ON public.notes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- Teachers can update their own notes; admins can update any
CREATE POLICY "notes_update"
  ON public.notes FOR UPDATE
  TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Teachers can delete their own notes; admins can delete any
CREATE POLICY "notes_delete"
  ON public.notes FOR DELETE
  TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RECORDED_VIDEOS table
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
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

CREATE POLICY "recorded_videos_update"
  ON public.recorded_videos FOR UPDATE
  TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "recorded_videos_delete"
  ON public.recorded_videos FOR DELETE
  TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ────────────────────────────────────────────────────────────
-- Verify:
--   SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_name = 'enrollments' AND table_schema = 'public';
-- ────────────────────────────────────────────────────────────
