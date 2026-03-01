# 🎓 Tareshwar Tutorials – Demo Guide

## Demo Accounts

| Role    | Email                    | Password      |
|---------|--------------------------|---------------|
| Admin   | admin@edutech.test       | ChangeMe123!  |
| Teacher | teacher@edutech.test     | ChangeMe123!  |
| Student | student@edutech.test     | ChangeMe123!  |

> **Quick Login:** The login screen has one-click demo buttons for each role.

---

## Pre-Seeded Demo Data

### Courses
| Title                                    | Status    |
|------------------------------------------|-----------|
| Class 10 Mathematics – Board Prep        | Published |
| Class 12 Physics – JEE Foundation        | Published |
| Class 9 Science – CBSE                   | Draft     |

### Batches
| Course                              | Start Date   | End Date     | Seats |
|-------------------------------------|--------------|--------------|-------|
| Class 10 Mathematics – Board Prep   | 31 Jan 2026  | 29 Jun 2026  | 30    |
| Class 10 Mathematics – Board Prep   | 14 Mar 2026  | 29 Jul 2026  | 25    |
| Class 12 Physics – JEE Foundation   | 31 Dec 2025  | 28 May 2026  | 20    |

### Enrollments (student@edutech.test)
- Class 10 Mathematics – Board Prep (Batch 1)
- Class 10 Mathematics – Board Prep (Batch 2)

---

## Demo Run-of-Show

### 1. Admin Flow (~5 min)
1. Login as **Admin** → Dashboard shows stats (courses, students, teachers)
2. **Courses** → See 3 seeded courses; create a new course; publish it
3. **Batches** → See batches with course names; create a new batch
4. **Students** → View student list with search/filter; create a new student
5. **Teachers** → View teacher list; create a new teacher
6. **Enrollments** → Select a batch → enroll / unenroll a student

### 2. Teacher Flow (~4 min)
1. Login as **Teacher (Rajesh Kumar)** → Dashboard shows assigned batches + stats
2. **My Content** → See uploaded videos / notes (empty initially)
3. **Upload Video** → Select a batch → fill title → pick a video file → upload
4. **Upload Notes** → Select a batch → fill title → pick a PDF → upload
5. Verify content appears in the content list with batch/course label

### 3. Student Flow (~4 min)
1. Login as **Student (Priya Sharma)** → Dashboard shows 2 enrolled courses
2. **My Courses** → Two course cards visible → click one
3. **Batch Content** → Videos tab and Notes tab shown
   - Videos: tap any video → opens in browser tab (web) / native player (mobile)
   - Notes: tap a note → opens PDF in browser
4. Back navigation works correctly throughout

---

## Known Limitations (by design for this demo)
- **Live Class** feature is not implemented (out of scope)
- Storage bucket must have public policy or signed URLs work (6-hour expiry)
- Admin Students List "deactivate" requires running `scripts/fix_profiles_columns_and_rls.sql` in Supabase (adds `is_active` column to profiles)

---

## Required One-Time Setup

Run this SQL in the **Supabase SQL Editor** before the demo:
```
https://supabase.com/dashboard/project/cyfwcgsfdlecnkycpjsk/sql/new
```
Copy-paste the contents of: **`scripts/fix_profiles_columns_and_rls.sql`**

This adds `is_active` and `deleted_at` columns to `profiles` and fixes admin RLS.

---

## Re-seed Demo Data
```bash
node scripts/seed_users.mjs     # creates demo accounts (idempotent)
node scripts/seed_demo_data.mjs # creates courses, batches, enrollments (idempotent)
```

---

## Deployment (Vercel)
- Branch `test-main` auto-deploys to Vercel on every push
- `vercel.json` handles Flutter web build + SPA rewrites
- Environment variables are baked into the compiled app (Supabase URL + anon key)
