-- Fix for infinite recursion in RLS policies
-- Run this to fix the courses and other policies causing recursion

-- Drop problematic policies
DROP POLICY IF EXISTS "admin_view_all_profiles" ON profiles;
DROP POLICY IF EXISTS "audit_logs_admin_only" ON admin_audit_logs;

-- Better approach: Create policies that don't query the same table
-- Admin view all profiles - use JWT claim instead
CREATE POLICY "admin_view_all_profiles" ON profiles
  FOR SELECT
  USING (
    (SELECT auth.jwt()->>'role') = 'admin'
  );

-- Audit logs admin only
CREATE POLICY "audit_logs_admin_only" ON admin_audit_logs
  FOR ALL
  USING (
    (SELECT auth.jwt()->>'role') = 'admin'
  );

-- If the above doesn't work (JWT doesn't have role), use this alternative:
-- Store admin status in auth.users metadata instead of querying profiles table
-- Or disable RLS on these tables for authenticated users and handle in application code
