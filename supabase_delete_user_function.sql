-- Supabase RPC Function for User Account Deletion
-- This function should be created in your Supabase SQL Editor

-- Function to delete user account and all associated data
CREATE OR REPLACE FUNCTION delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id uuid;
BEGIN
  -- Get the current authenticated user's ID
  user_id := auth.uid();

  -- Check if user is authenticated
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete user data in order (respecting foreign key constraints)
  -- 1. Delete bookings (both as host and guest)
  DELETE FROM bookings WHERE host_id = user_id OR guest_id = user_id;

  -- 2. Delete parking slots
  DELETE FROM slots WHERE host_id = user_id;

  -- 3. Delete listings
  DELETE FROM listings WHERE host_id = user_id;

  -- 4. Delete profile
  DELETE FROM profiles WHERE id = user_id;

  -- 5. Delete the auth user (this requires admin privileges)
  -- Note: This part uses auth.users which requires elevated privileges
  DELETE FROM auth.users WHERE id = user_id;

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user() TO authenticated;

-- Alternative simpler version if you can't delete from auth.users directly
-- This version only deletes the profile and related data, but keeps the auth user
-- The user won't be able to use the app anymore since their profile is deleted
CREATE OR REPLACE FUNCTION delete_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id uuid;
BEGIN
  -- Get the current authenticated user's ID
  user_id := auth.uid();

  -- Check if user is authenticated
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete user data in order (respecting foreign key constraints)
  DELETE FROM bookings WHERE host_id = user_id OR guest_id = user_id;
  DELETE FROM slots WHERE host_id = user_id;
  DELETE FROM listings WHERE host_id = user_id;
  DELETE FROM profiles WHERE id = user_id;

END;
$$;

GRANT EXECUTE ON FUNCTION delete_user_data() TO authenticated;

-- INSTRUCTIONS:
-- 1. Copy and run this SQL in your Supabase SQL Editor
-- 2. The first function (delete_user) attempts to delete the auth user as well
-- 3. If you get permission errors with the first function, use the second one (delete_user_data)
-- 4. After running this, your Flutter app's delete functionality will work
