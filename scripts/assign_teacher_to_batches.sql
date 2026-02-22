-- ============================================================
-- ASSIGN TEACHER TO BATCHES
-- Run this AFTER fix_courses_rls_and_seed.sql
-- Replace the email below with your actual teacher's email.
-- ============================================================

-- Step 1: Check your teacher's user ID
SELECT id, name, email FROM public.profiles WHERE role = 'teacher';

-- Step 2: Assign that teacher to all unassigned batches
-- Replace 'your-teacher@email.com' with the actual teacher email
UPDATE public.batches
SET teacher_id = (
  SELECT id FROM public.profiles
  WHERE email = 'your-teacher@email.com'
    AND role = 'teacher'
  LIMIT 1
)
WHERE teacher_id IS NULL;

-- Step 3: Verify
SELECT b.id, c.title, p.name AS teacher, b.start_date
FROM public.batches b
JOIN public.courses c ON c.id = b.course_id
LEFT JOIN public.profiles p ON p.id = b.teacher_id;
