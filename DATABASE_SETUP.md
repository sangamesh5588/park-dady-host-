# Database Setup Instructions

## Supabase Database Configuration

Your app requires a `profiles` table in Supabase. Follow these steps to set it up:

### 1. Create the Profiles Table

Go to your Supabase project dashboard and run this SQL query in the SQL Editor:

```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  role TEXT DEFAULT 'host',
  full_name TEXT,
  phone_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles table
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Optional: Create function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'host');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to call the function on new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### 2. Verify Configuration

1. Go to **Table Editor** in Supabase dashboard
2. Confirm the `profiles` table exists
3. Check that RLS policies are enabled
4. Test by creating a new user account

### 3. Current Status

Your Supabase credentials are configured in `.env`:
- **SUPABASE_URL**: https://eivjgwxyijhfmnyrcbcb.supabase.co
- **SUPABASE_ANON_KEY**: Configured ✓

### 4. Troubleshooting

If you're still experiencing crashes:

1. **Check Supabase Logs**: Go to Supabase dashboard → Logs to see database errors
2. **Verify Authentication**: Make sure users can sign up/sign in successfully
3. **Test Database Connection**: Try running a simple query in the SQL Editor
4. **Check RLS Policies**: Ensure policies allow authenticated users to access their profiles

### 5. Testing

After setup, test these scenarios:
1. Sign up a new user → Profile should be auto-created
2. Sign in → Home screen should load without crashes
3. View profile data → Email and role should display correctly

## Need Help?

If you continue to experience issues, check:
- Supabase project status (not paused)
- Network connectivity
- Error messages in Flutter debug console
