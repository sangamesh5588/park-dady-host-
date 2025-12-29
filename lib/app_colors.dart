import 'package:flutter/material.dart';

class AppColors {
  // Uber-like Color Scheme Generation (White background for both themes)
  static ColorScheme generateDynamicColorScheme(Brightness brightness) {
    // Use light theme colors for both light and dark mode (white background)
    return const ColorScheme.light(
      primary: Color(0xFF000000),     // Black primary
      onPrimary: Color(0xFFFFFFFF),   // White text on primary
      primaryContainer: Color(0xFFE0E0E0), // Light gray container
      onPrimaryContainer: Color(0xFF000000), // Black text on primary container

      secondary: Color(0xFF2196F3),    // Blue secondary (parking sign color)
      onSecondary: Color(0xFFFFFFFF),  // White text on secondary
      secondaryContainer: Color(0xFFE3F2FD), // Light blue container
      onSecondaryContainer: Color(0xFF0D47A1), // Dark text on secondary container

      tertiary: Color(0xFFFFD23F),     // Yellow tertiary (parking spot color)
      onTertiary: Color(0xFF000000),   // Black text on tertiary
      tertiaryContainer: Color(0xFFFFF8D6), // Light yellow container
      onTertiaryContainer: Color(0xFF332D00), // Dark text on tertiary container

      error: Color(0xFFD32F2F),         // Red error
      onError: Color(0xFFFFFFFF),       // White text on error
      errorContainer: Color(0xFFFFCDD2), // Light red error container
      onErrorContainer: Color(0xFFB71C1C), // Dark text on error container

      surface: Color(0xFFFFFFFF),       // Pure white surface
      onSurface: Color(0xFF000000),     // Black text on surface
      onSurfaceVariant: Color(0xFF424242), // Dark gray text on surface variant

      surfaceTint: Color(0xFF2196F3),   // Blue surface tint
      outline: Color(0xFF9E9E9E),       // Medium gray outline
      outlineVariant: Color(0xFFBDBDBD), // Light outline variant
      shadow: Color(0xFF000000),        // Pure black shadow

      inverseSurface: Color(0xFF303030), // Dark inverse surface
      onInverseSurface: Color(0xFFFFFFFF), // White text on inverse surface

      inversePrimary: Color(0xFFCCCCCC), // Light inverted primary

      // Custom extensions for app
      surfaceContainerLowest: Color(0xFFFFFFFF),    // Pure white
      surfaceContainerLow: Color(0xFFF5F5F5),       // Very light gray
      surfaceContainer: Color(0xFFF0F0F0),          // Light surface container
      surfaceContainerHigh: Color(0xFFE0E0E0),      // Light surface container high
      surfaceContainerHighest: Color(0xFFD0D0D0),   // Light surface container highest
    );
  }

  // Legacy colors for backward compatibility
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

// Helper method to get appropriate colors from ColorScheme
  static Color getPrimaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getSecondaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  static Color getButtonPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getButtonPrimaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  static Color getInputBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  static Color getInputText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getInputBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  // Parking-specific color utilities
  static Color getParkingSignColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary; // Blue for parking signs
  }

  static Color getParkingSpotAvailableColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary; // Yellow for available spots
  }

  static Color getParkingSpotOccupiedColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHigh; // Gray for occupied spots
  }

  static Color getParkingSpotSelectedColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary; // Blue for selected spots
  }

  // Uber-like color constants for direct access
  static const Color uberBlack = Color(0xFF000000);
  static const Color uberWhite = Color(0xFFFFFFFF);
  static const Color uberBlue = Color(0xFF2196F3);
  static const Color uberLightBlue = Color(0xFF64B5F6);
  static const Color uberOrange = Color(0xFF2196F3);  // Changed to blue
  static const Color uberLightOrange = Color(0xFF64B5F6);  // Changed to light blue
  static const Color uberYellow = Color(0xFFFFD23F);
  static const Color uberBrightYellow = Color(0xFFFFE135);

  // Get appropriate Uber color based on theme
  static Color getUberPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? uberWhite : uberBlack;
  }

  static Color getUberSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? uberLightOrange : uberOrange;
  }

  static Color getUberTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? uberBrightYellow : uberYellow;
  }
}
