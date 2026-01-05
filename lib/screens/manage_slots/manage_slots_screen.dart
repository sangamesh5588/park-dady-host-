import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/slot_service.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final SlotService _slotService = SlotService();

  List<Map<String, dynamic>> _approvedListings = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadApprovedListings();
  }

  Future<void> _loadApprovedListings() async {
    try {
      // Get current user info
      final currentUser = _authService.currentUser;
      debugPrint('=== MANAGE SLOTS DEBUG ===');
      debugPrint('Current User ID: ${currentUser?.id}');
      debugPrint('Current User Email: ${currentUser?.email}');

      if (currentUser == null) {
        debugPrint('❌ ISSUE: No user logged in!');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to view your listings'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        debugPrint('=== END DEBUG ===');
        return;
      }

      final listings = await _authService.getUserListings();
      debugPrint('Total listings found: ${listings.length}');

      if (listings.isEmpty) {
        debugPrint('❌ ISSUE: User has no listings!');
        debugPrint('💡 SOLUTION: Create parking listings first');
      }

      // Log all listings
      for (var listing in listings) {
        debugPrint('Listing: ${listing['parking_space_name']} - Status: ${listing['status']} - Host ID: ${listing['host_id']}');
      }

      // Filter only approved listings
      final approvedListings = listings.where((listing) => listing['status'] == 'approved').toList();
      debugPrint('Approved listings found: ${approvedListings.length}');

      if (listings.isNotEmpty && approvedListings.isEmpty) {
        debugPrint('❌ ISSUE: User has listings but none are approved!');
        debugPrint('💡 SOLUTION: Wait for admin approval or check listing status');
        debugPrint('📊 Listing statuses found: ${listings.map((l) => l['status']).toSet()}');
      }

      // Load current slot status for each listing
      for (var listing in approvedListings) {
        final listingId = listing['id'] as String;
        final hasTodaySlots = await _slotService.hasTodaySlots(listingId);
        final remainingSlots = await _slotService.getRemainingSlots(listingId);

        listing['has_today_slots'] = hasTodaySlots;
        listing['remaining_slots'] = remainingSlots;
        debugPrint('Listing $listingId - Has today slots: $hasTodaySlots');
      }

      if (mounted) {
        setState(() {
          _approvedListings = approvedListings;
          _isLoading = false;
        });
      }

      debugPrint('=== END DEBUG ===');

      // Show helpful message based on findings
      if (mounted && _approvedListings.isEmpty) {
        String message = '';
        if (listings.isEmpty) {
          message = 'Create your first parking listing to get started!';
        } else if (approvedListings.isEmpty) {
          message = 'Your listings are pending approval. Check back later!';
        }

        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF1A1A1A),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR loading listings: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadApprovedListings,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    debugPrint('🔧 BUILD METHOD CALLED - isLoading: $_isLoading, approvedListings: ${_approvedListings.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildModernAppBar(),
      body: _isLoading
          ? _buildModernLoadingState()
          : _approvedListings.isEmpty
              ? _buildModernEmptyState()
              : _buildModernContent(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F2937),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false, // Remove back button
      title: const Text(
        'Manage Slots',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your listings...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clean illustration
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
                Icons.local_parking_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'No Approved Listings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'You need approved parking listings to manage daily slots',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Steps card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Next Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStepItem('1', 'Create a parking listing'),
                  const SizedBox(height: 16),
                  _buildStepItem('2', 'Wait for admin approval'),
                  const SizedBox(height: 16),
                  _buildStepItem('3', 'Set daily available slots'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/create_listing'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Create New Listing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage your daily parking slot availability here after approval',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernContent() {
    return Column(
      children: [
        // Header summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      Text(
                        '${_approvedListings.length} approved listing${_approvedListings.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Listings list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadApprovedListings,
            color: const Color(0xFF1A1A1A),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _approvedListings.length,
              itemBuilder: (context, index) {
                final listing = _approvedListings[index];
                return _buildModernListingCard(listing);
              },
            ),
          ),
        ),

        // Bottom info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border(
              top: BorderSide(color: Colors.green[200]!, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pull down to refresh • Set daily slots for each listing',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernListingCard(Map<String, dynamic> listing) {
    final parkingName = listing['parking_space_name'] as String? ?? 'Unnamed Parking';
    final totalCarSlots = listing['total_car_slots'] as int? ?? 0;
    final totalBikeSlots = listing['total_bike_slots'] as int? ?? 0;
    final hasTodaySlots = listing['has_today_slots'] as bool? ?? false;
    final remainingSlots = listing['remaining_slots'] as Map<String, dynamic>? ?? {};

    final remainingCarSlots = remainingSlots['remaining_car_slots'] as int? ?? 0;
    final remainingBikeSlots = remainingSlots['remaining_bike_slots'] as int? ?? 0;
    final bookedCarSlots = remainingSlots['booked_car_slots'] as int? ?? 0;
    final bookedBikeSlots = remainingSlots['booked_bike_slots'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToSlotManagement(listing),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_parking,
                        color: Color(0xFF1A1A1A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parkingName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalCarSlots cars • $totalBikeSlots bikes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasTodaySlots ? const Color(0xFFF5F5F5) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasTodaySlots ? Icons.check_circle : Icons.schedule,
                        size: 16,
                        color: const Color(0xFF1A1A1A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasTodaySlots ? 'Slots Set Today' : 'Slots Not Set',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasTodaySlots) ...[
                  const SizedBox(height: 20),

                  // Current status overview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Today\'s Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusMetric(
                                'Active',
                                '$totalCarSlots cars\n$totalBikeSlots bikes',
                                const Color(0xFF1A1A1A),
                              ),
                            ),
                            Expanded(
                              child: _buildStatusMetric(
                                'Booked',
                                '$bookedCarSlots cars\n$bookedBikeSlots bikes',
                                const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                              ),
                            ),
                            Expanded(
                              child: _buildStatusMetric(
                                'Available',
                                '$remainingCarSlots cars\n$remainingBikeSlots bikes',
                                const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Emergency Reduction Section - Single Clean Card
                  if (remainingCarSlots > 0 || remainingBikeSlots > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[200]!, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red[700],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency Slot Reduction',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Reduce availability due to overflow or congestion',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red[700],
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Reduction Options Title
                          Text(
                            'Quick Reduction Options',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Car reduction buttons
                          if (remainingCarSlots > 0) ...[
                            Row(
                              children: [
                                Text(
                                  'Reduce Cars:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const Spacer(),
                                ..._buildReductionButtons(listing['id'], 'car', remainingCarSlots),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Bike reduction buttons
                          if (remainingBikeSlots > 0) ...[
                            Row(
                              children: [
                                Text(
                                  'Reduce Bikes:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const Spacer(),
                                ..._buildReductionButtons(listing['id'], 'bike', remainingBikeSlots),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Protection Notice
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined, color: Colors.red[600], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cannot reduce below already booked slots',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // All slots booked - no reduction possible
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All active slots are already booked. You cannot reduce further.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToSlotManagement(listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      hasTodaySlots ? 'Manage Today\'s Slots' : 'Set Today\'s Slots',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildStatusMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReductionButtons(String listingId, String vehicleType, int maxReduction) {
    final availableOptions = [1, 5, 10].where((amount) => amount <= maxReduction).toList();

    if (availableOptions.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'No reduction available',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ];
    }

    return availableOptions.map((amount) {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        child: ElevatedButton(
          onPressed: () => _performEmergencyReduction(listingId, vehicleType, amount),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          child: Text(
            '-$amount',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _performEmergencyReduction(String listingId, String vehicleType, int reductionAmount) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Emergency Reduction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 64, // Account for padding
            ),
            child: Text(
              'Are you sure you want to reduce $vehicleType slots by $reductionAmount? This will immediately affect availability.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Reduce Slots'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );

      if (confirmed != true) return;

      // Perform the reduction
      final carReduction = vehicleType == 'car' ? reductionAmount : 0;
      final bikeReduction = vehicleType == 'bike' ? reductionAmount : 0;

      await _slotService.emergencyReduceSlots(listingId, carReduction, bikeReduction);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$vehicleType slots reduced by $reductionAmount'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the data
        await _loadApprovedListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reduction failed: $e'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _navigateToSlotManagement(Map<String, dynamic> listing) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SlotManagementScreen(listing: listing),
      ),
    );

    if (result == true && mounted) {
      await _loadApprovedListings();
    }
  }
}

// Individual slot management screen
class SlotManagementScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const SlotManagementScreen({super.key, required this.listing});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> with AutomaticKeepAliveClientMixin {
  final SlotService _slotService = SlotService();

  late TextEditingController _carSlotsController;
  late TextEditingController _bikeSlotsController;

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _currentSlots;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _carSlotsController = TextEditingController();
    _bikeSlotsController = TextEditingController();
    _loadCurrentSlots();
  }

  @override
  void dispose() {
    _carSlotsController.dispose();
    _bikeSlotsController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSlots() async {
    setState(() => _isLoading = true);

    try {
      final listingId = widget.listing['id'] as String;
      final slots = await _slotService.getRemainingSlots(listingId);
      final todaySlots = await _slotService.getTodayActiveSlots(listingId);

      if (mounted) {
        setState(() {
          _currentSlots = slots;
          _isLoading = false;

          if (todaySlots != null) {
            _carSlotsController.text = (todaySlots['active_car_slots'] ?? 0).toString();
            _bikeSlotsController.text = (todaySlots['active_bike_slots'] ?? 0).toString();
          } else {
            _carSlotsController.text = (widget.listing['total_car_slots'] ?? 0).toString();
            _bikeSlotsController.text = (widget.listing['total_bike_slots'] ?? 0).toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading slots: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveDailySlots() async {
    final carSlots = int.tryParse(_carSlotsController.text) ?? 0;
    final bikeSlots = int.tryParse(_bikeSlotsController.text) ?? 0;

    final totalCarSlots = widget.listing['total_car_slots'] as int? ?? 0;
    final totalBikeSlots = widget.listing['total_bike_slots'] as int? ?? 0;

    if (carSlots > totalCarSlots || bikeSlots > totalBikeSlots || carSlots < 0 || bikeSlots < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid slot values'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final listingId = widget.listing['id'] as String;
      await _slotService.setDailySlots(listingId, carSlots, bikeSlots);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slots updated successfully!'), backgroundColor: Colors.green),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final parkingName = widget.listing['parking_space_name'] as String? ?? 'Manage Slots';
    final totalCarSlots = widget.listing['total_car_slots'] as int? ?? 0;
    final totalBikeSlots = widget.listing['total_bike_slots'] as int? ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: Text(parkingName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(false);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Today\'s Available Slots',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define how many parking slots are available for booking today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_currentSlots != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Current Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatusItem(
                                  'Available Cars',
                                  _currentSlots!['remaining_car_slots'] ?? 0,
                                  _currentSlots!['active_car_slots'] ?? 0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatusItem(
                                  'Available Bikes',
                                  _currentSlots!['remaining_bike_slots'] ?? 0,
                                  _currentSlots!['active_bike_slots'] ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Text(
                    'Car Parking Slots',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _carSlotsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter number of car slots',
                      prefixIcon: const Icon(Icons.directions_car),
                      suffixText: '/ $totalCarSlots',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Bike Parking Slots',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bikeSlotsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter number of bike slots',
                      prefixIcon: const Icon(Icons.two_wheeler),
                      suffixText: '/ $totalBikeSlots',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDailySlots,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Daily Slots',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can set different slot counts each day based on your availability',
                            style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusItem(String label, int available, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '$available / $total',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
        ),
      ],
    );
  }
}
