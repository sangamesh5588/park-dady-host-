-- ================================================================
-- QUICK FIX: Update existing users to HOST role
-- ================================================================
-- Run this in Supabase SQL Editor to fix existing users
-- ================================================================

-- 1. Update existing users to have role='host'
UPDATE public.profiles
SET role = 'host'
WHERE role = 'renter';

-- 2. Update the trigger function to use 'host' role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    'host',
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail user creation
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Verify the changes
SELECT id, full_name, role, created_at
FROM public.profiles
ORDER BY created_at DESC;

-- ================================================================
-- DONE! All users are now hosts
-- ================================================================
