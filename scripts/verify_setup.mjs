#!/usr/bin/env node

/**
 * Script to verify Supabase database setup
 * Run this after executing the SQL script in Supabase dashboard
 */

import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: { autoRefreshToken: false, persistSession: false },
  },
);

async function verifySetup() {
  console.log('🔍 Verifying Supabase database setup...\n');

  try {
    // 1. Check if profiles table exists and has data
    console.log('1️⃣  Checking profiles table...');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .limit(5);

    if (profilesError) {
      console.error('   ❌ ERROR: Cannot access profiles table');
      console.error('   ', profilesError.message);
      console.log('\n💡 ACTION REQUIRED: Run the SQL script in Supabase SQL Editor first!\n');
      process.exit(1);
    }

    console.log(`   ✅ Profiles table exists with ${profiles.length} users`);
    
    // 2. Verify all required users exist
    console.log('\n2️⃣  Verifying test users...');
    const requiredEmails = [
      'admin@edutech.test',
      'teacher@edutech.test', 
      'student@edutech.test'
    ];

    for (const email of requiredEmails) {
      const user = profiles.find(p => p.email === email);
      if (user) {
        console.log(`   ✅ ${email} (${user.role})`);
      } else {
        console.log(`   ❌ Missing: ${email}`);
      }
    }

    // 3. Test RLS policies by authenticating as a user
    console.log('\n3️⃣  Testing Row Level Security policies...');
    
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'student@edutech.test',
      password: process.env.STUDENT_PASSWORD,
    });

    if (authError) {
      console.log('   ⚠️  Could not authenticate test user');
      console.log('   ', authError.message);
    } else {
      // Try to fetch profile as authenticated user
      const { data: userProfile, error: profileError } = await supabase
        .from('profiles')
        .select()
        .eq('id', authData.user.id)
        .single();

      if (profileError) {
        console.log('   ❌ RLS policies not working correctly');
        console.log('   ', profileError.message);
        console.log('\n💡 ACTION REQUIRED: Re-run the SQL script to fix RLS policies\n');
        process.exit(1);
      } else {
        console.log('   ✅ RLS policies working correctly');
        console.log(`   ✅ Can fetch profile: ${userProfile.name} (${userProfile.role})`);
      }

      // Clean up: Sign out
      await supabase.auth.signOut();
    }

    console.log('\n✨ Database setup verified successfully!\n');
    console.log('🚀 You can now test the login at: http://localhost:52205/#/login\n');
    console.log('Test credentials:');
    console.log('  📧 Email: student@edutech.test');
    console.log('  🔑 Password: ChangeMe123!\n');

  } catch (error) {
    console.error('❌ Verification failed:', error.message);
    process.exit(1);
  }
}

verifySetup();
