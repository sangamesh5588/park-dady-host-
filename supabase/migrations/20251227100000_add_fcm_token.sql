-- Add FCM token column to profiles table for push notifications
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add actual entry and exit time columns to bookings table
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS actual_entry_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS actual_exit_time TIMESTAMPTZ;

-- Create index for faster queries on bookings
CREATE INDEX IF NOT EXISTS idx_bookings_host_id ON public.bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON public.bookings(created_at DESC);
