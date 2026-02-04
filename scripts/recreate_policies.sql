-- Step 2: Recreate RLS Policies - Run this AFTER cleanup
-- This creates fresh, correct RLS policies

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies with proper syntax to avoid infinite recursion
CREATE POLICY "profiles_select_policy"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "profiles_insert_policy" 
ON profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_policy"
ON profiles FOR UPDATE  
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
