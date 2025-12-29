import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'qr_scanner_screen.dart';
import 'booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHostBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHostBookings() async {
    if (_authService.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch all paid bookings (confirmed, checked_in, completed)
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('*')
          .eq('host_id', _authService.currentUser!.id)
          .eq('payment_status', 'paid')
          .inFilter('booking_status', ['confirmed', 'checked_in', 'completed'])
          .order('created_at', ascending: false);

      final bookings = List<Map<String, dynamic>>.from(bookingsResponse);

      // Fetch related data for each booking
      for (var booking in bookings) {
        // Fetch listing details
        if (booking['listing_id'] != null) {
          try {
            final listingResponse = await _supabase
                .from('listings')
                .select('parking_space_name, parking_address, hourly_rate_car, hourly_rate_bike, parking_type')
                .eq('id', booking['listing_id'])
                .maybeSingle();

            booking['listings'] = listingResponse;
          } catch (e) {
            print('Error fetching listing: $e');
            booking['listings'] = null;
          }
        }

        // Fetch renter/guest profile
        if (booking['renter_id'] != null) {
          try {
            final profileResponse = await _supabase
                .from('profiles')
                .select('full_name, phone')
                .eq('id', booking['renter_id'])
                .maybeSingle();

            booking['profiles'] = profileResponse;
          } catch (e) {
            print('Error fetching renter profile: $e');
            booking['profiles'] = null;
          }
        }
      }

      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterBookings(String status) {
    if (status == 'all') return _allBookings;
    return _allBookings.where((b) => b['booking_status'] == status).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Column(
              children: [
                // Statistics Card
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x196366F1),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', '${_allBookings.length}', Icons.calendar_today),
                      _buildStatItem('Active', '${_filterBookings('confirmed').length}', Icons.check_circle),
                      _buildStatItem('Checked In', '${_filterBookings('checked_in').length}', Icons.done_all),
                      _buildStatItem('Completed', '${_filterBookings('completed').length}', Icons.task_alt),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Confirmed'),
                      Tab(text: 'Checked In'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bookings List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(_allBookings),
                      _buildBookingsList(_filterBookings('confirmed')),
                      _buildBookingsList(_filterBookings('checked_in')),
                      _buildBookingsList(_filterBookings('completed')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 48,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bookings from guests will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHostBookings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final listing = booking['listings'];
    final guest = booking['profiles'];
    final status = booking['booking_status'] as String;

    // Parse booking date and times
    final bookingDate = DateTime.parse(booking['booking_date']);
    final requestedEntry = booking['requested_entry_time'] as String;
    final requestedExit = booking['requested_exit_time'] as String;

    // Create full datetime for display
    final entryParts = requestedEntry.split(':');
    final exitParts = requestedExit.split(':');
    final startTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                                int.parse(entryParts[0]), int.parse(entryParts[1]));
    final endTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                              int.parse(exitParts[0]), int.parse(exitParts[1]));

    // Calculate price from listing's hourly rate based on vehicle type and duration
    final vehicleType = booking['vehicle_type'] as String?;
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60.0;

    double hourlyRate = 0.0;
    if (vehicleType == 'car') {
      hourlyRate = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
    } else if (vehicleType == 'bike') {
      hourlyRate = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
    }

    final calculatedPrice = hourlyRate * hours;

    // Calculate overtime for checked-in bookings (live calculation)
    double overtimeCharges = 0.0;
    if (status == 'checked_in') {
      final now = DateTime.now();
      final difference = endTime.difference(now);
      if (difference.isNegative) {
        final overtimeMinutes = difference.abs().inMinutes;
        overtimeCharges = (overtimeMinutes / 60) * hourlyRate;
      }
    }

    // Get stored overtime charges for completed bookings
    final storedOvertimeCharges = (booking['overtime_charges'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () async {
        if (status == 'confirmed') {
          // Open QR scanner for confirmed bookings
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QRScannerScreen(
                bookingId: booking['id'],
                booking: booking,
              ),
            ),
          );
        } else if (status == 'checked_in' || status == 'completed') {
          // Open detail screen for checked-in or completed bookings
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookingDetailScreen(booking: booking),
            ),
          );
          // Reload bookings if booking was completed
          if (result == true) {
            _loadHostBookings();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing?['parking_space_name'] ?? 'Unknown Parking',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 12),

            // Guest Info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  guest?['full_name'] ?? 'Unknown Guest',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time
            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  '${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Price - show based on booking status
            Row(
              children: [
                // For completed bookings, show total collected amount in green
                if (status == 'completed') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '₹${(calculatedPrice + storedOvertimeCharges).toStringAsFixed(0)} Collected',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // For confirmed/checked-in bookings, show base price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${calculatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Show overtime badge for checked-in bookings with overtime
                  if (status == 'checked_in' && overtimeCharges > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+₹${overtimeCharges.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = const Color(0xFF2196F3);
        text = 'Pending';
        break;
      case 'confirmed':
        color = const Color(0xFF4CAF50);
        text = 'Confirmed';
        break;
      case 'checked_in':
        color = const Color(0xFF9C27B0);
        text = 'Checked In';
        break;
      case 'completed':
        color = const Color(0xFF10B981);
        text = 'Completed';
        break;
      case 'cancelled':
        color = const Color(0xFFFF4444);
        text = 'Cancelled';
        break;
      case 'expired':
        color = const Color(0xFF9E9E9E);
        text = 'Expired';
        break;
      default:
        color = const Color(0xFF9E9E9E);
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, HH:mm').format(dateTime);
  }
}
