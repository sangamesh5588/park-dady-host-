import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostApprovalWaitingScreen extends StatefulWidget {
  const HostApprovalWaitingScreen({super.key});

  @override
  State<HostApprovalWaitingScreen> createState() => _HostApprovalWaitingScreenState();
}

class _HostApprovalWaitingScreenState extends State<HostApprovalWaitingScreen> {
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    setState(() => _isCheckingStatus = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Check if profile is approved
      final response = await Supabase.instance.client
          .from('host_profiles')
          .select('status')
          .eq('user_id', userId)
          .single();

      final status = response['status'];

      if (status == 'approved') {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else if (status == 'rejected') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your application was rejected. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
          // Navigate back to login or show error screen
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      // Handle error - maybe profile not found yet
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Application Submitted!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Your host profile has been submitted for review. Our team will verify your documents and approve your account within 24-48 hours.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Status card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current Status: Under Review',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will notify you once your application is approved.',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Check status button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCheckingStatus ? null : _checkApprovalStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCheckingStatus
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Check Status',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact support button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement contact support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact support - Coming soon!')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
