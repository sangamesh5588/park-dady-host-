import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/support_screen.dart';
import 'screens/host_onboarding/host_onboarding_screen.dart';
import 'screens/host_onboarding/host_approval_waiting_screen.dart';
import 'screens/parking_listings/create_listing_screen.dart';
import 'screens/parking_listings/listing_approval_waiting_screen.dart';
import 'screens/parking_listings/listing_rejected_screen.dart';
import 'screens/manage_slots/manage_slots_screen.dart';
import 'services/auth_service.dart';
import 'services/permission_service.dart';
import 'services/booking_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, continue without it
    // Social authentication may not work properly.
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL', fallback: 'https://your-project-url.supabase.co'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY', fallback: 'your-supabase-anon-key'),
  );

  runApp(const ParkingHostApp());
}

class ParkingHostApp extends StatefulWidget {
  const ParkingHostApp({super.key});

  @override
  State<ParkingHostApp> createState() => _ParkingHostAppState();
}

class _ParkingHostAppState extends State<ParkingHostApp> {
  final AuthService _authService = AuthService();
  final PermissionService _permissionService = PermissionService();
  final ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while determining auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'Parking Host',
            debugShowCheckedModeBanner: false,
            themeMode: _themeMode,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              colorScheme: const ColorScheme.light(
                primary: AppColors.uberOrange,
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFFFF3E0),
                onPrimaryContainer: AppColors.uberOrange,
                secondary: AppColors.uberOrange,
                onSecondary: Colors.white,
                secondaryContainer: Color(0xFFFFF3E0),
                onSecondaryContainer: AppColors.uberOrange,
                surface: Colors.white,
                onSurface: Color(0xFF1F2937),
                surfaceContainerHighest: Colors.white,
                surfaceContainerHigh: Color(0xFFF8F9FA),
                surfaceContainer: Color(0xFFF3F4F6),
                surfaceContainerLow: Color(0xFFF8F9FA),
                surfaceContainerLowest: Colors.white,
                outline: Color(0xFFE5E7EB),
                outlineVariant: Color(0xFFD1D5DB),
                error: Color(0xFFEF4444),
                onError: Colors.white,
              ),
              platform: TargetPlatform.android,
            ),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final authState = snapshot.data;
        final isAuthenticated = authState?.session != null;

        return FutureBuilder<Widget>(
          future: _getInitialScreen(isAuthenticated),
          builder: (context, screenSnapshot) {
            if (screenSnapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                title: 'Parking Host',
                debugShowCheckedModeBanner: false,
                themeMode: _themeMode,
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.white,
                colorScheme: const ColorScheme.light(
                  primary: AppColors.uberOrange,
                  onPrimary: Colors.white,
                  primaryContainer: Color(0xFFFFF3E0),
                  onPrimaryContainer: AppColors.uberOrange,
                  secondary: AppColors.uberOrange,
                  onSecondary: Colors.white,
                  secondaryContainer: Color(0xFFFFF3E0),
                  onSecondaryContainer: AppColors.uberOrange,
                  surface: Colors.white,
                  onSurface: Color(0xFF1F2937),
                  surfaceContainerHighest: Colors.white,
                  surfaceContainerHigh: Color(0xFFF8F9FA),
                  surfaceContainer: Color(0xFFF3F4F6),
                  surfaceContainerLow: Color(0xFFF8F9FA),
                  surfaceContainerLowest: Colors.white,
                  outline: Color(0xFFE5E7EB),
                  outlineVariant: Color(0xFFD1D5DB),
                  error: Color(0xFFEF4444),
                  onError: Colors.white,
                ),
                platform: TargetPlatform.android,
              ),
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            return MaterialApp(
              title: 'Parking Host',
              debugShowCheckedModeBanner: false,
              themeMode: _themeMode,
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.white,
                colorScheme: const ColorScheme.light(
                  primary: AppColors.uberOrange,
                  onPrimary: Colors.white,
                  primaryContainer: Color(0xFFFFF3E0),
                  onPrimaryContainer: AppColors.uberOrange,
                  secondary: AppColors.uberOrange,
                  onSecondary: Colors.white,
                  secondaryContainer: Color(0xFFFFF3E0),
                  onSecondaryContainer: AppColors.uberOrange,
                  surface: Colors.white,
                  onSurface: Color(0xFF1F2937),
                  surfaceContainerHighest: Colors.white,
                  surfaceContainerHigh: Color(0xFFF8F9FA),
                  surfaceContainer: Color(0xFFF3F4F6),
                  surfaceContainerLow: Color(0xFFF8F9FA),
                  surfaceContainerLowest: Colors.white,
                  outline: Color(0xFFE5E7EB),
                  outlineVariant: Color(0xFFD1D5DB),
                  error: Color(0xFFEF4444),
                  onError: Colors.white,
                ),
                platform: TargetPlatform.android,
              ),
              home: screenSnapshot.data ?? const SplashScreen(),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignupScreen(),
                '/main': (context) => const MainNavigationScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/host_onboarding': (context) => const HostOnboardingScreen(),
                '/host_approval_waiting': (context) => const HostApprovalWaitingScreen(),
                '/create_listing': (context) => const CreateListingScreen(),
                '/listing_approval_waiting': (context) => const ListingApprovalWaitingScreen(),
                '/listing_rejected': (context) => const ListingRejectedScreen(),
                '/manage_slots': (context) => const ManageSlotsScreen(),
                '/support': (context) => const SupportScreen(),
              },
            );
          },
        );
      },
    );
  }

  Future<Widget> _getInitialScreen(bool isAuthenticated) async {
    // CRITICAL: If not authenticated, always go to login flow
    if (!isAuthenticated) {
      return const SplashScreen();
    }

    // Double-check authentication with current user
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      // No valid session - force logout and go to login
      await _authService.signOut();
      return const SplashScreen();
    }

    // Check if user profile exists in database
    final userExists = await _checkUserExistsInDatabase(currentUser.id);
    if (!userExists) {
      // User authenticated but profile not created - force logout and go to login
      await _authService.signOut();
      return const SplashScreen();
    }

    // Authenticated user with valid profile found - proceed with validation
    try {
      // Enable host functionality when user logs into HOST app
      await _authService.enableHostRole();

      // Initialize notification service for new bookings
      final notificationService = BookingNotificationService();
      await notificationService.initialize();
      await notificationService.startListeningForBookings(currentUser.id);

      final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();

      if (!hasCompletedOnboarding) {
        // First-time user - show onboarding (mandatory)
        return const OnboardingScreen();
      }

      // User has completed onboarding - validate critical permissions
      final hasPermissions = await _permissionService.hasAllCriticalPermissions();
      if (!hasPermissions) {
        // Permissions not granted - show permission validation screen
        return _buildPermissionValidationScreen();
      }

      // Check host profile status
      final hostProfileStatus = await _getHostProfileStatus();
      if (hostProfileStatus == null) {
        // No host profile exists - show host onboarding
        return const HostOnboardingScreen();
      } else if (hostProfileStatus == 'pending_approval') {
        // Profile submitted but pending approval - show approval waiting
        return const HostApprovalWaitingScreen();
      } else if (hostProfileStatus == 'approved') {
        // Profile approved - show main app
        return const MainNavigationScreen();
      } else if (hostProfileStatus == 'rejected') {
        // Profile rejected - could allow re-submission or show error
        // For now, show approval waiting with rejection info
        return const HostApprovalWaitingScreen();
      }

      // Fallback - show main app
      return const MainNavigationScreen();
    } catch (e) {
      // Error checking status - force logout for security
      await _authService.signOut();
      return const SplashScreen();
    }
  }

  Future<bool> _checkUserExistsInDatabase(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // If error checking, assume user doesn't exist for security
      return false;
    }
  }

  Future<String?> _getHostProfileStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('host_profiles')
          .select('status')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      // If no profile exists or error, return null
      return null;
    }
  }

  Future<bool> _hasCompletedHostProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('host_profiles')
          .select('status')
          .eq('user_id', userId)
          .single();

      final status = response['status'];
      return status == 'approved';
    } catch (e) {
      // If no profile exists or error, user hasn't completed host onboarding
      return false;
    }
  }

  Widget _buildPermissionValidationScreen() {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _permissionService.validateAppEntryPermissions(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final permissionsGranted = snapshot.data ?? false;

            if (permissionsGranted) {
              // Permissions granted - navigate to main app
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/main');
              });
              return const Center(child: CircularProgressIndicator());
            } else {
              // Permissions denied - show error and exit option
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Permissions Required',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Location permission is required to use Parking Host. Please grant the permission to continue.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          final granted = await _permissionService.validateAppEntryPermissions(context);
                          if (granted && mounted) {
                            Navigator.of(context).pushReplacementNamed('/main');
                          }
                        },
                        child: const Text('Grant Permission'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Exit app
                          // Note: This will close the app on mobile
                        },
                        child: const Text('Exit App'),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
