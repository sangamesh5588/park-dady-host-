# Supabase Database Setup

This folder contains the database migration files for the ParkDady Host app.

## Setup Instructions

### 1. Apply the Migration to Your Supabase Project

You have two options to set up your database:

#### Option A: Using Supabase Dashboard (Recommended for Quick Setup)

1. Go to your Supabase project dashboard: https://app.supabase.com/project/eivjgwxyijhfmnyrcbcb
2. Navigate to **SQL Editor** in the left sidebar
3. Open the migration file: `supabase/migrations/20250101000000_initial_schema.sql`
4. Copy the entire SQL content
5. Paste it into the SQL Editor
6. Click **Run** to execute the migration

#### Option B: Using Supabase CLI

1. Install Supabase CLI if you haven't already:
   ```bash
   npm install -g supabase
   ```

2. Link your project:
   ```bash
   supabase link --project-ref eivjgwxyijhfmnyrcbcb
   ```

3. Apply the migration:
   ```bash
   supabase db push
   ```

### 2. Verify the Setup

After running the migration, verify that the following tables were created:

1. Go to **Table Editor** in your Supabase dashboard
2. You should see these tables:
   - `profiles` - Stores user profile information
   - `parking_spots` - Stores parking spot listings
   - `bookings` - Stores booking information

### 3. Test Authentication

The migration includes an automatic trigger that creates a profile entry whenever a new user signs up. To test:

1. Run your Flutter app
2. Sign up with a new email and password
3. Check the `profiles` table in Supabase - you should see a new entry with:
   - User ID (from auth.users)
   - Email
   - Role (set to 'host' by default)
   - Created timestamp

## Database Schema Overview

### `profiles` Table
- Stores user profile information
- Automatically created when a user signs up (via trigger)
- Links to Supabase Auth users
- Contains role information (host/guest)

### `parking_spots` Table
- Stores parking spot listings created by hosts
- Includes location, pricing, and availability information
- Protected by Row Level Security (RLS)

### `bookings` Table
- Stores booking information
- Links guests, hosts, and parking spots
- Tracks booking status and timing
- Protected by Row Level Security (RLS)

## Security Features

All tables have Row Level Security (RLS) enabled with the following policies:

- **Profiles**: Users can only read/update their own profile
- **Parking Spots**: Hosts can manage their own spots; everyone can view available spots
- **Bookings**: Guests can view/manage their bookings; hosts can view bookings for their spots

## Need Help?

If you encounter any issues:
1. Check the Supabase dashboard logs
2. Verify that your `.env` file has the correct Supabase URL and anon key
3. Ensure Row Level Security is properly configured
