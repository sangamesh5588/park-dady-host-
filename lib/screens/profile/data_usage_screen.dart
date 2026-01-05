import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  Map<Permission, PermissionStatus> _permissions = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = await [
      Permission.location,
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();

    if (mounted) {
      setState(() {
        _permissions = permissions;
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shadowColor: const Color(0x1F000000),
            elevation: 2,
          ),
        ),
        title: const Text(
          'Data Usage & Permissions',
          style: TextStyle(
            color: Colors.black,
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
                      Icons.security_outlined,
                      size: 48,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How We Use Your Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We collect data to provide and improve our parking services',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data Collection Overview
              const Text(
                'Data We Collect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 16),

              _buildDataPoint(
                icon: Icons.account_circle_outlined,
                title: 'Account & Profile Information',
                description: 'Name, email, phone number, profile photos, and vehicle information for account creation and host verification',
                purpose: 'Account management, identity verification, and communication between hosts and renters',
                storage: 'Stored securely in encrypted database',
              ),

              _buildDataPoint(
                icon: Icons.location_on_outlined,
                title: 'Location & Navigation Data',
                description: 'Precise GPS coordinates for parking space locations, user location for nearby search results, and turn-by-turn navigation',
                purpose: 'Core parking discovery and navigation functionality',
                storage: 'Location data used in real-time for searches, not permanently stored',
              ),

              _buildDataPoint(
                icon: Icons.local_parking_outlined,
                title: 'Parking Space Details',
                description: 'Space dimensions, access instructions, photos, amenities, restrictions, and availability schedules provided by hosts',
                purpose: 'Accurate space representation and booking verification',
                storage: 'Stored in cloud storage with host profile data',
              ),

              _buildDataPoint(
                icon: Icons.book_online_outlined,
                title: 'Booking & Transaction Records',
                description: 'Complete booking history, payment amounts, space utilization, check-in/out times, and booking modifications',
                purpose: 'Service delivery, payment processing, and dispute resolution',
                storage: 'Retained for 7 years for legal compliance and service improvement',
              ),

              _buildDataPoint(
                icon: Icons.payment_outlined,
                title: 'Payment & Financial Data',
                description: 'Payment method details, transaction amounts, and payout information processed through certified payment processors',
                purpose: 'Secure payment processing and host earnings distribution',
                storage: 'Payment data never stored on our servers - handled by PCI-compliant partners',
              ),

              _buildDataPoint(
                icon: Icons.business_outlined,
                title: 'Host Verification Documents',
                description: 'Property ownership documents, identification, vehicle registrations, and business licenses for host verification',
                purpose: 'Platform safety, fraud prevention, and regulatory compliance',
                storage: 'Stored securely with strict access controls and encryption',
              ),

              _buildDataPoint(
                icon: Icons.star_rate_outlined,
                title: 'Ratings & Reviews',
                description: 'User ratings, review comments, and feedback on parking spaces and booking experiences',
                purpose: 'Quality assurance and platform improvement',
                storage: 'Public reviews stored indefinitely, private feedback retained for support',
              ),

              const SizedBox(height: 32),

              // Permissions Section
              const Text(
                'App Permissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 16),

              _buildPermissionStatus(
                icon: Icons.location_on,
                title: 'Location',
                description: 'Access to GPS for finding nearby parking',
                permission: Permission.location,
                status: _permissions[Permission.location],
              ),

              _buildPermissionStatus(
                icon: Icons.camera,
                title: 'Camera',
                description: 'Take photos of parking spaces (hosts only)',
                permission: Permission.camera,
                status: _permissions[Permission.camera],
              ),

              _buildPermissionStatus(
                icon: Icons.photo_library,
                title: 'Photos',
                description: 'Access photo gallery for uploading images',
                permission: Permission.photos,
                status: _permissions[Permission.photos],
              ),

              _buildPermissionStatus(
                icon: Icons.notifications,
                title: 'Notifications',
                description: 'Receive booking updates and reminders',
                permission: Permission.notification,
                status: _permissions[Permission.notification],
              ),

              const SizedBox(height: 24),

              // Manage Permissions Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings, color: Colors.white),
                  label: const Text('Manage Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
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

              // Data Rights
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Data Rights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDataRight(
                      icon: Icons.visibility_outlined,
                      title: 'Access',
                      description: 'Request a copy of your data',
                    ),
                    _buildDataRight(
                      icon: Icons.edit_outlined,
                      title: 'Rectification',
                      description: 'Correct inaccurate data',
                    ),
                    _buildDataRight(
                      icon: Icons.delete_outline,
                      title: 'Deletion',
                      description: 'Request complete data removal',
                    ),
                    _buildDataRight(
                      icon: Icons.portable_wifi_off_outlined,
                      title: 'Portability',
                      description: 'Download your data in portable format',
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
                      'Questions about data usage?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Contact our privacy team if you have questions about how we use your data.',
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
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'privacy@parkinghost.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPoint({
    required IconData icon,
    required String title,
    required String description,
    required String purpose,
    required String storage,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purpose: $purpose',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Storage: $storage',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatus({
    required IconData icon,
    required String title,
    required String description,
    required Permission permission,
    required PermissionStatus? status,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == null) {
      statusColor = Colors.grey;
      statusText = 'Checking...';
      statusIcon = Icons.help_outline;
    } else if (status.isGranted) {
      statusColor = Colors.black;
      statusText = 'Granted';
      statusIcon = Icons.check_circle;
    } else if (status.isDenied) {
      statusColor = Colors.black.withOpacity(0.6);
      statusText = 'Denied';
      statusIcon = Icons.cancel;
    } else if (status.isPermanentlyDenied) {
      statusColor = Colors.grey;
      statusText = 'Permanently Denied';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRight({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
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
