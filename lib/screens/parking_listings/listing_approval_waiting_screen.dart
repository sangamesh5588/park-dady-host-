import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ListingApprovalWaitingScreen extends StatefulWidget {
  const ListingApprovalWaitingScreen({super.key});

  @override
  State<ListingApprovalWaitingScreen> createState() => _ListingApprovalWaitingScreenState();
}

class _ListingApprovalWaitingScreenState extends State<ListingApprovalWaitingScreen> {
  bool _isCheckingStatus = false;

  Future<void> _checkListingStatus() async {
    if (_isCheckingStatus) return; // Prevent multiple simultaneous checks

    setState(() => _isCheckingStatus = true);

    try {
      final authService = AuthService();
      final status = await authService.getLatestListingStatus();

      if (!mounted) return;

      switch (status) {
        case 'approved':
          // Status changed to approved - navigate to home with success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Congratulations! Your listing has been approved!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/main');
          break;

        case 'rejected':
          // Status changed to rejected - navigate to rejection screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your listing status has been updated'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/listing_rejected');
          break;

        case 'pending':
          // Still pending - show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your listing is still under review. We\'ll notify you when there\'s an update.'),
              backgroundColor: Colors.blue,
            ),
          );
          break;

        default:
          // Unknown status or error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to check status. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error checking status. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Status'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Container(
        color: const Color(0xFFF8F9FA), // Light gray background
        child: SafeArea(
          child: Column(
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), // Light orange background
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Under Review',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          Text(
                            'Submitted on Dec 12, 2025',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Main message card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Clock icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFFF59E0B),
                                size: 32,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Title
                            Text(
                              "Your listing is being reviewed",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              "Thank you for your patience! Our team carefully reviews every submission to ensure quality. You'll hear back within 24-48 hours.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Review process card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'What we check',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCheckItem(
                              '✅ Photo quality and authenticity',
                            ),
                            const SizedBox(height: 8),
                            _buildCheckItem(
                              '✅ Location accuracy and safety',
                            ),
                            const SizedBox(height: 8),
                            _buildCheckItem(
                              '✅ Pricing competitiveness',
                            ),
                            const SizedBox(height: 8),
                            _buildCheckItem(
                              '✅ Complete and accurate information',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Timeline card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.timeline_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Review timeline',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTimelineItem(
                              '📋 Submission received',
                              'Your listing has been added to our review queue',
                              true,
                            ),
                            const SizedBox(height: 16),
                            _buildTimelineItem(
                              '🔍 Quality review',
                              'Our team is carefully checking your submission',
                              true,
                            ),
                            const SizedBox(height: 16),
                            _buildTimelineItem(
                              '✅ Final decision',
                              'Approval or feedback within 24-48 hours',
                              false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Primary action - Check Status
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checkListingStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Check Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to support
                              Navigator.of(context).pushNamed('/support');
                            },
                            icon: const Icon(Icons.help_outline, size: 18),
                            label: const Text('Need Help?'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/main');
                            },
                            icon: const Icon(Icons.home_outlined, size: 18),
                            label: const Text('Home'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String description, bool completed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: completed ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: completed
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                )
              : Container(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: completed ? Colors.grey[900] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


}
