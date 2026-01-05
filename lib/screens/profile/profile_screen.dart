import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'parking_slots_screen.dart';
import '../booking/bookings_screen.dart';
import 'transactions_screen.dart';
import 'earnings_screen.dart';
import 'support_screen.dart';
import 'rules_tips_screen.dart';
import 'report_issue_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'data_usage_screen.dart';
import 'data_deletion_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;

          // Initialize controllers with current values
          _nameController.text = profile?['full_name'] ?? '';
          _phoneController.text = profile?['phone_number'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      await _authService.updateUserProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() => _isEditing = false);
        await _loadUserProfile(); // Refresh profile data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n• Profile information\n• Parking listings\n• Bookings and transactions\n• All associated records',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1A1A1A),
          ),
        ),
      );

      try {
        await _authService.deleteAccount();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Navigate to onboarding/login screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/onboarding',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1A1A1A),
          ),
        ),
      );
    }

    final profile = _userProfile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('Unable to load profile'),
        ),
      );
    }

    final isHost = profile['role'] == 'host';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Minimal header
              Center(
                child: Column(
                  children: [
                    // Simple avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5F5F5),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(profile),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name and role
                    Text(
                      profile['full_name'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isHost ? 'Host' : 'Host',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Clean menu items
              _buildMenuItem(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                  // Refresh profile if changes were made
                  if (result == true && mounted) {
                    await _loadUserProfile();
                  }
                },
              ),

              if (isHost) ...[
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.local_parking_outlined,
                  title: 'Parking Slots',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ParkingSlotsScreen()),
                  ),
                ),

                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Manage Slots',
                  onTap: () => Navigator.of(context).pushNamed('/manage_slots'),
                ),
              ],

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.history_outlined,
                title: 'Booking History',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BookingsScreen()),
                ),
              ),



              if (isHost) ...[
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.attach_money_outlined,
                  title: 'Earnings',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EarningsScreen()),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Simple divider
              Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),

              const SizedBox(height: 24),

              // Support section
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Support & Help',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SupportScreen()),
                ),
              ),

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.rule_outlined,
                title: 'Rules & Tips',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RulesTipsScreen()),
                ),
              ),

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.report_problem_outlined,
                title: 'Report Issue',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                ),
              ),

              const SizedBox(height: 24),

              // Simple divider
              Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),

              const SizedBox(height: 24),

              // Legal section
              _buildMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                ),
              ),

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
                ),
              ),

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.security_outlined,
                title: 'Data Usage & Permissions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DataUsageScreen()),
                ),
              ),

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.delete_forever_outlined,
                title: 'Data Deletion Request',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DataDeletionScreen()),
                ),
              ),

              const SizedBox(height: 24),

              // Simple divider
              Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),

              const SizedBox(height: 24),

              // App Info section
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                ),
              ),

              const SizedBox(height: 24),

              // Simple divider
              Container(
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),

              const SizedBox(height: 24),

              // Account actions
              _buildMenuItem(
                icon: Icons.logout_outlined,
                title: 'Sign Out',
                textColor: const Color(0xFFDC2626),
                onTap: _signOut,
              ),

              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                textColor: const Color(0xFFDC2626),
                onTap: _deleteAccount,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(Map<String, dynamic> profile) {
    // Try to get initials from full name first
    final fullName = profile['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final nameParts = fullName.trim().split(' ');
      if (nameParts.length >= 2) {
        // First letter of first name + first letter of last name
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        // Just first letter of single name
        return nameParts[0][0].toUpperCase();
      }
    }

    // Fallback to email
    final email = profile['email'] as String?;
    if (email != null && email.trim().isNotEmpty) {
      return email[0].toUpperCase();
    }

    // Final fallback
    return 'U';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';

    try {
      final DateTime dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }



  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A1A1A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1A1A1A),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAuthProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return const Icon(Icons.g_mobiledata, color: Colors.red);
      case 'apple':
        return const Icon(Icons.apple, color: Colors.black);
      case 'email':
      default:
        return const Icon(Icons.email, color: Colors.blue);
    }
  }

  String _getAuthProviderDisplayName(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return 'Google Account';
      case 'apple':
        return 'Apple ID';
      case 'email':
      default:
        return 'Email & Password';
    }
  }
}
