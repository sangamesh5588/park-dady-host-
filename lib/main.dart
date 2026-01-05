import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
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
import 'widgets/auth_guard.dart';

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
  bool _showSplash = true; // Always show splash on app start

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while determining auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'ParkDady Host',
            debugShowCheckedModeBanner: false,
            themeMode: _themeMode,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFFAFAFA),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1A1A1A),
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFF5F5F5),
                onPrimaryContainer: Color(0xFF1A1A1A),
                secondary: Color(0xFF1A1A1A),
                onSecondary: Colors.white,
                secondaryContainer: Color(0xFFF5F5F5),
                onSecondaryContainer: Color(0xFF1A1A1A),
                surface: Colors.white,
                onSurface: Color(0xFF1A1A1A),
                surfaceContainerHighest: Colors.white,
                surfaceContainerHigh: Color(0xFFFAFAFA),
                surfaceContainer: Color(0xFFF5F5F5),
                surfaceContainerLow: Color(0xFFFAFAFA),
                surfaceContainerLowest: Colors.white,
                outline: Color(0xFFE0E0E0),
                outlineVariant: Color(0xFFF0F0F0),
                error: Color(0xFF1A1A1A),
                onError: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1A1A1A),
                elevation: 0,
                centerTitle: false,
                titleTextStyle: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(
                    color: Color(0xFF1A1A1A),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A1A1A),
                    width: 2,
                  ),
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF1A1A1A),
                ),
                hintStyle: TextStyle(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.4),
                ),
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

        // Always show splash screen first, then determine next screen
        if (_showSplash) {
          // Schedule navigation after splash screen animations complete
          // Total splash duration: ~2500ms (animations + status text changes)
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 2500));
            if (mounted) {
              setState(() => _showSplash = false);
            }
          });
        }

        return FutureBuilder<Widget>(
          future: _showSplash ? Future.value(const SplashScreen()) : _getInitialScreen(isAuthenticated),
          builder: (context, screenSnapshot) {
            if (screenSnapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                title: 'ParkDady Host',
                debugShowCheckedModeBanner: false,
                themeMode: _themeMode,
                theme: ThemeData(
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1A1A1A),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1A1A1A),
                  ),
                  platform: TargetPlatform.android,
                ),
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                  )),
                ),
              );
            }

            return MaterialApp(
              title: 'ParkDady Host',
              debugShowCheckedModeBanner: false,
              themeMode: _themeMode,
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFFFAFAFA),
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1A1A1A),
                  onPrimary: Colors.white,
                  primaryContainer: Color(0xFFF5F5F5),
                  onPrimaryContainer: Color(0xFF1A1A1A),
                  secondary: Color(0xFF1A1A1A),
                  onSecondary: Colors.white,
                  secondaryContainer: Color(0xFFF5F5F5),
                  onSecondaryContainer: Color(0xFF1A1A1A),
                  surface: Colors.white,
                  onSurface: Color(0xFF1A1A1A),
                  surfaceContainerHighest: Colors.white,
                  surfaceContainerHigh: Color(0xFFFAFAFA),
                  surfaceContainer: Color(0xFFF5F5F5),
                  surfaceContainerLow: Color(0xFFFAFAFA),
                  surfaceContainerLowest: Colors.white,
                  outline: Color(0xFFE0E0E0),
                  outlineVariant: Color(0xFFF0F0F0),
                  error: Color(0xFF1A1A1A),
                  onError: Colors.white,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1A1A1A),
                  elevation: 0,
                  centerTitle: false,
                  titleTextStyle: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                cardTheme: CardThemeData(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(
                      color: Color(0xFF1A1A1A),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A1A1A),
                      width: 2,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    color: Color(0xFF1A1A1A),
                  ),
                  hintStyle: TextStyle(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.4),
                  ),
                ),
                platform: TargetPlatform.android,
              ),
              home: screenSnapshot.data ?? const SplashScreen(),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignupScreen(),
                '/main': (context) => const AuthGuard(child: MainNavigationScreen()),
                '/onboarding': (context) => const OnboardingScreen(),
                '/host_onboarding': (context) => const AuthGuard(child: HostOnboardingScreen()),
                '/host_approval_waiting': (context) => const HostApprovalWaitingScreen(),
                '/create_listing': (context) => const AuthGuard(child: CreateListingScreen()),
                '/listing_approval_waiting': (context) => const ListingApprovalWaitingScreen(),
                '/listing_rejected': (context) => const ListingRejectedScreen(),
                '/manage_slots': (context) => const AuthGuard(child: ManageSlotsScreen()),
                '/support': (context) => const AuthGuard(child: SupportScreen()),
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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return null;

      final response = await Supabase.instance.client
          .from('host_profiles')
          .select('status')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      print('Error getting host profile status: $e');
      // If no profile exists or error, return null
      return null;
    }
  }

  Future<bool> _hasCompletedHostProfile() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await Supabase.instance.client
          .from('host_profiles')
          .select('status')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return false;

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
                        'Location permission is required to use ParkDady Host. Please grant the permission to continue.',
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
