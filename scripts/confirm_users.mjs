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

const emails = [
  'admin@edutech.test',
  'teacher@edutech.test',
  'student@edutech.test',
];

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

async function main() {
  for (const email of emails) {
    const user = await findUserByEmail(email);
    if (!user) {
      console.log(`User not found: ${email}`);
      continue;
    }
    const { error } = await supabase.auth.admin.updateUserById(user.id, {
      email_confirm: true,
    });
    if (error) throw error;
    console.log(`Confirmed email: ${email}`);
  }
}

main().catch((err) => {
  console.error('Confirm failed:', err.message ?? err);
  process.exit(1);
});
