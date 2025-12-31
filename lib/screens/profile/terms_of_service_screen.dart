import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  Future<void> _openTermsOfService() async {
    const url = 'https://splendorous-strudel-cead22.netlify.app/terms/';

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Show a message that the URL is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terms of Service URL not configured yet. Please check back later.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Terms of Service: $e'),
            duration: const Duration(seconds: 3),
          ),
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
          'Terms of Service',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Effective date: ${DateTime.now().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Access Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: _openTermsOfService,
                  icon: const Icon(Icons.open_in_browser, color: Colors.white),
                  label: const Text('View Full Terms of Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Key Terms Summary
              const Text(
                'Key Terms Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 16),

              _buildTermsPoint(
                icon: Icons.account_circle_outlined,
                title: 'User Accounts & Verification',
                description: 'All users must provide accurate information and complete identity verification. Hosts must verify property ownership and provide identification documents.',
              ),

              _buildTermsPoint(
                icon: Icons.local_parking_outlined,
                title: 'Parking Space Listings',
                description: 'Hosts are responsible for accurately describing parking spaces, including dimensions, access methods, restrictions, and availability. Misrepresentation may result in account suspension.',
              ),

              _buildTermsPoint(
                icon: Icons.book_online_outlined,
                title: 'Booking & Reservation System',
                description: 'Users can book parking spaces in advance. Bookings are confirmed instantly and both parties receive booking confirmations. Hosts must make spaces available as listed.',
              ),

              _buildTermsPoint(
                icon: Icons.payment_outlined,
                title: 'Payments & Platform Fees',
                description: 'Payments are processed securely through certified partners. Hosts receive payments after successful bookings, minus platform fees. Users pay the listed rate plus any applicable fees.',
              ),

              _buildTermsPoint(
                icon: Icons.access_time_outlined,
                title: 'Access & Parking Duration',
                description: 'Users receive access instructions upon booking confirmation. Parking duration is clearly specified in each booking. Overtime parking may incur additional charges.',
              ),

              _buildTermsPoint(
                icon: Icons.cancel_outlined,
                title: 'Cancellation & Refund Policy',
                description: 'Cancellations made 24+ hours before booking start receive full refunds. Late cancellations may forfeit payments. Hosts must honor confirmed bookings.',
              ),

              _buildTermsPoint(
                icon: Icons.car_crash_outlined,
                title: 'Vehicle Safety & Damage',
                description: 'Users are responsible for their vehicles while parked. Any damage to host property or other vehicles must be reported immediately. ParkingHost is not liable for vehicle damage or theft.',
              ),

              _buildTermsPoint(
                icon: Icons.report_outlined,
                title: 'Prohibited Activities',
                description: 'Illegal parking, property damage, fraudulent bookings, harassment, or violation of local parking regulations will result in immediate account suspension.',
              ),

              _buildTermsPoint(
                icon: Icons.star_rate_outlined,
                title: 'Ratings & Reviews',
                description: 'Both hosts and users can rate their experience after each booking. Accurate, honest feedback helps maintain platform quality and trust.',
              ),

              const SizedBox(height: 32),

              // Important Notices
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEAA7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: Color(0xFF856404),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Important Notices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Service availability may vary by location\n• ParkingHost is not responsible for property damage or theft\n• Users must comply with all local parking regulations\n• Platform fees apply to all transactions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF856404),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contact Information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Questions about our terms?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If you have any questions about these terms, please contact our legal team.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 20,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'legal@parkinghost.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Acceptance Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Text(
                  'By using ParkingHost, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and our Privacy Policy.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E40AF),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
