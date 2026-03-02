/**
 * seed_demo_data.mjs
 * Seeds demo courses, batches, enrollments, and placeholder content records
 * so the app is fully populated for a client demo.
 *
 * Run:  node scripts/seed_demo_data.mjs
 */

import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const requiredEnv = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
for (const key of requiredEnv) {
  if (!process.env[key]) {
    console.error(`Missing env var: ${key}`);
    process.exit(1);
  }
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

// ─── helpers ────────────────────────────────────────────────────────────────

async function findUserByEmail(email) {
  let page = 1;
  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw error;
    const found = data.users.find((u) => u.email === email);
    if (found) return found;
    if (data.users.length < 1000) return null;
    page++;
  }
}

function log(msg) {
  console.log(`[seed] ${msg}`);
}

// ─── main ────────────────────────────────────────────────────────────────────

async function main() {
  // 1. Fetch demo user IDs
  const teacherUser = await findUserByEmail(process.env.TEACHER_EMAIL || 'teacher@edutech.test');
  const studentUser = await findUserByEmail(process.env.STUDENT_EMAIL || 'student@edutech.test');
  const adminUser   = await findUserByEmail(process.env.ADMIN_EMAIL   || 'admin@edutech.test');

  if (!teacherUser) throw new Error('Teacher user not found – run seed_users.mjs first');
  if (!studentUser) throw new Error('Student user not found – run seed_users.mjs first');

  log(`Teacher ID : ${teacherUser.id}`);
  log(`Student ID : ${studentUser.id}`);
  if (adminUser) log(`Admin ID   : ${adminUser.id}`);

  // 2. Upsert teacher profile with name
  await supabase.from('profiles').upsert({
    id: teacherUser.id,
    name: 'Rajesh Kumar',
    email: teacherUser.email,
    role: 'teacher',
    is_active: true,
  });
  log('Teacher profile ready');

  await supabase.from('profiles').upsert({
    id: studentUser.id,
    name: 'Priya Sharma',
    email: studentUser.email,
    role: 'student',
  });
  log('Student profile ready');

  if (adminUser) {
    await supabase.from('profiles').upsert({
      id: adminUser.id,
      name: 'Admin User',
      email: adminUser.email,
      role: 'admin',
    });
    log('Admin profile ready');
  }

  // 3. Upsert courses
  const courses = [
    {
      title: 'Class 10 Mathematics – Board Prep',
      description: 'Complete NCERT-aligned preparation for Class 10 Maths including Algebra, Geometry, Trigonometry, and Statistics.',
      is_published: true,
      created_by: adminUser?.id ?? teacherUser.id,
    },
    {
      title: 'Class 12 Physics – JEE Foundation',
      description: 'In-depth Physics for Class 12 with focus on Mechanics, Electrostatics, and Optics for JEE preparation.',
      is_published: true,
      created_by: adminUser?.id ?? teacherUser.id,
    },
    {
      title: 'Class 9 Science – CBSE',
      description: 'Foundational Science covering Physics, Chemistry, and Biology for Class 9 CBSE students.',
      is_published: false,
      created_by: adminUser?.id ?? teacherUser.id,
    },
  ];

  const insertedCourses = [];
  for (const course of courses) {
    // Check if course already exists
    const { data: existing } = await supabase
      .from('courses')
      .select('id, title')
      .eq('title', course.title)
      .maybeSingle();

    if (existing) {
      log(`Course already exists: "${course.title}" (${existing.id})`);
      insertedCourses.push(existing);
    } else {
      const { data, error } = await supabase
        .from('courses')
        .insert(course)
        .select()
        .single();
      if (error) throw new Error(`Failed to insert course "${course.title}": ${error.message}`);
      log(`Created course: "${course.title}" (${data.id})`);
      insertedCourses.push(data);
    }
  }

  // 4. Upsert batches
  const today = new Date();
  const batchDefs = [
    {
      courseIndex: 0,
      start_date: new Date(today.getFullYear(), today.getMonth() - 1, 1).toISOString().split('T')[0],
      end_date:   new Date(today.getFullYear(), today.getMonth() + 3, 30).toISOString().split('T')[0],
      seat_limit: 30,
    },
    {
      courseIndex: 0,
      start_date: new Date(today.getFullYear(), today.getMonth(), 15).toISOString().split('T')[0],
      end_date:   new Date(today.getFullYear(), today.getMonth() + 4, 30).toISOString().split('T')[0],
      seat_limit: 25,
    },
    {
      courseIndex: 1,
      start_date: new Date(today.getFullYear(), today.getMonth() - 2, 1).toISOString().split('T')[0],
      end_date:   new Date(today.getFullYear(), today.getMonth() + 2, 28).toISOString().split('T')[0],
      seat_limit: 20,
    },
  ];

  const insertedBatches = [];
  for (const bd of batchDefs) {
    const course = insertedCourses[bd.courseIndex];
    const { courseIndex, ...batchData } = bd;

    const { data: existing } = await supabase
      .from('batches')
      .select('id')
      .eq('course_id', course.id)
      .eq('start_date', batchData.start_date)
      .eq('teacher_id', teacherUser.id)
      .maybeSingle();

    if (existing) {
      log(`Batch already exists for course "${course.title}" starting ${batchData.start_date} (${existing.id})`);
      insertedBatches.push({ ...existing, course_id: course.id });
    } else {
      const { data, error } = await supabase
        .from('batches')
        .insert({
          ...batchData,
          course_id: course.id,
          teacher_id: teacherUser.id,
        })
        .select()
        .single();
      if (error) throw new Error(`Failed to insert batch for "${course.title}": ${error.message}`);
      log(`Created batch for "${course.title}" starting ${batchData.start_date} (${data.id})`);
      insertedBatches.push(data);
    }
  }

  // 5. Enroll student in first two batches
  for (const batch of insertedBatches.slice(0, 2)) {
    const { data: existing } = await supabase
      .from('enrollments')
      .select('id')
      .eq('student_id', studentUser.id)
      .eq('batch_id', batch.id)
      .maybeSingle();

    if (existing) {
      log(`Student already enrolled in batch ${batch.id}`);
    } else {
      const { error } = await supabase.from('enrollments').insert({
        student_id: studentUser.id,
        batch_id: batch.id,
        enrolled_at: new Date().toISOString(),
      });
      if (error) throw new Error(`Failed to enroll student in batch ${batch.id}: ${error.message}`);
      log(`Enrolled student in batch: ${batch.id}`);
    }
  }

  // 6. Done
  log('');
  log('✅ Demo data seeded successfully!');
  log('');
  log('Demo accounts:');
  log(`  Admin   : ${process.env.ADMIN_EMAIL   || 'admin@edutech.test'}  / ${process.env.ADMIN_PASSWORD   || 'ChangeMe123!'}`);
  log(`  Teacher : ${process.env.TEACHER_EMAIL || 'teacher@edutech.test'} / ${process.env.TEACHER_PASSWORD || 'ChangeMe123!'}`);
  log(`  Student : ${process.env.STUDENT_EMAIL || 'student@edutech.test'} / ${process.env.STUDENT_PASSWORD || 'ChangeMe123!'}`);
}

main().catch((err) => {
  console.error('Seed failed:', err.message ?? err);
  process.exit(1);
});
