-- ============================================================
-- FIX COURSES RLS (infinite recursion) + SEED MOCK DATA
-- Actual courses schema: id, title, description, price,
--                        created_by, is_published, created_at
-- Actual batches schema: id, course_id, teacher_id,
--                        start_date, end_date, seat_limit, created_at
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. DROP all existing policies on 'courses' to start fresh
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE
  pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'courses' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.courses', pol);
  END LOOP;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 2. Re-create clean, non-recursive policies on 'courses'
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read courses (USING true = no subquery, no recursion)
CREATE POLICY "courses_select_all"
  ON public.courses FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can insert
CREATE POLICY "courses_insert_admin"
  ON public.courses FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update
CREATE POLICY "courses_update_admin"
  ON public.courses FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can delete
CREATE POLICY "courses_delete_admin"
  ON public.courses FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ────────────────────────────────────────────────────────────
-- 3. DROP all existing policies on 'batches' and re-create
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE
  pol TEXT;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'batches' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.batches', pol);
  END LOOP;
END;
$$;

ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read batches
CREATE POLICY "batches_select_all"
  ON public.batches FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can insert batches
CREATE POLICY "batches_insert_admin"
  ON public.batches FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update batches
CREATE POLICY "batches_update_admin"
  ON public.batches FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can delete batches
CREATE POLICY "batches_delete_admin"
  ON public.batches FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ────────────────────────────────────────────────────────────
-- 4. Grab the admin user id (used as created_by for courses)
--    and teacher user id (used as teacher_id for batches)
-- ────────────────────────────────────────────────────────────

-- Insert 4 mock courses using the admin's profile id as created_by
-- (skips each one if a course with the same title already exists)

INSERT INTO public.courses (title, description, price, created_by, is_published)
SELECT
  'Data Structures & Algorithms',
  'Master arrays, trees, graphs and dynamic programming.',
  4999,
  (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1),
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.courses WHERE title = 'Data Structures & Algorithms'
);

INSERT INTO public.courses (title, description, price, created_by, is_published)
SELECT
  'Full Stack Web Development',
  'Build complete web apps with React, Node.js and PostgreSQL.',
  6999,
  (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1),
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.courses WHERE title = 'Full Stack Web Development'
);

INSERT INTO public.courses (title, description, price, created_by, is_published)
SELECT
  'Python for Data Science',
  'Learn Python, Pandas, NumPy and Matplotlib for data analysis.',
  3999,
  (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1),
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.courses WHERE title = 'Python for Data Science'
);

INSERT INTO public.courses (title, description, price, created_by, is_published)
SELECT
  'Digital Marketing Fundamentals',
  'SEO, SEM, social media and email marketing strategies.',
  2999,
  (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1),
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.courses WHERE title = 'Digital Marketing Fundamentals'
);

-- ────────────────────────────────────────────────────────────
-- 5. INSERT one batch per course using the first teacher's id.
--    Batches schema: course_id, teacher_id, start_date,
--                   end_date, seat_limit
-- ────────────────────────────────────────────────────────────

INSERT INTO public.batches (course_id, teacher_id, start_date, end_date, seat_limit)
SELECT
  c.id,
  (SELECT id FROM public.profiles WHERE role = 'teacher' LIMIT 1),
  '2025-06-01'::date,
  '2025-09-01'::date,
  30
FROM public.courses c
WHERE c.title = 'Data Structures & Algorithms'
  AND NOT EXISTS (
    SELECT 1 FROM public.batches b
    WHERE b.course_id = c.id AND b.start_date = '2025-06-01'
  );

INSERT INTO public.batches (course_id, teacher_id, start_date, end_date, seat_limit)
SELECT
  c.id,
  (SELECT id FROM public.profiles WHERE role = 'teacher' LIMIT 1),
  '2025-07-01'::date,
  '2025-11-01'::date,
  25
FROM public.courses c
WHERE c.title = 'Full Stack Web Development'
  AND NOT EXISTS (
    SELECT 1 FROM public.batches b
    WHERE b.course_id = c.id AND b.start_date = '2025-07-01'
  );

INSERT INTO public.batches (course_id, teacher_id, start_date, end_date, seat_limit)
SELECT
  c.id,
  (SELECT id FROM public.profiles WHERE role = 'teacher' LIMIT 1),
  '2025-08-01'::date,
  '2025-10-15'::date,
  20
FROM public.courses c
WHERE c.title = 'Python for Data Science'
  AND NOT EXISTS (
    SELECT 1 FROM public.batches b
    WHERE b.course_id = c.id AND b.start_date = '2025-08-01'
  );

INSERT INTO public.batches (course_id, teacher_id, start_date, end_date, seat_limit)
SELECT
  c.id,
  (SELECT id FROM public.profiles WHERE role = 'teacher' LIMIT 1),
  '2025-09-01'::date,
  '2025-10-31'::date,
  40
FROM public.courses c
WHERE c.title = 'Digital Marketing Fundamentals'
  AND NOT EXISTS (
    SELECT 1 FROM public.batches b
    WHERE b.course_id = c.id AND b.start_date = '2025-09-01'
  );

-- ────────────────────────────────────────────────────────────
-- Verify with:
--   SELECT * FROM public.courses;
--   SELECT b.id, c.title, p.name AS teacher, b.start_date, b.seat_limit
--   FROM public.batches b
--   JOIN public.courses c ON c.id = b.course_id
--   LEFT JOIN public.profiles p ON p.id = b.teacher_id;
-- ────────────────────────────────────────────────────────────
