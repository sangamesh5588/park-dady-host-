-- ================================================================
-- DUAL ROLE SYSTEM: Support both Renter and Host functionality
-- ================================================================
-- This allows users to be BOTH renters and hosts
-- The app context determines which features they see
-- ================================================================

-- 1. Make role nullable and remove default
ALTER TABLE public.profiles
ALTER COLUMN role DROP DEFAULT,
ALTER COLUMN role DROP NOT NULL;

-- 2. Add new columns to track dual roles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_renter BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_host BOOLEAN NOT NULL DEFAULT FALSE;

-- 3. Update existing users
-- Users from renter app become renters
-- Users from host app become hosts
UPDATE public.profiles
SET is_renter = (role = 'renter'),
    is_host = (role = 'host');

-- 4. Update the trigger to create profile without role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, is_renter, is_host)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    FALSE,  -- Will be set to TRUE when user uses renter app
    FALSE   -- Will be set to TRUE when user uses host app
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

-- 5. Add comments
COMMENT ON COLUMN public.profiles.is_renter IS 'TRUE if user has activated renter functionality';
COMMENT ON COLUMN public.profiles.is_host IS 'TRUE if user has activated host functionality';
COMMENT ON COLUMN public.profiles.role IS 'Legacy role field - use is_renter and is_host instead';

-- 6. Verify changes
SELECT id, full_name, role, is_renter, is_host, created_at
FROM public.profiles
ORDER BY created_at DESC;

-- ================================================================
-- DONE! Users can now be both renters and hosts
-- ================================================================
