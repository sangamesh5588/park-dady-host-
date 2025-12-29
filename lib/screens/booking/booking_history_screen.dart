import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure TabController is properly initialized
    if (_tabController.length != 4) {
      _tabController.dispose();
      _tabController = TabController(length: 4, vsync: this);
      _tabController.addListener(_handleTabChange);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedFilter = _getFilterForTab(_tabController.index);
        _filterBookings();
      });
    }
  }

  String _getFilterForTab(int index) {
    switch (index) {
      case 0: return 'All';
      case 1: return 'Active';
      case 2: return 'Upcoming';
      case 3: return 'Past';
      default: return 'All';
    }
  }

  void _filterBookings() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredBookings = _bookings.where((booking) {
          switch (_selectedFilter) {
            case 'Active':
              return booking['status'] == 'active';
            case 'Upcoming':
              return booking['status'] == 'upcoming';
            case 'Past':
              return booking['status'] == 'completed' || booking['status'] == 'cancelled';
            default:
              return true;
          }
        }).toList();
      } else {
        _filteredBookings = _bookings.where((booking) {
          final matchesSearch = booking['parking_title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               booking['address'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               booking['host_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesFilter = _selectedFilter == 'All' ||
                               (_selectedFilter == 'Active' && booking['status'] == 'active') ||
                               (_selectedFilter == 'Upcoming' && booking['status'] == 'upcoming') ||
                               (_selectedFilter == 'Past' && (booking['status'] == 'completed' || booking['status'] == 'cancelled'));

          return matchesSearch && matchesFilter;
        }).toList();
      }
    });
  }

  Future<void> _loadBookings() async {
    try {
      // Import AuthService at the top of the file if not already imported
      final AuthService authService = AuthService();
      final rawBookings = await authService.getUserBookingsAsGuest();

      if (mounted) {
        setState(() {
          _bookings = rawBookings.map((booking) {
            // Calculate duration in hours
            final startTime = DateTime.parse(booking['start_time']);
            final endTime = DateTime.parse(booking['end_time']);
            final durationHours = endTime.difference(startTime).inHours;

            // Calculate hourly rate from total price and duration
            final hourlyRate = durationHours > 0
                ? (booking['total_price'] as num).toDouble() / durationHours
                : 0.0;

            // Transform booking status to UI status
            String uiStatus;
            switch (booking['status']) {
              case 'confirmed':
                uiStatus = 'active';
                break;
              case 'pending':
                uiStatus = 'upcoming';
                break;
              case 'completed':
                uiStatus = 'completed';
                break;
              case 'cancelled':
                uiStatus = 'cancelled';
                break;
              default:
                uiStatus = 'unknown';
            }

            // Determine vehicle type based on listing parking type and rates
            String vehicleType = 'Car'; // Default
            final listing = booking['listings'];
            if (listing != null) {
              final parkingType = listing['parking_type'];
              final hasBikeRate = listing['hourly_rate_bike'] != null;
              final hasCarRate = listing['hourly_rate_car'] != null;

              if (parkingType == 'Bike' || (parkingType == 'Both' && !hasCarRate && hasBikeRate)) {
                vehicleType = 'Bike';
              } else if (parkingType == 'Both') {
                vehicleType = 'Car'; // Default to car for both
              } else {
                vehicleType = parkingType ?? 'Car';
              }
            }

            return {
              'id': booking['id'],
              'parking_title': booking['listings']?['parking_space_name'] ?? 'Unknown Parking',
              'address': booking['listings']?['parking_address'] ?? 'Unknown Address',
              'start_time': startTime,
              'end_time': endTime,
              'status': uiStatus,
              'total_price': (booking['total_price'] as num).toDouble(),
              'hourly_rate': hourlyRate,
              'duration_hours': durationHours,
              'host_name': booking['profiles']?['full_name'] ?? 'Unknown Host',
              'rating': 4.5, // Default rating since not stored in current schema
              'vehicle_type': vehicleType,
              'spot_number': 'TBD', // Spot number not tracked in current schema
            };
          }).toList();

          _filteredBookings = List.from(_bookings);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookings = [];
          _filteredBookings = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shadowColor: const Color(0x1F000000),
            elevation: 2,
          ),
        ),
        title: const Text(
          'Booking History',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFF6366F1)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sort options - Coming soon!')),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            )
          : Column(
              children: [
                // Statistics Overview
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
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
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Bookings',
                          '${_bookings.length}',
                          Icons.calendar_today,
                          const Color(0xFFFFFFFF),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Active',
                          '${_bookings.where((b) => b['status'] == 'active').length}',
                          Icons.access_time,
                          const Color(0xFFFFFFFF),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Total Spent',
                          '\$${_calculateTotalSpent().toStringAsFixed(0)}',
                          Icons.attach_money,
                          const Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterBookings();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bookings...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Enhanced Tab Bar
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
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Active'),
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bookings List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(_filteredBookings),
                      _buildBookingsList(_filteredBookings.where((b) => b['status'] == 'active').toList()),
                      _buildBookingsList(_filteredBookings.where((b) => b['status'] == 'upcoming').toList()),
                      _buildBookingsList(_filteredBookings.where((b) => b['status'] == 'completed' || b['status'] == 'cancelled').toList()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = const Color(0xFF4CAF50);
        text = 'Active';
        break;
      case 'upcoming':
        color = const Color(0xFF2196F3);
        text = 'Upcoming';
        break;
      case 'completed':
        color = const Color(0xFF9C27B0);
        text = 'Completed';
        break;
      case 'cancelled':
        color = const Color(0xFFFF4444);
        text = 'Cancelled';
        break;
      default:
        color = const Color(0xFF9E9E9E);
        text = 'Unknown';
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _calculateTotalSpent() {
    return _bookings
        .where((booking) => booking['status'] != 'cancelled')
        .fold(0.0, (sum, booking) => sum + (booking['total_price'] as double));
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 48,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No bookings found' : 'No bookings match your search',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Your booking history will appear here'
                  : 'Try adjusting your search or filter',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking['parking_title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    _buildStatusBadge(booking['status']),
                  ],
                ),

                const SizedBox(height: 8),

                // Address
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking['address'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Time and duration
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDateTime(booking['start_time'])} - ${_formatDateTime(booking['end_time'])}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Price and rating
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${booking['total_price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${booking['rating']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Vehicle type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking['vehicle_type'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons based on status
                if (booking['status'] == 'active') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Extend booking - Coming soon!')),
                          ),
                          icon: const Icon(Icons.access_time),
                          label: const Text('Extend'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            foregroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cancel booking - Coming soon!')),
                          ),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (booking['status'] == 'upcoming') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Modify booking - Coming soon!')),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Modify'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            foregroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cancel booking - Coming soon!')),
                          ),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (booking['status'] == 'completed') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download receipt - Coming soon!')),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }
}
