import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../services/permission_service.dart';
import '../../../services/auth_service.dart';
import '../booking/booking_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _locationText;
  bool _isLoadingLocation = false;
  bool _hasAnyListings = false;
  String? _latestListingStatus;
  bool _isCheckingListings = true;

  // Real data for stats
  String? _businessName;
  int _totalOrders = 0;
  double _todayEarnings = 0.0;
  bool _isLoadingStats = true;

  // Checked-in booking data
  Map<String, dynamic>? _checkedInBooking;
  Timer? _countdownTimer;
  Duration? _remainingTime;
  double _overtimeCharges = 0.0;


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkListingStatus();
    _loadStatsData();
    _loadCheckedInBooking();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatsData() async {
    try {
      final authService = AuthService();

      // Load business name, orders, and earnings in parallel
      final results = await Future.wait([
        authService.getHostBusinessName(),
        authService.getHostTotalOrders(),
        authService.getHostTodayEarnings(),
      ]);

      if (mounted) {
        setState(() {
          _businessName = results[0] as String?;
          _totalOrders = results[1] as int;
          _todayEarnings = results[2] as double;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading stats data: $e');
      if (mounted) {
        setState(() {
          _businessName = null;
          _totalOrders = 0;
          _todayEarnings = 0.0;
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadCheckedInBooking() async {
    try {
      final authService = AuthService();
      final supabase = Supabase.instance.client;

      if (authService.currentUser == null) return;

      // Fetch checked-in booking for this host
      final response = await supabase
          .from('bookings')
          .select('*')
          .eq('host_id', authService.currentUser!.id)
          .eq('booking_status', 'checked_in')
          .maybeSingle();

      if (response != null) {
        // Fetch listing details
        if (response['listing_id'] != null) {
          try {
            final listingResponse = await supabase
                .from('listings')
                .select('parking_space_name, hourly_rate_car, hourly_rate_bike')
                .eq('id', response['listing_id'])
                .maybeSingle();
            response['listings'] = listingResponse;
          } catch (e) {
            print('Error fetching listing: $e');
            response['listings'] = null;
          }
        }

        // Fetch renter/guest profile
        if (response['renter_id'] != null) {
          try {
            final profileResponse = await supabase
                .from('profiles')
                .select('full_name')
                .eq('id', response['renter_id'])
                .maybeSingle();
            response['profiles'] = profileResponse;
          } catch (e) {
            print('Error fetching renter profile: $e');
            response['profiles'] = null;
          }
        }

        if (mounted) {
          setState(() {
            _checkedInBooking = response;
          });
          _startCountdownTimer();
        }
      }
    } catch (e) {
      print('Error loading checked-in booking: $e');
    }
  }

  void _startCountdownTimer() {
    if (_checkedInBooking == null) return;

    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _checkedInBooking == null) {
        timer.cancel();
        return;
      }

      // Countdown based on the requested exit time, not check-in time
      final bookingDate = DateTime.parse(_checkedInBooking!['booking_date']);
      final requestedExitTime = _checkedInBooking!['requested_exit_time'] as String;

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

          // Calculate overtime charges based on vehicle type and hourly rate
          final listing = _checkedInBooking!['listings'];
          final vehicleType = _checkedInBooking!['vehicle_type'] as String?;

          // Get hourly rate based on vehicle type
          double hourlyRate = 0.0;
          if (vehicleType == 'car') {
            hourlyRate = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
          } else if (vehicleType == 'bike') {
            hourlyRate = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
          }

          // Calculate overtime charges based on actual minutes
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

  Future<void> _checkListingStatus() async {
    try {
      final authService = AuthService();
      final hasAny = await authService.hasAnyListings();
      final status = await authService.getLatestListingStatus();

      // Check if we should show approval congratulations
      if (status == 'approved') {
        final hasSeenCongrats = await _hasSeenApprovalCongrats();
        if (!hasSeenCongrats && mounted) {
          // Show congratulatory dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showApprovalCongratsDialog();
          });
        }
      }

      if (mounted) {
        setState(() {
          _hasAnyListings = hasAny;
          _latestListingStatus = status;
          _isCheckingListings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasAnyListings = false;
          _latestListingStatus = null;
          _isCheckingListings = false;
        });
      }
    }
  }

  void _handleCreateListing() {
    if (_hasAnyListings) {
      // User already has listings - redirect based on status
      switch (_latestListingStatus) {
        case 'pending':
          Navigator.of(context).pushNamed('/listing_approval_waiting');
          break;
        case 'approved':
          // Should not reach here due to FAB visibility logic, but handle gracefully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already have an approved listing')),
          );
          break;
        case 'rejected':
          Navigator.of(context).pushNamed('/listing_rejected');
          break;
        default:
          // Unknown status - allow creation
          Navigator.of(context).pushNamed('/create_listing');
      }
    } else {
      // No listings yet - allow creation
      Navigator.of(context).pushNamed('/create_listing');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Use permission service to check and request location permission
      final permissionService = PermissionService();
      final hasPermission = await permissionService.checkAndRequestPermission(
        context,
        Permission.location,
        isCritical: true,
      );

      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _locationText = 'Location permission required';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationString = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown';

        if (mounted) {
          setState(() {
            _locationText = locationString;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<bool> _hasSeenApprovalCongrats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = AuthService().currentUser;
      if (user != null) {
        final key = 'approval_congrats_seen_${user.id}';
        return prefs.getBool(key) ?? false;
      }
      return true; // If no user, don't show congrats
    } catch (e) {
      return true; // On error, don't show congrats
    }
  }

  Future<void> _markCongratsAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = AuthService().currentUser;
      if (user != null) {
        final key = 'approval_congrats_seen_${user.id}';
        await prefs.setBool(key, true);
      }
    } catch (e) {
      // Handle silently
    }
  }

  void _showApprovalCongratsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  '🎉 Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your parking listing has been approved!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Tip section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Update your available slots daily and start earning! Check your parking slots in the Profile section.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _markCongratsAsSeen(); // Mark as seen
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
                      'Get Started',
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
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Status bar background
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFF6366F1),
          ),

          // Enhanced gradient header with blue tap effect
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to profile screen when tapped
                Navigator.of(context).pushNamed('/profile');
              },
              splashColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
              highlightColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ).createShader(bounds),
                          child: const Text(
                            'PH',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Business info with white text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Business name
                          Text(
                            _businessName ?? 'Parking Host',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Location with white icon
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 15,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: _isLoadingLocation
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 11,
                                            height: 11,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Fetching...',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _locationText ?? 'Location not available',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
            ),
          ),

            // Scrollable content below header
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadStatsData(),
                    _loadCheckedInBooking(),
                  ]);
                },
                color: const Color(0xFF6366F1),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 8), // Small gap after header

                    // Quick stats - Orders and Earnings
                    Row(
                      children: [
                        Expanded(
                          child: _isLoadingStats
                            ? _buildShimmerStatCard()
                            : _buildStatCard(
                                context,
                                'Total Orders',
                                _totalOrders.toString(),
                                Icons.receipt_long,
                                const Color(0xFF1976D2), // Blue for Orders
                              ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isLoadingStats
                            ? _buildShimmerStatCard()
                            : _buildStatCard(
                                context,
                                'Total Earnings',
                                '₹${_todayEarnings.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                                const Color(0xFF10B981), // Green for Earnings
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Active Bookings Section Header
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Active Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Booking Card or Empty State
                    if (_checkedInBooking != null)
                      _buildCheckedInBookingCard()
                    else
                      _buildNoActiveBookingsCard(),

                    const SizedBox(height: 24), // Extra padding at bottom
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (!_isCheckingListings && _latestListingStatus != 'approved') ? Container(
        margin: const EdgeInsets.only(bottom: 20), // Positioned at bottom 20
        child: FloatingActionButton(
          onPressed: _handleCreateListing,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 8,
          child: const Icon(
            Icons.add,
            size: 28,
          ),
        ),
      ) : null,
      floatingActionButtonLocation: (!_isCheckingListings && _latestListingStatus != 'approved')
          ? FloatingActionButtonLocation.endFloat
          : null,
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add subtle tap feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title: $value'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              backgroundColor: color.withValues(alpha: 0.9),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced icon with 3D effect
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 6,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Enhanced value display with animation-ready styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.8,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: color.withValues(alpha: 0.1),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                // Enhanced title with subtle styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckedInBookingCard() {
    if (_checkedInBooking == null || _remainingTime == null) return const SizedBox.shrink();

    final listing = _checkedInBooking!['listings'];
    final guest = _checkedInBooking!['profiles'];
    final parkingName = listing?['parking_space_name'] ?? 'Unknown Parking';
    final guestName = guest?['full_name'] ?? 'Unknown Guest';

    // Calculate price from listing's hourly rate based on vehicle type and duration
    final bookingDate = DateTime.parse(_checkedInBooking!['booking_date']);
    final requestedEntry = _checkedInBooking!['requested_entry_time'] as String;
    final requestedExit = _checkedInBooking!['requested_exit_time'] as String;

    final entryParts = requestedEntry.split(':');
    final exitParts = requestedExit.split(':');
    final startTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                                int.parse(entryParts[0]), int.parse(entryParts[1]));
    final endTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day,
                              int.parse(exitParts[0]), int.parse(exitParts[1]));

    final vehicleType = _checkedInBooking!['vehicle_type'] as String?;
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60.0;

    double hourlyRate = 0.0;
    if (vehicleType == 'car') {
      hourlyRate = (listing?['hourly_rate_car'] as num?)?.toDouble() ?? 0.0;
    } else if (vehicleType == 'bike') {
      hourlyRate = (listing?['hourly_rate_bike'] as num?)?.toDouble() ?? 0.0;
    }

    final basePrice = hourlyRate * hours;

    final isOvertime = _overtimeCharges > 0;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(booking: _checkedInBooking!),
          ),
        );
        // Reload if booking was completed
        if (result == true) {
          _loadCheckedInBooking();
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
            // Header with parking name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    parkingName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Checked In',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Guest Info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  guestName,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Countdown Timer
            Row(
              children: [
                Icon(
                  isOvertime ? Icons.warning_amber : Icons.timer_outlined,
                  size: 16,
                  color: isOvertime ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_remainingTime!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOvertime ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOvertime ? 'OVERTIME' : 'Remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isOvertime ? FontWeight.bold : FontWeight.normal,
                    color: isOvertime ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Price badge with overtime calculation
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${basePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isOvertime && _overtimeCharges > 0) ...[
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
                      '+₹${_overtimeCharges.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNoActiveBookingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF9FAFB),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with gradient background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 40,
              color: const Color(0xFF6366F1).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Active bookings will appear here',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerStatCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shimmer circle for icon
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Shimmer for value
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 80,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Shimmer for title
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
