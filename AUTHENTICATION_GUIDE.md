# Authentication System Guide

This guide will help you set up and test the authentication system for the Parking Host app.

## Prerequisites

Before testing authentication, ensure you have:

1. ✅ Flutter installed and configured
2. ✅ A Supabase project created
3. ✅ `.env` file configured with your Supabase credentials
4. ✅ Database tables created (see [supabase/README.md](supabase/README.md))

## Step 1: Set Up the Database

### Option A: Using Supabase Dashboard (Quick)

1. Go to your Supabase Dashboard: https://app.supabase.com/project/eivjgwxyijhfmnyrcbcb
2. Click on **SQL Editor** in the left sidebar
3. Open the file `supabase/migrations/20250101000000_initial_schema.sql`
4. Copy all the SQL code
5. Paste it into the SQL Editor in Supabase
6. Click **Run** to execute

### Option B: Using Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Link your project
supabase link --project-ref eivjgwxyijhfmnyrcbcb

# Apply the migration
supabase db push
```

### Verify Database Setup

After running the migration, verify in your Supabase dashboard:

1. Go to **Table Editor**
2. Confirm these tables exist:
   - `profiles` - User profiles with email and role
   - `parking_spots` - Parking spot listings
   - `bookings` - Booking records

## Step 2: Configure Authentication Settings in Supabase

### Disable Email Confirmation (for testing only)

If you want to test without email confirmation:

1. Go to **Authentication** > **Providers** in your Supabase dashboard
2. Click on **Email** provider
3. Scroll down to **Email Confirmation**
4. Toggle **OFF** "Confirm email"
5. Click **Save**

⚠️ **Note:** For production, you should enable email confirmation for security.

### Enable Email Confirmation (for production)

For production apps:

1. Keep email confirmation **enabled**
2. Configure your email templates in **Authentication** > **Email Templates**
3. Users will need to confirm their email before logging in

## Step 3: Test the Authentication Flow

### Test 1: Sign Up with Email

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Navigate to Sign Up:**
   - Tap "Sign up" on the splash screen or login screen

3. **Enter test credentials:**
   - Email: `test@example.com`
   - Password: `password123`
   - Confirm Password: `password123`

4. **Tap "Create Account"**

5. **Expected Results:**
   - ✅ **If email confirmation is DISABLED:**
     - You should see: "Account created successfully!"
     - You'll be automatically logged in
     - You'll be redirected to the Home Screen

   - ✅ **If email confirmation is ENABLED:**
     - You should see: "Please check your email to confirm your account"
     - You'll be redirected to the login screen
     - Check your email inbox for the confirmation link
     - Click the link to confirm your account

6. **Verify in Supabase:**
   - Go to **Authentication** > **Users**
   - You should see your new user listed
   - Go to **Table Editor** > **profiles**
   - You should see a profile entry with:
     - `id`: User's UUID
     - `email`: test@example.com
     - `role`: host
     - `created_at`: Current timestamp

### Test 2: Sign In with Email

1. **If already logged in, sign out:**
   - Navigate to home screen
   - Tap on settings/profile
   - Tap "Sign Out"

2. **On Login Screen, enter:**
   - Email: `test@example.com`
   - Password: `password123`

3. **Tap "Sign In"**

4. **Expected Results:**
   - ✅ You should see: "Signed in successfully!"
   - ✅ You'll be redirected to the Home Screen
   - ✅ Your session should persist (even if you close and reopen the app)

### Test 3: Error Handling

#### Test Invalid Credentials

1. On login screen, enter:
   - Email: `test@example.com`
   - Password: `wrongpassword`
2. Tap "Sign In"
3. **Expected:** "Invalid email or password. Please try again."

#### Test Duplicate Email

1. Navigate to sign up screen
2. Try to sign up with an email that already exists
3. **Expected:** "This email is already registered. Please sign in instead."

#### Test Weak Password

1. Navigate to sign up screen
2. Enter:
   - Email: `new@example.com`
   - Password: `123` (less than 6 characters)
3. **Expected:** Form validation error: "Password must be at least 6 characters"

#### Test Invalid Email Format

1. Navigate to sign up screen
2. Enter:
   - Email: `invalidemail` (no @ symbol)
   - Password: `password123`
3. **Expected:** Form validation error: "Please enter a valid email"

### Test 4: Session Persistence

1. **Log in to the app**
2. **Close the app completely** (swipe away from recent apps)
3. **Reopen the app**
4. **Expected Result:**
   - ✅ You should remain logged in
   - ✅ You should be on the Home Screen (not login screen)

### Test 5: Profile Creation

1. **Sign up with a new account**
2. **Check Supabase Table Editor:**
   - Open **profiles** table
   - Find your user's entry
3. **Expected Result:**
   - ✅ Profile automatically created via database trigger
   - ✅ Contains: id, email, role ('host'), timestamps

## Step 4: Common Issues and Solutions

### Issue: "NotInitializedError"

**Cause:** `.env` file not loaded properly

**Solution:**
1. Ensure `.env` is in the root directory
2. Check `pubspec.yaml` has:
   ```yaml
   assets:
     - .env
   ```
3. Run `flutter clean && flutter pub get`
4. Restart the app completely

### Issue: "Invalid login credentials" on signup

**Cause:** Email confirmation might be required

**Solution:**
1. Check your email for confirmation link
2. Or disable email confirmation in Supabase (see Step 2)

### Issue: Profile not created in database

**Cause:** Database trigger might not be set up

**Solution:**
1. Re-run the SQL migration from `supabase/migrations/20250101000000_initial_schema.sql`
2. Verify the `handle_new_user()` function exists in Supabase SQL Editor

### Issue: "Row Level Security" errors

**Cause:** RLS policies might not be configured

**Solution:**
1. Ensure the migration SQL was run completely
2. Check that RLS policies are active in **Authentication** > **Policies**

## Step 5: Testing with Multiple Users

### Create a Second User Account

1. Sign out from the first account
2. Sign up with different email: `test2@example.com`
3. Verify both users exist in Supabase

### Verify Data Isolation

1. Each user should only see their own:
   - Profile data
   - Parking spots (when created)
   - Bookings (when created)

## Features Implemented

### ✅ Email/Password Authentication
- User registration with email and password
- Email validation
- Password strength validation (minimum 6 characters)
- Password confirmation matching

### ✅ User Profile Management
- Automatic profile creation on signup (via database trigger)
- Profile linked to Supabase Auth user
- Role-based system (host/guest)
- Email stored in profile

### ✅ Session Management
- Automatic session persistence
- Auth state listeners for navigation
- Automatic logout on session expiry

### ✅ Error Handling
- User-friendly error messages
- Validation for all input fields
- Proper error handling for network issues

### ✅ Database Integration
- User profiles stored in Supabase
- Row Level Security (RLS) enabled
- Automatic triggers for profile creation
- Prepared for parking spots and bookings

### ✅ Security Features
- Row Level Security on all tables
- Users can only access their own data
- Email confirmation support (optional)
- Secure password handling via Supabase Auth

## Next Steps

After authentication is working:

1. **Test Google Sign-In** (requires Google Cloud Console setup)
2. **Test Apple Sign-In** (requires Apple Developer account)
3. **Create Parking Spots** (host functionality)
4. **Create Bookings** (guest functionality)
5. **Add profile editing** (update name, phone, etc.)

## Support

If you encounter any issues:

1. Check the Flutter console for error messages
2. Check Supabase dashboard logs (**Logs** > **Auth Logs**)
3. Verify your `.env` configuration
4. Ensure all database tables and policies are set up correctly
