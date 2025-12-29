import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      // If record found, email is already registered
      return response != null;
    } catch (e) {
      // If error occurs, assume email is available
      return false;
    }
  }

  // Sign up with email and password (HOST role for this app)
  // Note: This is the HOST app - all users who sign up here are hosts
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      // Sign up with Supabase Auth
      // The database trigger will automatically create a profile with role='host'
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.praking_host://login-callback',
    );
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.example.praking_host://login-callback',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get authentication method/provider
  String getAuthProvider() {
    if (currentUser == null) return 'unknown';

    // Check app_metadata for provider info
    final appMetadata = currentUser!.appMetadata;
    if (appMetadata != null && appMetadata['provider'] != null) {
      return appMetadata['provider'] as String;
    }

    // Check user_metadata for provider info
    final userMetadata = currentUser!.userMetadata;
    if (userMetadata != null && userMetadata['provider'] != null) {
      return userMetadata['provider'] as String;
    }

    // Check identities for provider info
    if (currentUser!.identities != null && currentUser!.identities!.isNotEmpty) {
      final provider = currentUser!.identities!.first.provider;
      if (provider == 'email') {
        return 'email';
      } else if (provider == 'google') {
        return 'google';
      } else if (provider == 'apple') {
        return 'apple';
      }
    }

    // Default fallback
    return 'email';
  }

  // Get comprehensive user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      final authProvider = getAuthProvider();
      final userMetadata = currentUser!.userMetadata ?? {};
      final createdAt = currentUser!.createdAt;

      // If no profile exists in profiles table, return auth-based info
      if (response == null) {
        return {
          'id': currentUser!.id,
          'email': currentUser!.email,
          'is_renter': false,
          'is_host': false,
          'auth_provider': authProvider,
          'full_name': userMetadata['full_name'] ?? userMetadata['name'] ?? '',
          'phone_number': userMetadata['phone_number'] ?? '',
          'created_at': createdAt,
          'last_sign_in': currentUser!.lastSignInAt,
        };
      }

      // Merge profiles data with auth data
      return {
        ...response,
        'auth_provider': authProvider,
        'full_name': response['full_name'] ?? userMetadata['full_name'] ?? userMetadata['name'] ?? '',
        'phone_number': response['phone_number'] ?? userMetadata['phone_number'] ?? '',
        'last_sign_in': currentUser!.lastSignInAt,
      };
    } catch (e) {
      // Return basic auth-based info on error
      return {
        'id': currentUser!.id,
        'email': currentUser!.email,
        'is_renter': false,
        'is_host': false,
        'auth_provider': getAuthProvider(),
        'full_name': currentUser!.userMetadata?['full_name'] ?? currentUser!.userMetadata?['name'] ?? '',
        'phone_number': currentUser!.userMetadata?['phone_number'] ?? '',
        'created_at': currentUser!.createdAt,
        'last_sign_in': currentUser!.lastSignInAt,
      };
    }
  }

  // Enable host functionality for current user
  // Call this when user first accesses HOST app features
  Future<void> enableHostRole() async {
    if (currentUser == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'is_host': true})
          .eq('id', currentUser!.id);
    } catch (e) {
      print('Error enabling host role: $e');
      rethrow;
    }
  }

  // Enable renter functionality for current user
  // Call this when user first accesses RENTER app features
  Future<void> enableRenterRole() async {
    if (currentUser == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'is_renter': true})
          .eq('id', currentUser!.id);
    } catch (e) {
      print('Error enabling renter role: $e');
      rethrow;
    }
  }

  // Check if user has host capabilities
  Future<bool> isHost() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_host')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['is_host'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if user has renter capabilities
  Future<bool> isRenter() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_renter')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['is_renter'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Update user profile with additional information (stored in auth metadata)
  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    if (currentUser == null) return;

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      if (updates.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(data: updates),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['onboarding_completed'] ?? false;
    } catch (e) {
      // If error, assume onboarding not completed for safety
      return false;
    }
  }

  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    if (currentUser == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'onboarding_completed': true})
          .eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  // Update permissions status
  Future<void> updatePermissionsStatus(Map<String, bool> permissions) async {
    if (currentUser == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'permissions_granted': permissions})
          .eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  // Get permissions status
  Future<Map<String, dynamic>?> getPermissionsStatus() async {
    if (currentUser == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('permissions_granted')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['permissions_granted'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }

  // Get user's parking listings with status
  Future<List<Map<String, dynamic>>> getUserListings() async {
    if (currentUser == null) return [];

    try {
      final response = await _supabase
          .from('listings')
          .select()
          .eq('host_id', currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Check if user has any approved listings
  Future<bool> hasApprovedListings() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('listings')
          .select('id')
          .eq('host_id', currentUser!.id)
          .eq('status', 'approved')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if user has any listings (regardless of status)
  Future<bool> hasAnyListings() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('listings')
          .select('id')
          .eq('host_id', currentUser!.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get the status of user's latest listing
  Future<String?> getLatestListingStatus() async {
    if (currentUser == null) return null;

    try {
      final response = await _supabase
          .from('listings')
          .select('status, rejection_reason')
          .eq('host_id', currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Get user's latest listing with full details
  Future<Map<String, dynamic>?> getLatestListing() async {
    if (currentUser == null) return null;

    try {
      final response = await _supabase
          .from('listings')
          .select()
          .eq('host_id', currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get user's bookings as a guest (renter)
  Future<List<Map<String, dynamic>>> getUserBookingsAsGuest() async {
    if (currentUser == null) return [];

    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            listings!inner(
              parking_space_name,
              parking_address,
              hourly_rate_car,
              hourly_rate_bike,
              parking_type
            ),
            profiles!bookings_host_id_fkey(
              full_name
            )
          ''')
          .eq('guest_id', currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  // Get host's total orders/bookings count (all confirmed + paid bookings)
  Future<int> getHostTotalOrders() async {
    if (currentUser == null) return 0;

    try {
      // Count all paid bookings (confirmed, checked_in, completed)
      final response = await _supabase
          .from('bookings')
          .select('id')
          .eq('host_id', currentUser!.id)
          .eq('payment_status', 'paid')
          .inFilter('booking_status', ['confirmed', 'checked_in', 'completed']);

      return response.length;
    } catch (e) {
      print('Error fetching host total orders: $e');
      return 0;
    }
  }

  // Get host's total earnings from all paid bookings
  Future<double> getHostTodayEarnings() async {
    if (currentUser == null) return 0.0;

    try {
      // Fetch all paid bookings with listing details
      final response = await _supabase
          .from('bookings')
          .select('id, booking_status, listing_id, vehicle_type, booking_date, requested_entry_time, requested_exit_time, final_amount, overtime_charges')
          .eq('host_id', currentUser!.id)
          .eq('payment_status', 'paid')
          .inFilter('booking_status', ['confirmed', 'checked_in', 'completed']);

      double totalEarnings = 0.0;

      for (final booking in response) {
        final status = booking['booking_status'];

        // For completed bookings with final_amount, use that (includes overtime)
        if (status == 'completed' && booking['final_amount'] != null) {
          final amount = booking['final_amount'];
          totalEarnings += (amount is int) ? amount.toDouble() : amount;
          continue;
        }

        // For confirmed/checked_in bookings, calculate from listing rates
        try {
          // Fetch listing details
          final listingResponse = await _supabase
              .from('listings')
              .select('hourly_rate_car, hourly_rate_bike')
              .eq('id', booking['listing_id'])
              .maybeSingle();

          if (listingResponse != null) {
            // Parse times
            final bookingDate = DateTime.parse(booking['booking_date']);
            final entryParts = (booking['requested_entry_time'] as String).split(':');
            final exitParts = (booking['requested_exit_time'] as String).split(':');

            final startTime = DateTime(
              bookingDate.year, bookingDate.month, bookingDate.day,
              int.parse(entryParts[0]), int.parse(entryParts[1])
            );
            final endTime = DateTime(
              bookingDate.year, bookingDate.month, bookingDate.day,
              int.parse(exitParts[0]), int.parse(exitParts[1])
            );

            // Calculate duration and price
            final duration = endTime.difference(startTime);
            final hours = duration.inMinutes / 60.0;

            final vehicleType = booking['vehicle_type'] as String?;
            double hourlyRate = 0.0;
            if (vehicleType == 'car') {
              hourlyRate = (listingResponse['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
            } else if (vehicleType == 'bike') {
              hourlyRate = (listingResponse['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
            }

            final baseAmount = hourlyRate * hours;

            // Add overtime if checked_in
            double overtimeAmount = 0.0;
            if (status == 'checked_in') {
              final now = DateTime.now();
              final difference = endTime.difference(now);
              if (difference.isNegative) {
                final overtimeMinutes = difference.abs().inMinutes;
                overtimeAmount = (overtimeMinutes / 60) * hourlyRate;
              }
            }

            totalEarnings += baseAmount + overtimeAmount;
          }
        } catch (e) {
          print('Error calculating earnings for booking ${booking['id']}: $e');
        }
      }

      return totalEarnings;
    } catch (e) {
      print('Error fetching host today earnings: $e');
      return 0.0;
    }
  }

  // Get host's business name (first approved listing name)
  Future<String?> getHostBusinessName() async {
    if (currentUser == null) return null;

    try {
      final response = await _supabase
          .from('listings')
          .select('parking_space_name')
          .eq('host_id', currentUser!.id)
          .eq('status', 'approved')
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      return response?['parking_space_name'] as String?;
    } catch (e) {
      print('Error fetching host business name: $e');
      return null;
    }
  }
}
