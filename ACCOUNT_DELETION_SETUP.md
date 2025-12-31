# Account Deletion Feature - Setup Guide

## Overview
This document explains how to set up and use the account deletion functionality in the ParkingHost app.

## Features Implemented

### 1. Delete Account Button (Profile Screen)
- Located in Profile > Account Actions section
- Red "Delete Account" button at the bottom
- Shows detailed confirmation dialog listing what will be deleted
- Performs actual account deletion via Supabase

### 2. Data Deletion Request Screen
- Comprehensive deletion form with detailed information
- Lists all data that will be deleted
- Requires explicit confirmation checkbox
- Alternative email option for manual requests

## Setup Instructions

### Step 1: Create Supabase RPC Function

1. Open your Supabase project dashboard
2. Go to the SQL Editor
3. Run the SQL from `supabase_delete_user_function.sql`

The SQL creates two functions:
- `delete_user()` - Deletes everything including auth user (requires admin privileges)
- `delete_user_data()` - Deletes all user data but keeps auth record (fallback option)

### Step 2: Choose Which Function to Use

In `lib/services/auth_service.dart` at line 601, the code calls:
```dart
await _supabase.rpc('delete_user');
```

**If you get permission errors:**
- Change it to `delete_user_data` instead
- This will delete all user data from tables but keep the auth user record
- The user still won't be able to use the app since their profile is deleted

### Step 3: Set Up Row Level Security (RLS) Policies

Ensure your Supabase tables have proper RLS policies that allow users to delete their own data:

```sql
-- Allow users to delete their own bookings
CREATE POLICY "Users can delete own bookings"
ON bookings FOR DELETE
TO authenticated
USING (auth.uid() = host_id OR auth.uid() = guest_id);

-- Allow users to delete their own slots
CREATE POLICY "Users can delete own slots"
ON slots FOR DELETE
TO authenticated
USING (auth.uid() = host_id);

-- Allow users to delete their own listings
CREATE POLICY "Users can delete own listings"
ON listings FOR DELETE
TO authenticated
USING (auth.uid() = host_id);

-- Allow users to delete their own profile
CREATE POLICY "Users can delete own profile"
ON profiles FOR DELETE
TO authenticated
USING (auth.uid() = id);
```

## How It Works

### User Flow:

1. User navigates to Profile screen
2. Scrolls to bottom and taps "Delete Account" (red button)
3. Sees confirmation dialog with detailed list of what will be deleted:
   - Profile information
   - Parking listings
   - Bookings and transactions
   - All associated records
4. Taps "Delete" to confirm
5. App shows loading indicator
6. Backend deletes data in this order:
   - Bookings (as host and guest)
   - Parking slots
   - Listings
   - Profile
   - Auth user (if using `delete_user` function)
7. User is redirected to onboarding screen
8. Success message is shown

### Alternative Flow (Data Deletion Request Screen):

1. User can access detailed data deletion form
2. Fill optional reason and additional info
3. Check confirmation checkbox
4. Tap "Submit Deletion Request"
5. See final confirmation dialog
6. Same deletion process as above

## Testing

### Test Cases:

1. **Unauthenticated User**
   - Should show error if somehow accessed
   - Function returns exception

2. **User with No Data**
   - Should successfully delete profile only
   - No errors from empty deletions

3. **User with Complete Data**
   - Should delete all bookings, slots, listings, and profile
   - Should redirect to onboarding
   - Should not be able to log back in with same account (if auth user deleted)

4. **User Cancels Deletion**
   - Should not delete anything
   - Should stay on profile screen

## Error Handling

The implementation includes comprehensive error handling:

- Shows loading indicator during deletion
- Catches and displays errors with descriptive messages
- Uses mounted checks to prevent memory leaks
- Navigates to onboarding only on success

## Data Deleted

When account deletion is triggered, the following data is permanently removed:

1. **Bookings Table**
   - All bookings where user is host
   - All bookings where user is guest

2. **Slots Table**
   - All parking slots owned by user

3. **Listings Table**
   - All parking space listings created by user

4. **Profiles Table**
   - User's profile record

5. **Auth Users** (if using `delete_user` function)
   - Authentication record from Supabase Auth

## GDPR Compliance

This implementation helps comply with GDPR "Right to Erasure" requirements:
- Users can request deletion at any time
- All personal data is removed
- Process is irreversible as required
- Clear communication about what gets deleted

## Alternative: Email-Based Deletion

The app also provides an email option (`Send via Email Instead` button) that:
- Opens default email client
- Sends to: privacy@parkinghost.com
- Includes deletion request details
- Useful if automated deletion fails

Make sure to monitor this email address and process manual requests within legal timeframes (typically 30 days).

## Files Modified

1. `lib/services/auth_service.dart` - Added `deleteAccount()` method
2. `lib/screens/profile/profile_screen.dart` - Updated `_deleteAccount()` function
3. `lib/screens/profile/data_deletion_screen.dart` - Updated `_submitDeletionRequest()` function
4. `supabase_delete_user_function.sql` - New SQL file for Supabase function

## Troubleshooting

### Issue: "Permission denied for table auth.users"
**Solution:** Use `delete_user_data` instead of `delete_user` in auth_service.dart

### Issue: "Function delete_user does not exist"
**Solution:** Run the SQL from `supabase_delete_user_function.sql` in Supabase SQL Editor

### Issue: "Foreign key constraint violation"
**Solution:** Check that the deletion order is correct (bookings → slots → listings → profile)

### Issue: User can still log in after deletion
**Solution:** You're using `delete_user_data` which doesn't delete auth user. Switch to `delete_user` or handle this on the backend.

## Security Considerations

1. **Authentication Required** - Only authenticated users can delete their account
2. **User Can Only Delete Own Data** - Function uses `auth.uid()` to ensure users only delete their own records
3. **RLS Policies** - Ensure Row Level Security policies allow deletion
4. **No Undo** - Deletion is permanent and irreversible
5. **Confirmation Required** - Multiple confirmations prevent accidental deletion

## Next Steps

After implementing this feature:
1. Test thoroughly in development
2. Verify RLS policies are correct
3. Set up monitoring for deletion requests
4. Update privacy policy to reflect deletion process
5. Train support team on handling deletion inquiries
