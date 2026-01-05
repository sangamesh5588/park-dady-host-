import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication guard widget that protects routes
/// Redirects to onboarding if user is not authenticated
class AuthGuard extends StatefulWidget {
  final Widget child;
  final bool checkProfile;

  const AuthGuard({
    super.key,
    required this.child,
    this.checkProfile = true,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _hasRedirected = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthentication(),
      builder: (context, snapshot) {
        // Show loading while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }

        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated && !_hasRedirected) {
          // Not authenticated - redirect to onboarding once
          _hasRedirected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/onboarding',
                (route) => false,
              );
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }

        // Authenticated - show the protected content
        return widget.child;
      },
    );
  }

  Future<bool> _checkAuthentication() async {
    try {
      // Check if user is authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Optionally check if profile exists in database
      if (widget.checkProfile) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (response == null) {
          // Profile doesn't exist - sign out and redirect
          await Supabase.instance.client.auth.signOut();
          return false;
        }
      }

      return true;
    } catch (e) {
      // On error, assume not authenticated for security
      return false;
    }
  }
}
