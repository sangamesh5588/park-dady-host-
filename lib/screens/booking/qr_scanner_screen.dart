import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRScannerScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> booking;

  const QRScannerScreen({
    super.key,
    required this.bookingId,
    required this.booking,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      await _scannerController.start();
      print('✅ Scanner started successfully');
    } catch (e) {
      print('❌ Scanner initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCodeScanned(String scannedData) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      print('Scanned data: $scannedData');
      print('Expected booking ID: ${widget.bookingId}');

      // Clean up scanned data (remove whitespace, newlines)
      final cleanedData = scannedData.trim();

      // Check if scanned data matches booking ID (exact match or contains it)
      final isValid = cleanedData == widget.bookingId ||
                      cleanedData.contains(widget.bookingId) ||
                      widget.bookingId.contains(cleanedData);

      if (isValid) {
        print('✅ Valid QR code! Checking in...');

        // Get listing hourly rate for storing listing_price
        final listing = widget.booking['listings'];
        final vehicleType = widget.booking['vehicle_type'] as String?;
        double listingPrice = 0.0;

        if (vehicleType == 'car') {
          listingPrice = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
        } else if (vehicleType == 'bike') {
          listingPrice = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
        }

        // Update booking status to checked_in
        await _supabase
            .from('bookings')
            .update({
              'booking_status': 'checked_in',
              'actual_entry_time': DateTime.now().toUtc().toIso8601String(),
              'qr_verified_at': DateTime.now().toUtc().toIso8601String(),
              'listing_price': listingPrice,
            })
            .eq('id', widget.bookingId);

        if (mounted) {
          // Navigate to countdown timer screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BookingTimerScreen(
                booking: widget.booking,
                bookingId: widget.bookingId,
              ),
            ),
          );
        }
      } else {
        // Invalid QR code
        print('❌ Invalid QR code!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid QR code.\nScanned: $cleanedData\nExpected: ${widget.bookingId}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing check-in: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Toggle flashlight
          IconButton(
            icon: Icon(
              Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner
          MobileScanner(
            fit: BoxFit.cover,
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              print('Detected ${barcodes.length} barcodes');

              for (final barcode in barcodes) {
                print('Barcode value: ${barcode.rawValue}');
                print('Barcode type: ${barcode.type}');

                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _handleQRCodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanner frame overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Align QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the renter to show their booking QR code',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing check-in...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BookingTimerScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String bookingId;

  const BookingTimerScreen({
    super.key,
    required this.booking,
    required this.bookingId,
  });

  @override
  State<BookingTimerScreen> createState() => _BookingTimerScreenState();
}

class _BookingTimerScreenState extends State<BookingTimerScreen> {
  late DateTime entryTime;
  late DateTime exitTime;
  Duration? remainingTime;
  Duration? overtimeTime;
  bool isOvertime = false;

  @override
  void initState() {
    super.initState();
    _initializeTimes();
    _startTimer();
  }

  void _initializeTimes() {
    // Parse booking date and times
    final bookingDate = DateTime.parse(widget.booking['booking_date']);
    final requestedEntry = widget.booking['requested_entry_time'] as String;
    final requestedExit = widget.booking['requested_exit_time'] as String;

    // Create full datetime for entry and exit
    final entryParts = requestedEntry.split(':');
    final exitParts = requestedExit.split(':');

    entryTime = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      int.parse(entryParts[0]),
      int.parse(entryParts[1]),
    );

    exitTime = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      int.parse(exitParts[0]),
      int.parse(exitParts[1]),
    );
  }

  void _startTimer() {
    // Update timer every second
    Future.doWhile(() async {
      if (!mounted) return false;

      await Future.delayed(const Duration(seconds: 1));

      final now = DateTime.now();
      final difference = exitTime.difference(now);

      setState(() {
        if (difference.isNegative) {
          isOvertime = true;
          overtimeTime = now.difference(exitTime);
          remainingTime = null;
        } else {
          isOvertime = false;
          remainingTime = difference;
          overtimeTime = null;
        }
      });

      return true;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.booking['listings'];
    final guest = widget.booking['profiles'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Active Booking',
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
            // Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOvertime
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isOvertime
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF6366F1))
                        .withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
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
                    isOvertime ? 'OVERTIME' : 'TIME REMAINING',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDuration(isOvertime ? overtimeTime! : remainingTime ?? Duration.zero),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isOvertime)
                    const Text(
                      'Extra charges will apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Booking Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.local_parking,
                    'Parking Space',
                    listing?['parking_space_name'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Guest',
                    guest?['full_name'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.login,
                    'Entry Time',
                    '${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.logout,
                    'Exit Time',
                    '${exitTime.hour.toString().padLeft(2, '0')}:${exitTime.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeBooking,
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _completeBooking() async {
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('bookings')
          .update({
            'booking_status': 'completed',
            'actual_exit_time': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.bookingId);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking completed successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
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
    }
  }
}
