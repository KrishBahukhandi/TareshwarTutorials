-- ============================================================
-- CREATE STORAGE BUCKETS + POLICIES
-- Run this in Supabase SQL Editor
-- Creates: notes-pdfs, recorded-videos
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Create the buckets (skip if already exist)
-- ────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'notes-pdfs',
  'notes-pdfs',
  false,
  52428800,  -- 50 MB limit
  ARRAY['application/pdf','application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation']
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'recorded-videos',
  'recorded-videos',
  false,
  524288000,  -- 500 MB limit
  ARRAY['video/mp4','video/quicktime','video/x-msvideo','video/webm']
)
ON CONFLICT (id) DO NOTHING;

-- ────────────────────────────────────────────────────────────
-- 2. Storage policies for notes-pdfs
-- ────────────────────────────────────────────────────────────

-- Drop old policies if any
DROP POLICY IF EXISTS "notes_pdfs_teacher_upload" ON storage.objects;
DROP POLICY IF EXISTS "notes_pdfs_authenticated_read" ON storage.objects;
DROP POLICY IF EXISTS "notes_pdfs_teacher_delete" ON storage.objects;

-- Teachers can upload to notes-pdfs
CREATE POLICY "notes_pdfs_teacher_upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'notes-pdfs'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- All authenticated users can read notes-pdfs (students view their batch notes)
CREATE POLICY "notes_pdfs_authenticated_read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'notes-pdfs');

-- Teachers and admins can delete from notes-pdfs
CREATE POLICY "notes_pdfs_teacher_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'notes-pdfs'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- Teachers and admins can update/overwrite in notes-pdfs
CREATE POLICY "notes_pdfs_teacher_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'notes-pdfs'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- ────────────────────────────────────────────────────────────
-- 3. Storage policies for recorded-videos
-- ────────────────────────────────────────────────────────────

-- Drop old policies if any
DROP POLICY IF EXISTS "recorded_videos_teacher_upload" ON storage.objects;
DROP POLICY IF EXISTS "recorded_videos_authenticated_read" ON storage.objects;
DROP POLICY IF EXISTS "recorded_videos_teacher_delete" ON storage.objects;
DROP POLICY IF EXISTS "recorded_videos_teacher_update" ON storage.objects;

-- Teachers can upload to recorded-videos
CREATE POLICY "recorded_videos_teacher_upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'recorded-videos'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- All authenticated users can read recorded-videos
CREATE POLICY "recorded_videos_authenticated_read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'recorded-videos');

-- Teachers and admins can delete from recorded-videos
CREATE POLICY "recorded_videos_teacher_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'recorded-videos'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- Teachers and admins can update/overwrite in recorded-videos
CREATE POLICY "recorded_videos_teacher_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'recorded-videos'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('teacher', 'admin')
    )
  );

-- ────────────────────────────────────────────────────────────
-- Verify:
--   SELECT id, name, public, file_size_limit FROM storage.buckets;
-- ────────────────────────────────────────────────────────────
