import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;
  final Map<String, PermissionStatus> _permissionStatuses = {};

  final List<Map<String, dynamic>> _permissions = [
    {
      'title': 'Location Access',
      'description': 'We need your location to show nearby parking spaces and help drivers find your parking spots on the map',
      'icon': Icons.location_on,
      'color': Colors.green,
      'permission': Permission.location,
      'isRequired': true,
    },
    {
      'title': 'Camera Access',
      'description': 'Take photos of your parking spaces to attract more customers',
      'icon': Icons.camera_alt,
      'color': Colors.orange,
      'permission': Permission.camera,
      'isRequired': false,
    },
    {
      'title': 'Photo Library',
      'description': 'Upload existing photos of your parking spaces from your gallery',
      'icon': Icons.photo_library,
      'color': Colors.purple,
      'permission': Platform.isAndroid ? Permission.photos : Permission.photos,
      'isRequired': false,
    },
    {
      'title': 'Notifications',
      'description': 'Get instant alerts about new bookings, messages, and payments',
      'icon': Icons.notifications,
      'color': Colors.red,
      'permission': Permission.notification,
      'isRequired': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    for (final permissionData in _permissions) {
      final permission = permissionData['permission'] as Permission;
      final status = await permission.status;
      _permissionStatuses[permission.toString()] = status;
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestPermission(Permission permission) async {
    setState(() => _isLoading = true);

    try {
      final status = await permission.request();
      _permissionStatuses[permission.toString()] = status;

      if (status.isPermanentlyDenied) {
        await _showOpenSettingsDialog(permission);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permission: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showOpenSettingsDialog(Permission permission) async {
    final permissionName = _getPermissionName(permission);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permissionName permission is required for this feature. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.location) return 'Location';
    if (permission == Permission.camera) return 'Camera';
    if (permission == Permission.photos) return 'Photos';
    if (permission == Permission.notification) return 'Notification';
    return 'This';
  }

  bool _isPermissionGranted(Permission permission) {
    final status = _permissionStatuses[permission.toString()];
    return status != null && status.isGranted;
  }

  bool _areAllRequiredPermissionsGranted() {
    // Check if all required permissions are granted
    for (final permissionData in _permissions) {
      final permission = permissionData['permission'] as Permission;
      final isRequired = permissionData['isRequired'] as bool;

      if (isRequired && !_isPermissionGranted(permission)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed and navigate to host profile setup
    try {
      final authService = AuthService();
      await authService.completeOnboarding();

      // Update permissions status
      final permissionStatuses = <String, bool>{};
      for (final permissionData in _permissions) {
        final permission = permissionData['permission'] as Permission;
        permissionStatuses[permission.toString()] = _isPermissionGranted(permission);
      }
      await authService.updatePermissionsStatus(permissionStatuses);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/host_onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRequiredGranted = _areAllRequiredPermissionsGranted();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Permissions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Grant Permissions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please grant the following permissions to use all features of ParkDady Host',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Permissions checklist
              Expanded(
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permissionData = _permissions[index];
                    final permission = permissionData['permission'] as Permission;
                    final isGranted = _isPermissionGranted(permission);
                    final isRequired = permissionData['isRequired'] as bool;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isGranted
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with checkbox and icon
                          Row(
                            children: [
                              // Checkbox
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isGranted ? Colors.green : Colors.grey.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  isGranted ? Icons.check : Icons.circle,
                                  size: 16,
                                  color: isGranted ? Colors.white : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (permissionData['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  permissionData['icon'] as IconData,
                                  color: permissionData['color'] as Color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Title
                              Expanded(
                                child: Text(
                                  permissionData['title'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              // Required badge
                              if (isRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Required',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Description
                          Text(
                            permissionData['description'] as String,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Status and action button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Status
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isGranted
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isGranted ? Icons.check_circle : Icons.info_outline,
                                      size: 16,
                                      color: isGranted ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isGranted ? 'Granted' : 'Not Granted',
                                      style: TextStyle(
                                        color: isGranted ? Colors.green : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action button
                              if (!isGranted)
                                TextButton(
                                  onPressed: _isLoading ? null : () => _requestPermission(permission),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    backgroundColor: (permissionData['color'] as Color).withValues(alpha: 0.1),
                                    foregroundColor: permissionData['color'] as Color,
                                  ),
                                  child: const Text('Grant'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (allRequiredGranted && !_isLoading) ? _completeOnboarding : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: allRequiredGranted ? const Color(0xFF6366F1) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue to Profile Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              if (!allRequiredGranted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please grant all required permissions to continue',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
}
