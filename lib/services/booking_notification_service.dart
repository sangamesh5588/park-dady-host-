import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingNotificationService {
  static final BookingNotificationService _instance = BookingNotificationService._internal();
  factory BookingNotificationService() => _instance;
  BookingNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _bookingsChannel;
  String? _currentHostId;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap - navigate to bookings screen
        print('Notification tapped: ${details.payload}');
      },
    );

    // Request notification permission on Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Start listening for new bookings for the current host
  Future<void> startListeningForBookings(String hostId) async {
    _currentHostId = hostId;

    // Subscribe to realtime changes on bookings table
    _bookingsChannel = _supabase
        .channel('host_bookings_$hostId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'host_id',
            value: hostId,
          ),
          callback: (payload) async {
            // New booking received!
            final booking = payload.newRecord;
            await _handleNewBooking(booking);
          },
        )
        .subscribe();
  }

  Future<void> _handleNewBooking(Map<String, dynamic> booking) async {
    try {
      // Fetch renter details
      final renterId = booking['renter_id'];
      final listingId = booking['listing_id'];

      final renter = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', renterId)
          .maybeSingle();

      final listing = await _supabase
          .from('listings')
          .select('parking_space_name')
          .eq('id', listingId)
          .maybeSingle();

      final guestName = renter?['full_name'] ?? 'A guest';
      final parkingSpace = listing?['parking_space_name'] ?? 'your parking space';

      // Show notification
      await _showNotification(
        title: '🎉 New Booking!',
        body: '$guestName booked $parkingSpace',
        payload: booking['id'].toString(),
      );
    } catch (e) {
      print('Error handling new booking: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      channelDescription: 'Notifications for new bookings and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Stop listening for bookings
  void stopListening() {
    _bookingsChannel?.unsubscribe();
    _bookingsChannel = null;
  }

  /// Show a test notification
  Future<void> showTestNotification() async {
    await _showNotification(
      title: '🎉 New Booking!',
      body: 'Test User booked Main Parking',
      payload: 'test',
    );
  }
}
