import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Critical permissions required for basic app functionality
  static const List<Permission> _criticalPermissions = [
    Permission.location,
  ];

  // Optional permissions for enhanced features
  static const List<Permission> _optionalPermissions = [
    Permission.camera,
    Permission.photos,
    Permission.notification,
  ];

  // Check if all critical permissions are granted
  Future<bool> hasAllCriticalPermissions() async {
    for (final permission in _criticalPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  // Check if a specific permission is granted
  Future<bool> hasPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // Request critical permissions (blocking for app entry)
  Future<Map<Permission, PermissionStatus>> requestCriticalPermissions() async {
    final Map<Permission, PermissionStatus> results = {};

    for (final permission in _criticalPermissions) {
      final status = await permission.request();
      results[permission] = status;
    }

    return results;
  }

  // Request a specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  // Request optional permissions (non-blocking)
  Future<Map<Permission, PermissionStatus>> requestOptionalPermissions() async {
    final Map<Permission, PermissionStatus> results = {};

    for (final permission in _optionalPermissions) {
      final status = await permission.request();
      results[permission] = status;
    }

    return results;
  }

  // Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  // Get user-friendly permission name
  String getPermissionName(Permission permission) {
    if (permission == Permission.location) return 'Location';
    if (permission == Permission.camera) return 'Camera';
    if (permission == Permission.photos) return 'Photos';
    if (permission == Permission.notification) return 'Notifications';
    return 'This permission';
  }

  // Get permission description
  String getPermissionDescription(Permission permission) {
    if (permission == Permission.location) {
      return 'Location access is required to show nearby parking spaces and help drivers find your parking spots on the map.';
    }
    if (permission == Permission.camera) {
      return 'Camera access allows you to take photos of your parking spaces to attract more customers.';
    }
    if (permission == Permission.photos) {
      return 'Photo library access allows you to upload existing photos of your parking spaces from your gallery.';
    }
    if (permission == Permission.notification) {
      return 'Notifications allow you to receive instant alerts about new bookings, messages, and payments.';
    }
    return 'This permission is needed for the app to function properly.';
  }

  // Show permission dialog
  Future<bool> showPermissionDialog(
    BuildContext context,
    Permission permission, {
    bool isCritical = false,
  }) async {
    final permissionName = getPermissionName(permission);
    final description = getPermissionDescription(permission);
    final isPermanentlyDenied = await this.isPermissionPermanentlyDenied(permission);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isCritical,
      builder: (context) => AlertDialog(
        title: Text('${permissionName} Permission Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Text(
              isCritical
                  ? 'This permission is required to use the app.'
                  : 'This permission enhances your experience but is not required.',
              style: TextStyle(
                color: isCritical ? Colors.red : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (!isCritical)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
          TextButton(
            onPressed: () async {
              final status = await requestPermission(permission);
              Navigator.of(context).pop(status.isGranted);
            },
            child: const Text('Grant Permission'),
          ),
          if (isPermanentlyDenied)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );

    return result ?? false;
  }

  // Check and request permission with dialog
  Future<bool> checkAndRequestPermission(
    BuildContext context,
    Permission permission, {
    bool isCritical = false,
  }) async {
    final hasPermission = await this.hasPermission(permission);

    if (hasPermission) {
      return true;
    }

    return await showPermissionDialog(context, permission, isCritical: isCritical);
  }

  // Validate app entry permissions
  Future<bool> validateAppEntryPermissions(BuildContext context) async {
    final hasCritical = await hasAllCriticalPermissions();

    if (!hasCritical) {
      // Request permissions directly without showing dialog first
      final results = await requestCriticalPermissions();
      return results.values.every((status) => status.isGranted);
    }

    return true;
  }
}
