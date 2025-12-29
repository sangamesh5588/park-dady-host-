import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DataDeletionScreen extends StatefulWidget {
  const DataDeletionScreen({super.key});

  @override
  State<DataDeletionScreen> createState() => _DataDeletionScreenState();
}

class _DataDeletionScreenState extends State<DataDeletionScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();
  bool _confirmDeletion = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitDeletionRequest() async {
    if (!_confirmDeletion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you want to delete your data'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Here you would typically send the deletion request to your backend
      // For now, we'll simulate the process

      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data deletion request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendDeletionEmail() async {
    final String reason = _reasonController.text.trim();
    final String body = '''
Dear ParkingHost Privacy Team,

I am requesting the complete deletion of my account data and personal information from your systems.

Account Details:
- Request Date: ${DateTime.now().toString().split(' ')[0]}
${reason.isNotEmpty ? '- Reason for deletion: $reason' : ''}

Data to be deleted includes:
- Account profile and personal information
- Parking space listings (if applicable)
- Booking records and transaction history
- Payment information and payout records
- Ratings, reviews, and feedback
- Communication records and messages
- Location data and search history

Please confirm when this deletion has been completed and provide a confirmation of the data removal.

Thank you,
ParkingHost User
        ''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'privacy@parkinghost.com',
      queryParameters: {
        'subject': 'Data Deletion Request - Account Removal',
        'body': body.trim(),
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email client opened successfully. Please send the email to complete your request.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email client found. Please email privacy@parkinghost.com manually.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email client: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
          'Data Deletion Request',
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
              // Warning Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEAA7)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Color(0xFF856404),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Important Notice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF856404),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Data deletion is permanent and cannot be undone. All your account information, booking history, and preferences will be permanently removed.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF856404),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // What Gets Deleted
              const Text(
                'What Will Be Deleted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 16),

              _buildDeletionItem(
                icon: Icons.account_circle_outlined,
                title: 'Account Profile',
                description: 'Name, email, phone number, profile photo, and account preferences',
              ),

              _buildDeletionItem(
                icon: Icons.local_parking_outlined,
                title: 'Parking Space Listings',
                description: 'All parking spaces listed by you as a host, including photos and descriptions',
              ),

              _buildDeletionItem(
                icon: Icons.book_online_outlined,
                title: 'Booking Records',
                description: 'Complete history of all parking bookings made and received, including past and future reservations',
              ),

              _buildDeletionItem(
                icon: Icons.payment_outlined,
                title: 'Payment & Transaction Data',
                description: 'Payment methods, transaction history, payout records, and financial information',
              ),

              _buildDeletionItem(
                icon: Icons.business_outlined,
                title: 'Host Verification Documents',
                description: 'Property ownership documents, identification, and verification materials',
              ),

              _buildDeletionItem(
                icon: Icons.star_rate_outlined,
                title: 'Ratings & Reviews',
                description: 'All ratings given and received, review comments, and feedback history',
              ),

              _buildDeletionItem(
                icon: Icons.message_outlined,
                title: 'Communication Records',
                description: 'Messages, notifications, and communication history with other users',
              ),

              _buildDeletionItem(
                icon: Icons.location_on_outlined,
                title: 'Location & Search History',
                description: 'Saved locations, search preferences, and location-based browsing history',
              ),

              const SizedBox(height: 24),

              // What Stays
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What May Remain',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Anonymized analytics data\n• Legal records required by law\n• Information needed for dispute resolution\n• Data already processed by third parties',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reason for Deletion (Optional)
              const Text(
                'Reason for Deletion (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please tell us why you want to delete your data...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Confirmation Checkbox
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _confirmDeletion,
                      onChanged: (value) {
                        setState(() => _confirmDeletion = value ?? false);
                      },
                      activeColor: const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I understand that this action cannot be undone and all my data will be permanently deleted.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitDeletionRequest,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.delete_forever, color: Colors.white),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Deletion Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: OutlinedButton.icon(
                      onPressed: _sendDeletionEmail,
                      icon: const Icon(Icons.email_outlined, color: Color(0xFF6366F1)),
                      label: const Text('Send via Email Instead'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
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
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If you have questions about data deletion or need assistance, contact our privacy team.',
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
                          'privacy@parkinghost.com',
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
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
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFDC2626),
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
        ],
      ),
    );
  }
}
