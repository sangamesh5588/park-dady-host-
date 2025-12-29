import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen> {

  List<Map<String, dynamic>> _todayBookings = [];
  List<Map<String, dynamic>> _upcomingBookings = [];
  bool _isLoading = true;

  // Countdown timers for active bookings
  Map<String, Timer> _countdownTimers = {};
  Map<String, Duration> _remainingTimes = {};

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    // Clean up all timers
    _countdownTimers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      // TODO: Replace with actual API calls
      // For now, using mock data to demonstrate the UI

      setState(() {
        _todayBookings = [
          {
            'id': '1',
            'renter_name': 'John Smith',
            'renter_phone': '+1 234 567 890',
            'vehicle_info': 'Toyota Camry • ABC 123',
            'booking_status': 'checked_in',
            'check_in_time': DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
            'expected_exit_time': DateTime.now().add(const Duration(hours: 2, minutes: 30)),
            'base_amount': 5.00,
            'vehicle_type': 'car',
            'duration_hours': 3,
          },
          {
            'id': '2',
            'renter_name': 'Sarah Johnson',
            'renter_phone': '+1 234 567 891',
            'vehicle_info': 'Honda Civic • XYZ 456',
            'booking_status': 'confirmed',
            'requested_entry_time': '14:00',
            'base_amount': 3.75,
            'vehicle_type': 'car',
            'duration_hours': 1.5,
          },
        ];

        _upcomingBookings = [
          {
            'id': '3',
            'renter_name': 'Mike Wilson',
            'renter_phone': '+1 234 567 892',
            'vehicle_info': 'BMW X3 • BMW 789',
            'booking_status': 'confirmed',
            'requested_entry_time': '16:30',
            'base_amount': 12.50,
            'vehicle_type': 'car',
            'duration_hours': 5,
          },
        ];

        _isLoading = false;
      });

      // Start countdown timers for active bookings
      _startCountdownTimers();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  void _startCountdownTimers() {
    for (var booking in _todayBookings) {
      if (booking['booking_status'] == 'checked_in') {
        final expectedExit = booking['expected_exit_time'] as DateTime;
        final bookingId = booking['id'] as String;

        _countdownTimers[bookingId]?.cancel();

        _countdownTimers[bookingId] = Timer.periodic(const Duration(seconds: 1), (timer) {
          final now = DateTime.now();
          final remaining = expectedExit.difference(now);

          if (remaining.isNegative) {
            // Overstay - handle differently
            _remainingTimes[bookingId] = Duration.zero;
          } else {
            _remainingTimes[bookingId] = remaining;
          }

          // Update UI if widget is still mounted
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Booking Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's Summary
          _buildTodaySummary(),

          const SizedBox(height: 24),

          // Today's Active Bookings
          if (_todayBookings.isNotEmpty) ...[
            _buildSectionHeader('Today\'s Bookings', _todayBookings.length),
            const SizedBox(height: 12),
            ..._todayBookings.map((booking) => _buildBookingCard(booking)),
          ],

          // Upcoming Bookings
          if (_upcomingBookings.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Upcoming Bookings', _upcomingBookings.length),
            const SizedBox(height: 12),
            ..._upcomingBookings.map((booking) => _buildBookingCard(booking)),
          ],

          // Empty State
          if (_todayBookings.isEmpty && _upcomingBookings.isEmpty) ...[
            const SizedBox(height: 48),
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    final activeCount = _todayBookings.where((b) => b['booking_status'] == 'checked_in').length;
    final confirmedCount = _todayBookings.where((b) => b['booking_status'] == 'confirmed').length;
    final totalAmount = _todayBookings.fold<double>(0, (sum, b) => sum + (b['base_amount'] as double));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      '$activeCount active • $confirmedCount confirmed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.green[600],
                    ),
                  ),
                  Text(
                    'Total Revenue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final isActive = booking['booking_status'] == 'checked_in';
    final isUpcoming = booking['booking_status'] == 'confirmed' && booking['check_in_time'] == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.green[100]! : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Renter Info Header
            _buildRenterInfo(booking),

            const SizedBox(height: 16),

            // Booking Details
            _buildBookingDetails(booking),

            const SizedBox(height: 16),

            // Status Specific Content
            if (isActive) _buildActiveBookingContent(booking),
            if (isUpcoming) _buildUpcomingBookingContent(booking),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildRenterInfo(Map<String, dynamic> booking) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: Color(0xFF6366F1),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking['renter_name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking['renter_phone'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                booking['vehicle_info'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(booking['booking_status'] as String),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'checked_in':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        text = 'Checked In';
        break;
      case 'confirmed':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        text = 'Confirmed';
        break;
      case 'completed':
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        text = 'Completed';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBookingDetails(Map<String, dynamic> booking) {
    final amount = booking['base_amount'] as double;
    final duration = booking['duration_hours'] as double;

    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            'Duration',
            '${duration}h',
            Icons.access_time,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            'Amount',
            '\$${amount.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ),
        if (booking['check_in_time'] != null)
          Expanded(
            child: _buildDetailItem(
              'Entry',
              _formatTime(booking['check_in_time'] as DateTime),
              Icons.login,
            ),
          ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBookingContent(Map<String, dynamic> booking) {
    final bookingId = booking['id'] as String;
    final remaining = _remainingTimes[bookingId] ?? Duration.zero;
    final expectedExit = booking['expected_exit_time'] as DateTime;

    final isOverstay = remaining.isNegative;
    final overstayDuration = isOverstay ? remaining.abs() : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverstay ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverstay ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isOverstay ? Icons.warning : Icons.access_time,
                size: 16,
                color: isOverstay ? Colors.red[700] : Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                isOverstay ? 'Overstay Time' : 'Time Remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOverstay ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isOverstay
                ? '${overstayDuration.inHours}h ${overstayDuration.inMinutes % 60}m over'
                : '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isOverstay ? Colors.red[700] : Colors.green[700],
            ),
          ),
          Text(
            'Exit by ${_formatTime(expectedExit)}',
            style: TextStyle(
              fontSize: 12,
              color: isOverstay ? Colors.red[600] : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookingContent(Map<String, dynamic> booking) {
    final entryTime = booking['requested_entry_time'] as String;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: Color.fromARGB(255, 221, 221, 221)),
          const SizedBox(width: 8),
          Text(
            'Expected arrival: $entryTime',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking) {
    final status = booking['booking_status'] as String;

    switch (status) {
      case 'checked_in':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _extendTime(booking),
                icon: const Icon(Icons.access_time, size: 16),
                label: const Text('Extend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[200]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markExit(booking),
                icon: const Icon(Icons.exit_to_app, size: 16),
                label: const Text('Exit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _checkIn(booking),
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Check In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Bookings Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bookings will appear here when renters reserve your parking spaces',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  void _checkIn(Map<String, dynamic> booking) {
    // TODO: Implement QR scanning or manual check-in
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check In Renter'),
        content: const Text('Scan QR code or confirm manual check-in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Update booking status to checked_in
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Renter checked in successfully')),
              );
            },
            child: const Text('Confirm Check-in'),
          ),
        ],
      ),
    );
  }

  void _extendTime(Map<String, dynamic> booking) {
    // TODO: Implement time extension
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time extension feature coming soon')),
    );
  }

  void _markExit(Map<String, dynamic> booking) {
    // TODO: Implement exit process with overstay calculation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Exit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm renter exit?'),
            const SizedBox(height: 8),
            Text(
              'Base amount: \$${booking['base_amount']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Update booking status to completed
              // TODO: Calculate overstay and final amount
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Renter exit marked successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: const Text('Confirm Exit'),
          ),
        ],
      ),
    );
  }
}
