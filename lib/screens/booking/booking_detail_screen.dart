import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _countdownTimer;
  Duration? _remainingTime;
  double _overtimeCharges = 0.0;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking['booking_status'] == 'checked_in') {
      _startCountdownTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Countdown based on the requested exit time, not check-in time
      final bookingDate = DateTime.parse(widget.booking['booking_date']);
      final requestedExitTime = widget.booking['requested_exit_time'] as String;

      // Parse the requested exit time
      final exitParts = requestedExitTime.split(':');
      final exitHour = int.parse(exitParts[0]);
      final exitMinute = int.parse(exitParts[1]);

      // Create the end time from the requested exit time
      final endTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        exitHour,
        exitMinute,
      );

      final now = DateTime.now();
      final difference = endTime.difference(now);

      setState(() {
        if (difference.isNegative) {
          // Show overtime as positive duration
          _remainingTime = difference.abs();

          // Calculate overtime charges
          final listing = widget.booking['listings'];
          final vehicleType = widget.booking['vehicle_type'] as String?;

          double hourlyRate = 0.0;
          if (vehicleType == 'car') {
            hourlyRate = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
          } else if (vehicleType == 'bike') {
            hourlyRate = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
          }

          // Calculate charges based on actual minutes
          final overtimeMinutes = difference.abs().inMinutes;
          _overtimeCharges = (overtimeMinutes / 60) * hourlyRate;
        } else {
          _remainingTime = difference;
          _overtimeCharges = 0.0;
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  Future<void> _completeBooking() async {
    if (_isCompleting) return;

    // Calculate base amount from listing rates
    final listing = widget.booking['listings'];
    final bookingDate = DateTime.parse(widget.booking['booking_date']);
    final requestedEntry = widget.booking['requested_entry_time'] as String;
    final requestedExit = widget.booking['requested_exit_time'] as String;

    final entryParts = requestedEntry.split(':');
    final exitParts = requestedExit.split(':');
    final startTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                                int.parse(entryParts[0]), int.parse(entryParts[1]));
    final endTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                              int.parse(exitParts[0]), int.parse(exitParts[1]));

    final vehicleType = widget.booking['vehicle_type'] as String?;
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60.0;

    double hourlyRate = 0.0;
    if (vehicleType == 'car') {
      hourlyRate = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
    } else if (vehicleType == 'bike') {
      hourlyRate = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
    }

    final baseAmount = hourlyRate * hours;

    // Show confirmation dialog with overtime charge input
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OvertimeChargeDialog(
        calculatedOvertimeCharges: _overtimeCharges,
        baseAmount: baseAmount,
      ),
    );

    if (result == null) return; // User cancelled

    final collectedOvertimeCharge = result['overtime_charge'] as double;
    final finalAmount = baseAmount + collectedOvertimeCharge;

    setState(() => _isCompleting = true);

    try {
      final now = DateTime.now();

      await _supabase.from('bookings').update({
        'booking_status': 'completed',
        'actual_exit_time': now.toIso8601String(),
        'final_amount': finalAmount,
        'overtime_charges': collectedOvertimeCharge,
        'listing_price': hourlyRate, // Store the hourly rate used for calculation
      }).eq('id', widget.booking['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking completed successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate completion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.booking['listings'];
    final guest = widget.booking['profiles'];
    final status = widget.booking['booking_status'] as String;
    final isCheckedIn = status == 'checked_in';
    final isCompleted = status == 'completed';
    final isOvertime = isCheckedIn && _overtimeCharges > 0;

    // Get stored overtime charges for completed bookings
    final storedOvertimeCharges = (widget.booking['overtime_charges'] as num?)?.toDouble() ?? 0.0;

    // Parse booking times
    final bookingDate = DateTime.parse(widget.booking['booking_date']);
    final requestedEntry = widget.booking['requested_entry_time'] as String;
    final requestedExit = widget.booking['requested_exit_time'] as String;

    final entryParts = requestedEntry.split(':');
    final exitParts = requestedExit.split(':');
    final startTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                                int.parse(entryParts[0]), int.parse(entryParts[1]));
    final endTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                              int.parse(exitParts[0]), int.parse(exitParts[1]));

    // Calculate price from listing's hourly rate based on vehicle type and duration
    final vehicleType = widget.booking['vehicle_type'] as String?;
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60.0;

    double hourlyRate = 0.0;
    if (vehicleType == 'car') {
      hourlyRate = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
    } else if (vehicleType == 'bike') {
      hourlyRate = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
    }

    final baseAmount = hourlyRate * hours;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            _buildStatusBadge(status, isOvertime),
            const SizedBox(height: 24),

            // Countdown Timer Card (only for checked-in bookings)
            if (isCheckedIn && _remainingTime != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOvertime
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isOvertime ? const Color(0xFFEF4444) : const Color(0xFF6366F1))
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      isOvertime ? Icons.warning_amber : Icons.timer,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOvertime ? 'OVERTIME!' : 'TIME REMAINING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDuration(_remainingTime!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ),
                    if (isOvertime) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Extra charges applying',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Parking Details Card
            _buildInfoCard(
              title: 'Parking Space',
              children: [
                _buildInfoRow(Icons.local_parking, 'Location', listing?['parking_space_name'] ?? 'Unknown'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.directions_car, 'Vehicle Type', widget.booking['vehicle_type']?.toString().toUpperCase() ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.confirmation_number, 'Booking ID', widget.booking['id']?.toString().substring(0, 8) ?? 'N/A'),
              ],
            ),

            const SizedBox(height: 16),

            // Guest Details Card
            _buildInfoCard(
              title: 'Guest Information',
              children: [
                _buildInfoRow(Icons.person_outline, 'Name', guest?['full_name'] ?? 'Unknown Guest'),
              ],
            ),

            const SizedBox(height: 16),

            // Timing Details Card
            _buildInfoCard(
              title: 'Timing',
              children: [
                _buildInfoRow(Icons.login, 'Entry', _formatDateTime(startTime)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.logout, 'Exit', _formatDateTime(endTime)),
                if (widget.booking['actual_entry_time'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.check_circle_outline,
                    'Checked In',
                    _formatDateTime(DateTime.parse(widget.booking['actual_entry_time'])),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Payment Details Card
            _buildInfoCard(
              title: 'Payment',
              children: [
                _buildInfoRow(Icons.receipt_long, 'Base Amount', '₹${baseAmount.toStringAsFixed(0)}'),
                // Show overtime charges for checked-in (live) or completed bookings
                if (isOvertime && _overtimeCharges > 0) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.add_circle_outline,
                    'Overtime Charges (Live)',
                    '₹${_overtimeCharges.toStringAsFixed(0)}',
                    valueColor: const Color(0xFFEF4444),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.account_balance_wallet,
                    'Total Amount',
                    '₹${(baseAmount + _overtimeCharges).toStringAsFixed(0)}',
                    valueStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ] else if (isCompleted && storedOvertimeCharges > 0) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.add_circle_outline,
                    'Overtime Charges Collected',
                    '₹${storedOvertimeCharges.toStringAsFixed(0)}',
                    valueColor: const Color(0xFFEF4444),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.account_balance_wallet,
                    'Total Amount Collected',
                    '₹${(baseAmount + storedOvertimeCharges).toStringAsFixed(0)}',
                    valueStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ] else ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.account_balance_wallet,
                    isCompleted ? 'Total Amount Collected' : 'Total Amount',
                    '₹${baseAmount.toStringAsFixed(0)}',
                    valueStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Complete Booking Button (only for checked-in bookings)
            if (isCheckedIn)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _completeBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isCompleting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOvertime) {
    Color color;
    String text;

    if (status == 'checked_in' && isOvertime) {
      color = const Color(0xFFEF4444);
      text = 'Overtime';
    } else {
      switch (status) {
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
        default:
          color = const Color(0xFF9E9E9E);
          text = status;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'completed' ? Icons.check_circle : Icons.fiber_manual_record,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: valueStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// Overtime Charge Confirmation Dialog
class _OvertimeChargeDialog extends StatefulWidget {
  final double calculatedOvertimeCharges;
  final double baseAmount;

  const _OvertimeChargeDialog({
    required this.calculatedOvertimeCharges,
    required this.baseAmount,
  });

  @override
  State<_OvertimeChargeDialog> createState() => _OvertimeChargeDialogState();
}

class _OvertimeChargeDialogState extends State<_OvertimeChargeDialog> {
  late TextEditingController _overtimeController;
  double _collectedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with calculated overtime charge
    _collectedAmount = widget.calculatedOvertimeCharges;
    _overtimeController = TextEditingController(
      text: _collectedAmount > 0 ? _collectedAmount.toStringAsFixed(0) : '0',
    );
  }

  @override
  void dispose() {
    _overtimeController.dispose();
    super.dispose();
  }

  void _updateCollectedAmount(String value) {
    setState(() {
      _collectedAmount = double.tryParse(value) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasOvertime = widget.calculatedOvertimeCharges > 0;
    final totalAmount = widget.baseAmount + _collectedAmount;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasOvertime
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasOvertime ? Icons.warning_amber : Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasOvertime ? 'Overtime Charges' : 'Complete Booking',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasOvertime ? Colors.red[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasOvertime ? Colors.red[200]! : Colors.blue[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: hasOvertime ? Colors.red[700] : Colors.blue[700],
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasOvertime
                                ? 'Guest exceeded booking time. Enter the overtime charge collected from the renter.'
                                : 'No overtime charges. Enter amount if you collected any additional charges.',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasOvertime ? Colors.red[900] : Colors.blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Calculated overtime (if any)
                  if (hasOvertime) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calculated Overtime:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${widget.calculatedOvertimeCharges.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Overtime charge input
                  const Text(
                    'Collected Overtime Charge',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _overtimeController,
                    keyboardType: TextInputType.number,
                    onChanged: _updateCollectedAmount,
                    decoration: InputDecoration(
                      hintText: 'Enter amount collected',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      suffixText: hasOvertime ? '(Suggested)' : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Base Amount:',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            Text(
                              '₹${widget.baseAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overtime Charge:',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            Text(
                              '₹${_collectedAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF6B7280)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'overtime_charge': _collectedAmount,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
