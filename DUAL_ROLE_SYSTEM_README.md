# Dual Role System - Renter & Host Apps

## Overview
This parking platform supports **two separate apps** that share the same database:
- **Renter App** - For users looking to rent parking spaces
- **Host App** - For users offering their parking spaces (this app)

**Important:** The same user can use BOTH apps with the same login credentials!

## How It Works

### Database Structure
The `profiles` table has been updated with dual role tracking:

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  phone TEXT,
  role TEXT,  -- Legacy field (nullable)
  is_renter BOOLEAN DEFAULT FALSE,  -- TRUE when user uses renter app
  is_host BOOLEAN DEFAULT FALSE,    -- TRUE when user uses host app
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  permissions_granted JSONB DEFAULT '{}'
);
```

### User Journey

#### Scenario 1: User starts with Renter App
1. User signs up in **Renter App**
2. Database trigger creates profile with `is_renter=FALSE, is_host=FALSE`
3. When user logs into **Renter App**, it sets `is_renter=TRUE`
4. User can now rent parking spaces

#### Scenario 2: Same user now wants to be a Host
1. User downloads **Host App**
2. Logs in with same credentials
3. **Host App** automatically sets `is_host=TRUE`
4. User completes host onboarding
5. User can now offer parking spaces

#### Scenario 3: User uses both apps
1. User opens **Renter App** → sees renter features
2. User opens **Host App** → sees host features
3. Database shows: `is_renter=TRUE, is_host=TRUE`
4. Both apps work seamlessly!

## Implementation

### 1. Run Database Migration

Open Supabase SQL Editor and run:
```bash
c:\Users\msi\Desktop\project\praking_host\supabase\fix_dual_role_system.sql
```

This will:
- Add `is_renter` and `is_host` columns
- Update existing users
- Fix the trigger function

### 2. Auth Service Methods

New methods added to `auth_service.dart`:

```dart
// Enable host functionality (called by HOST app)
await authService.enableHostRole();

// Enable renter functionality (called by RENTER app)
await authService.enableRenterRole();

// Check user capabilities
bool isHost = await authService.isHost();
bool isRenter = await authService.isRenter();
```

### 3. Automatic Role Assignment

In `main.dart`, when user logs into **HOST app**:

```dart
Future<Widget> _getInitialScreen(bool isAuthenticated) async {
  if (isAuthenticated) {
    // Automatically enable host role for this app
    await _authService.enableHostRole();

    // Continue with onboarding/navigation...
  }
}
```

Similarly, in your **RENTER app**, you would call:
```dart
await _authService.enableRenterRole();
```

## Migration Steps

### Step 1: Update Database
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Run `fix_dual_role_system.sql`
4. Verify: Check `profiles` table for new columns

### Step 2: Deploy Code
1. The code changes are already in place
2. Test login flow
3. Verify `is_host` is set to TRUE when users login

### Step 3: Update Renter App
In your **Renter App**, add similar logic:
```dart
// In main.dart when user is authenticated
await _authService.enableRenterRole();
```

## Database Policies

The existing RLS policies still work:
- Users can read/update their own profile
- The app context (renter/host) determines which features they see
- Same authentication, different app experience

## Benefits

✅ **Single Account** - Users login once, use both apps
✅ **Flexible Roles** - Be a renter, host, or both
✅ **Shared Database** - No data duplication
✅ **Independent Apps** - Each app maintains its own UX
✅ **Easy Transitions** - Users can upgrade to host anytime

## Testing

### Test Scenario 1: New User
1. Sign up in Host App
2. Check database: `is_host=TRUE, is_renter=FALSE`
3. Complete host onboarding
4. ✅ User can create listings

### Test Scenario 2: Existing Renter becomes Host
1. User already has `is_renter=TRUE`
2. Login to Host App
3. Check database: `is_host=TRUE, is_renter=TRUE`
4. ✅ User can both rent AND host

### Test Scenario 3: Switch Between Apps
1. Open Renter App → see rental listings
2. Open Host App → see host dashboard
3. ✅ Both apps work independently

## SQL Query Examples

### Find all hosts
```sql
SELECT * FROM profiles WHERE is_host = TRUE;
```

### Find users who are both renters and hosts
```sql
SELECT * FROM profiles WHERE is_renter = TRUE AND is_host = TRUE;
```

### Find users who only rent
```sql
SELECT * FROM profiles WHERE is_renter = TRUE AND is_host = FALSE;
```

## Troubleshooting

### Issue: Users still showing role='renter'
**Solution:** Run the `fix_dual_role_system.sql` migration

### Issue: is_host not being set
**Solution:** Check that `enableHostRole()` is being called in main.dart

### Issue: Database trigger error
**Solution:** Verify trigger is updated with new function from migration

## Next Steps

1. ✅ Run database migration
2. ✅ Test login flow
3. ✅ Verify role assignment
4. 🔄 Update Renter App with similar changes
5. 🔄 Test cross-app functionality

---

**Created:** 2025-12-15
**Last Updated:** 2025-12-15
