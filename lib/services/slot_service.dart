import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SlotService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Set daily active slots for today
  Future<bool> setDailySlots(String listingId, int carSlots, int bikeSlots) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Validate against total slots
      final listing = await _getListingDetails(listingId);
      if (listing == null) throw Exception('Listing not found');

      final totalCarSlots = listing['total_car_slots'] as int? ?? 0;
      final totalBikeSlots = listing['total_bike_slots'] as int? ?? 0;

      if (carSlots > totalCarSlots) {
        throw Exception('Car slots cannot exceed total capacity ($totalCarSlots)');
      }
      if (bikeSlots > totalBikeSlots) {
        throw Exception('Bike slots cannot exceed total capacity ($totalBikeSlots)');
      }

      // Upsert active slots for today
      await _supabase.from('parking_active_slots').upsert({
        'listing_id': listingId,
        'date': today,
        'active_car_slots': carSlots,
        'active_bike_slots': bikeSlots,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'listing_id,date');

      return true;
    } catch (e) {
      throw Exception('Failed to set daily slots: $e');
    }
  }

  /// Get active slots for a specific date
  Future<Map<String, dynamic>?> getActiveSlots(String listingId, DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final response = await _supabase
          .from('parking_active_slots')
          .select()
          .eq('listing_id', listingId)
          .eq('date', dateStr)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get today's active slots
  Future<Map<String, dynamic>?> getTodayActiveSlots(String listingId) async {
    return getActiveSlots(listingId, DateTime.now());
  }

  /// Emergency reduction of active slots
  Future<bool> reduceSlots(String listingId, int carReduction, int bikeReduction) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get current active slots
      final currentSlots = await getTodayActiveSlots(listingId);
      if (currentSlots == null) {
        throw Exception('No active slots set for today');
      }

      final currentCarSlots = currentSlots['active_car_slots'] as int? ?? 0;
      final currentBikeSlots = currentSlots['active_bike_slots'] as int? ?? 0;

      // Get booked slots for today
      final bookedSlots = await _getTodayBookedSlots(listingId);
      final bookedCarSlots = bookedSlots['car'] ?? 0;
      final bookedBikeSlots = bookedSlots['bike'] ?? 0;

      // Calculate new active slots
      final newCarSlots = currentCarSlots - carReduction;
      final newBikeSlots = currentBikeSlots - bikeReduction;

      // Validation: Cannot go below booked slots
      if (newCarSlots < bookedCarSlots) {
        throw Exception('Cannot reduce car slots below $bookedCarSlots (currently booked)');
      }
      if (newBikeSlots < bookedBikeSlots) {
        throw Exception('Cannot reduce bike slots below $bookedBikeSlots (currently booked)');
      }

      // Validation: Cannot go below zero
      if (newCarSlots < 0 || newBikeSlots < 0) {
        throw Exception('Active slots cannot be negative');
      }

      // Update active slots
      await _supabase.from('parking_active_slots').upsert({
        'listing_id': listingId,
        'date': today,
        'active_car_slots': newCarSlots,
        'active_bike_slots': newBikeSlots,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'listing_id,date');

      return true;
    } catch (e) {
      throw Exception('Failed to reduce slots: $e');
    }
  }

  /// Get remaining available slots (active - booked)
  Future<Map<String, dynamic>> getRemainingSlots(String listingId) async {
    try {
      // Get active slots for today
      final activeSlots = await getTodayActiveSlots(listingId);
      final activeCarSlots = activeSlots?['active_car_slots'] as int? ?? 0;
      final activeBikeSlots = activeSlots?['active_bike_slots'] as int? ?? 0;

      // Get booked slots for today
      final bookedSlots = await _getTodayBookedSlots(listingId);
      final bookedCarSlots = bookedSlots['car'] ?? 0;
      final bookedBikeSlots = bookedSlots['bike'] ?? 0;

      // Calculate remaining
      final remainingCarSlots = activeCarSlots - bookedCarSlots;
      final remainingBikeSlots = activeBikeSlots - bookedBikeSlots;

      return {
        'active_car_slots': activeCarSlots,
        'active_bike_slots': activeBikeSlots,
        'booked_car_slots': bookedCarSlots,
        'booked_bike_slots': bookedBikeSlots,
        'remaining_car_slots': remainingCarSlots.clamp(0, activeCarSlots),
        'remaining_bike_slots': remainingBikeSlots.clamp(0, activeBikeSlots),
      };
    } catch (e) {
      return {
        'active_car_slots': 0,
        'active_bike_slots': 0,
        'booked_car_slots': 0,
        'booked_bike_slots': 0,
        'remaining_car_slots': 0,
        'remaining_bike_slots': 0,
      };
    }
  }

  /// Get slot history for the last N days
  Future<List<Map<String, dynamic>>> getSlotHistory(String listingId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);

      final response = await _supabase
          .from('parking_active_slots')
          .select()
          .eq('listing_id', listingId)
          .gte('date', startDateStr)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get listing details
  Future<Map<String, dynamic>?> _getListingDetails(String listingId) async {
    try {
      final response = await _supabase
          .from('listings')
          .select()
          .eq('id', listingId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get today's booked slots count by vehicle type
  Future<Map<String, int>> _getTodayBookedSlots(String listingId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Count confirmed and checked_in bookings (active bookings that occupy slots)
      final response = await _supabase
          .from('bookings')
          .select('vehicle_type')
          .eq('listing_id', listingId)
          .eq('booking_date', today)
          .eq('payment_status', 'paid')
          .inFilter('booking_status', ['confirmed', 'checked_in']);

      int carCount = 0;
      int bikeCount = 0;

      for (final booking in response) {
        final vehicleType = booking['vehicle_type'] as String?;
        if (vehicleType == 'car') {
          carCount++;
        } else if (vehicleType == 'bike') {
          bikeCount++;
        }
      }

      return {'car': carCount, 'bike': bikeCount};
    } catch (e) {
      return {'car': 0, 'bike': 0};
    }
  }

  /// Check if slots are set for today
  Future<bool> hasTodaySlots(String listingId) async {
    final todaySlots = await getTodayActiveSlots(listingId);
    return todaySlots != null;
  }

  /// Get today's booked slots count by vehicle type
  Future<Map<String, int>> getTodayBookedSlots(String listingId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Count confirmed and checked_in bookings (active bookings that occupy slots)
      final response = await _supabase
          .from('bookings')
          .select('vehicle_type')
          .eq('listing_id', listingId)
          .eq('booking_date', today)
          .eq('payment_status', 'paid')
          .inFilter('booking_status', ['confirmed', 'checked_in']);

      int carCount = 0;
      int bikeCount = 0;

      for (final booking in response) {
        final vehicleType = booking['vehicle_type'] as String?;
        if (vehicleType == 'car') {
          carCount++;
        } else if (vehicleType == 'bike') {
          bikeCount++;
        }
      }

      return {'car': carCount, 'bike': bikeCount};
    } catch (e) {
      // Return zero if there's an error
      return {'car': 0, 'bike': 0};
    }
  }

  /// Emergency reduction of active slots (cannot go below booked slots)
  Future<bool> emergencyReduceSlots(String listingId, int carReduction, int bikeReduction) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // RULE 1: Get current active slots
      final currentActiveSlots = await getTodayActiveSlots(listingId);
      if (currentActiveSlots == null) {
        throw Exception('No active slots set for today. Set slots first before reducing.');
      }

      final currentActiveCarSlots = currentActiveSlots['active_car_slots'] as int? ?? 0;
      final currentActiveBikeSlots = currentActiveSlots['active_bike_slots'] as int? ?? 0;

      // RULE 2: Get today's booked slots
      final bookedSlots = await getTodayBookedSlots(listingId);
      final bookedCarSlots = bookedSlots['car'] ?? 0;
      final bookedBikeSlots = bookedSlots['bike'] ?? 0;

      // RULE 3: Calculate remaining slots (active - booked)
      final remainingCarSlots = currentActiveCarSlots - bookedCarSlots;
      final remainingBikeSlots = currentActiveBikeSlots - bookedBikeSlots;

      // RULE 4: Validate reductions don't exceed remaining slots
      if (carReduction > remainingCarSlots) {
        throw Exception('Cannot reduce car slots by $carReduction. Maximum allowed: $remainingCarSlots (remaining slots).');
      }
      if (bikeReduction > remainingBikeSlots) {
        throw Exception('Cannot reduce bike slots by $bikeReduction. Maximum allowed: $remainingBikeSlots (remaining slots).');
      }

      // RULE 5: Calculate new active slots
      final newActiveCarSlots = currentActiveCarSlots - carReduction;
      final newActiveBikeSlots = currentActiveBikeSlots - bikeReduction;

      // RULE 6: Ensure we don't go below booked slots (double check)
      if (newActiveCarSlots < bookedCarSlots) {
        throw Exception('Cannot reduce car slots below $bookedCarSlots (currently booked).');
      }
      if (newActiveBikeSlots < bookedBikeSlots) {
        throw Exception('Cannot reduce bike slots below $bookedBikeSlots (currently booked).');
      }

      // RULE 7: Validate positive reductions only
      if (carReduction < 0 || bikeReduction < 0) {
        throw Exception('Reduction amounts cannot be negative.');
      }

      // RULE 8: Update active slots in database
      await _supabase.from('parking_active_slots').upsert({
        'listing_id': listingId,
        'date': today,
        'active_car_slots': newActiveCarSlots,
        'active_bike_slots': newActiveBikeSlots,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'listing_id,date');

      return true;
    } catch (e) {
      throw Exception('Emergency reduction failed: $e');
    }
  }

  /// Get available reduction options (respecting booked slots)
  Future<Map<String, List<int>>> getAvailableReductions(String listingId) async {
    try {
      final remainingSlots = await getRemainingSlots(listingId);
      final remainingCarSlots = remainingSlots['remaining_car_slots'] as int? ?? 0;
      final remainingBikeSlots = remainingSlots['remaining_bike_slots'] as int? ?? 0;

      // Available reductions: 1, 5, 10, 20, up to remaining slots
      final carReductions = [1, 5, 10, 20].where((r) => r <= remainingCarSlots).toList();
      final bikeReductions = [1, 5, 10, 20].where((r) => r <= remainingBikeSlots).toList();

      return {
        'car': carReductions,
        'bike': bikeReductions,
      };
    } catch (e) {
      return {'car': [], 'bike': []};
    }
  }

  /// Get comprehensive slot status for emergency management
  Future<Map<String, dynamic>> getEmergencySlotStatus(String listingId) async {
    try {
      // Get active slots
      final activeSlots = await getTodayActiveSlots(listingId);
      final activeCarSlots = activeSlots?['active_car_slots'] as int? ?? 0;
      final activeBikeSlots = activeSlots?['active_bike_slots'] as int? ?? 0;

      // Get booked slots
      final bookedSlots = await getTodayBookedSlots(listingId);
      final bookedCarSlots = bookedSlots['car'] ?? 0;
      final bookedBikeSlots = bookedSlots['bike'] ?? 0;

      // Calculate remaining
      final remainingCarSlots = activeCarSlots - bookedCarSlots;
      final remainingBikeSlots = activeBikeSlots - bookedBikeSlots;

      // Get available reductions
      final availableReductions = await getAvailableReductions(listingId);

      return {
        'active_car_slots': activeCarSlots,
        'active_bike_slots': activeBikeSlots,
        'booked_car_slots': bookedCarSlots,
        'booked_bike_slots': bookedBikeSlots,
        'remaining_car_slots': remainingCarSlots.clamp(0, activeCarSlots),
        'remaining_bike_slots': remainingBikeSlots.clamp(0, activeBikeSlots),
        'available_car_reductions': availableReductions['car'] ?? [],
        'available_bike_reductions': availableReductions['bike'] ?? [],
        'can_reduce_car': remainingCarSlots > 0,
        'can_reduce_bike': remainingBikeSlots > 0,
      };
    } catch (e) {
      return {
        'active_car_slots': 0,
        'active_bike_slots': 0,
        'booked_car_slots': 0,
        'booked_bike_slots': 0,
        'remaining_car_slots': 0,
        'remaining_bike_slots': 0,
        'available_car_reductions': [],
        'available_bike_reductions': [],
        'can_reduce_car': false,
        'can_reduce_bike': false,
      };
    }
  }
}
