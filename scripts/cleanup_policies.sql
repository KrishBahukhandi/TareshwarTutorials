-- Step 1: Cleanup Script - Run this FIRST
-- This completely removes all RLS policies

-- Drop all existing policies completely
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Temporarily disable RLS to ensure clean slate
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
