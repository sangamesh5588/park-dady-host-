-- Add onboarding_completed and permissions_granted columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS permissions_granted JSONB DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.onboarding_completed IS 'Tracks whether the user has completed the onboarding process';
COMMENT ON COLUMN public.profiles.permissions_granted IS 'Stores the permission status for various app permissions';
