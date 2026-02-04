-- ================================================
-- ADMIN PANEL PRODUCTION UPGRADE - DATABASE SCHEMA
-- ================================================
-- This script adds production-grade features:
-- 1. Soft delete columns (is_active, deleted_at)
-- 2. Audit logging table
-- 3. Updated triggers for tracking
-- 4. Enrollment seat limit enforcement
-- ================================================

-- ================================================
-- 1. ADD SOFT DELETE & TRACKING COLUMNS
-- ================================================

-- Add to profiles table
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add to courses table
ALTER TABLE courses 
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add to batches table
ALTER TABLE batches 
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add to enrollments table
ALTER TABLE enrollments 
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add to recorded_videos table
ALTER TABLE recorded_videos 
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add to notes table
ALTER TABLE notes 
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- ================================================
-- 2. CREATE AUDIT LOGS TABLE
-- ================================================

CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  admin_email text,
  action text NOT NULL, -- 'create', 'update', 'delete', 'activate', 'deactivate', 'enroll', 'unenroll'
  resource_type text NOT NULL, -- 'student', 'teacher', 'course', 'batch', 'enrollment', 'content'
  resource_id uuid,
  resource_name text,
  old_data jsonb,
  new_data jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Index for efficient querying
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_type ON admin_audit_logs(resource_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON admin_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_id ON admin_audit_logs(resource_id);

-- ================================================
-- 3. CREATE UPDATED_AT TRIGGERS
-- ================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_courses_updated_at ON courses;
CREATE TRIGGER update_courses_updated_at
  BEFORE UPDATE ON courses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_batches_updated_at ON batches;
CREATE TRIGGER update_batches_updated_at
  BEFORE UPDATE ON batches
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_enrollments_updated_at ON enrollments;
CREATE TRIGGER update_enrollments_updated_at
  BEFORE UPDATE ON enrollments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 4. ENROLLMENT SEAT LIMIT ENFORCEMENT
-- ================================================

-- Function to check batch capacity before enrollment
CREATE OR REPLACE FUNCTION check_batch_seat_availability()
RETURNS TRIGGER AS $$
DECLARE
  batch_seat_limit int;
  current_enrollment_count int;
BEGIN
  -- Get the seat limit for the batch
  SELECT seat_limit INTO batch_seat_limit
  FROM batches
  WHERE id = NEW.batch_id;
  
  -- Count current active enrollments
  SELECT COUNT(*) INTO current_enrollment_count
  FROM enrollments
  WHERE batch_id = NEW.batch_id
    AND is_active = true
    AND deleted_at IS NULL;
  
  -- Check if batch is full (only for INSERT or reactivation)
  IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.is_active = false AND NEW.is_active = true)) THEN
    IF current_enrollment_count >= batch_seat_limit THEN
      RAISE EXCEPTION 'Batch is full. Seat limit: %, Current enrollments: %', batch_seat_limit, current_enrollment_count;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to enrollments table
DROP TRIGGER IF EXISTS check_enrollment_capacity ON enrollments;
CREATE TRIGGER check_enrollment_capacity
  BEFORE INSERT OR UPDATE ON enrollments
  FOR EACH ROW
  EXECUTE FUNCTION check_batch_seat_availability();

-- ================================================
-- 5. HELPER FUNCTIONS FOR ADMIN OPERATIONS
-- ================================================

-- Function to get active enrollment count for a batch
CREATE OR REPLACE FUNCTION get_batch_enrollment_count(batch_uuid uuid)
RETURNS int AS $$
DECLARE
  enrollment_count int;
BEGIN
  SELECT COUNT(*) INTO enrollment_count
  FROM enrollments
  WHERE batch_id = batch_uuid
    AND is_active = true
    AND deleted_at IS NULL;
  
  RETURN enrollment_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get seat availability for a batch
CREATE OR REPLACE FUNCTION get_batch_seat_availability(batch_uuid uuid)
RETURNS TABLE (
  seat_limit int,
  enrolled_count int,
  available_seats int,
  is_full boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.seat_limit,
    CAST(get_batch_enrollment_count(batch_uuid) AS int) as enrolled_count,
    b.seat_limit - get_batch_enrollment_count(batch_uuid) as available_seats,
    get_batch_enrollment_count(batch_uuid) >= b.seat_limit as is_full
  FROM batches b
  WHERE b.id = batch_uuid;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- 6. UPDATE RLS POLICIES FOR SOFT DELETE
-- ================================================

-- Update profiles select policy to exclude deleted records
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
CREATE POLICY "profiles_select_policy" ON profiles
  FOR SELECT
  USING (is_active = true AND deleted_at IS NULL);

-- Update courses select policy
DROP POLICY IF EXISTS "courses_select_policy" ON courses;
CREATE POLICY "courses_select_policy" ON courses
  FOR SELECT
  USING (is_active = true AND deleted_at IS NULL);

-- Update batches select policy
DROP POLICY IF EXISTS "batches_select_policy" ON batches;
CREATE POLICY "batches_select_policy" ON batches
  FOR SELECT
  USING (is_active = true AND deleted_at IS NULL);

-- Update enrollments select policy
DROP POLICY IF EXISTS "enrollments_select_policy" ON enrollments;
CREATE POLICY "enrollments_select_policy" ON enrollments
  FOR SELECT
  USING (is_active = true AND deleted_at IS NULL);

-- Admin can see ALL records (including deleted)
DROP POLICY IF EXISTS "admin_view_all_profiles" ON profiles;
CREATE POLICY "admin_view_all_profiles" ON profiles
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Audit logs are admin-only
DROP POLICY IF EXISTS "audit_logs_admin_only" ON admin_audit_logs;
CREATE POLICY "audit_logs_admin_only" ON admin_audit_logs
  FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- ================================================
-- 7. GRANT PERMISSIONS
-- ================================================

-- Allow authenticated users to read active records
GRANT SELECT ON profiles TO authenticated;
GRANT SELECT ON courses TO authenticated;
GRANT SELECT ON batches TO authenticated;
GRANT SELECT ON enrollments TO authenticated;
GRANT SELECT ON recorded_videos TO authenticated;
GRANT SELECT ON notes TO authenticated;

-- Allow admin to access audit logs
GRANT ALL ON admin_audit_logs TO authenticated;

-- ================================================
-- 8. SEED INITIAL DATA (Optional)
-- ================================================

-- Set all existing records as active if column just added
UPDATE profiles SET is_active = true WHERE is_active IS NULL;
UPDATE courses SET is_active = true WHERE is_active IS NULL;
UPDATE batches SET is_active = true WHERE is_active IS NULL;
UPDATE enrollments SET is_active = true WHERE is_active IS NULL;

-- ================================================
-- VERIFICATION QUERIES
-- ================================================

-- Check seat availability for a batch
-- SELECT * FROM get_batch_seat_availability('batch-uuid-here');

-- View recent audit logs
-- SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT 10;

-- Count active vs inactive records
-- SELECT 
--   'profiles' as table_name,
--   COUNT(*) FILTER (WHERE is_active = true) as active_count,
--   COUNT(*) FILTER (WHERE is_active = false) as inactive_count
-- FROM profiles
-- UNION ALL
-- SELECT 'courses', COUNT(*) FILTER (WHERE is_active = true), COUNT(*) FILTER (WHERE is_active = false) FROM courses;
