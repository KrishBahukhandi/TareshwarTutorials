import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const requiredEnv = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'ADMIN_EMAIL',
  'ADMIN_PASSWORD',
  'TEACHER_EMAIL',
  'TEACHER_PASSWORD',
  'STUDENT_EMAIL',
  'STUDENT_PASSWORD',
];

for (const key of requiredEnv) {
  if (!process.env[key]) {
    console.error(`Missing env var: ${key}`);
    process.exit(1);
  }
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: { autoRefreshToken: false, persistSession: false },
  },
);

async function findUserByEmail(email) {
  let page = 1;
  const perPage = 1000;
  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page,
      perPage,
    });
    if (error) throw error;
    const found = data.users.find((u) => u.email === email);
    if (found) return found;
    if (data.users.length < perPage) return null;
    page += 1;
  }
}

async function ensureUser({ email, password, role }) {
  let user = await findUserByEmail(email);
  if (!user) {
    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (error) throw error;
    user = data.user;
    console.log(`Created user: ${email}`);
  } else {
    console.log(`User already exists: ${email}`);
  }

  const { error: profileError } = await supabase.from('profiles').upsert({
    id: user.id,
    name: email.split('@')[0],
    email,
    role,
  });
  if (profileError) throw profileError;

  console.log(`Profile upserted with role: ${role}`);
}

async function main() {
  await ensureUser({
    email: process.env.ADMIN_EMAIL,
    password: process.env.ADMIN_PASSWORD,
    role: 'admin',
  });

  await ensureUser({
    email: process.env.TEACHER_EMAIL,
    password: process.env.TEACHER_PASSWORD,
    role: 'teacher',
  });

  await ensureUser({
    email: process.env.STUDENT_EMAIL,
    password: process.env.STUDENT_PASSWORD,
    role: 'student',
  });

  console.log('Seed complete.');
}

main().catch((err) => {
  console.error('Seed failed:', err.message ?? err);
  process.exit(1);
});
