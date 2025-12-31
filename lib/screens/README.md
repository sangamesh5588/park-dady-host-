# Screens Architecture

This directory contains all screen widgets for the ParkDady Host app, organized by feature for better maintainability and scalability.

## 📁 Folder Structure

```
lib/screens/
├── README.md                          # This documentation
├── main_navigation_screen.dart        # Main bottom navigation
├── splash_screen.dart                 # App splash screen
├── login_screen.dart                  # User authentication
├── signup_screen.dart                 # User registration
├── onboarding_screen.dart             # First-time user setup
├── home/                              # Home/Dashboard screens
│   ├── __init__.dart                  # Home screens exports
│   └── home_screen.dart               # Main dashboard
├── booking/                           # Booking management screens
│   ├── __init__.dart                  # Booking screens exports
│   ├── bookings_screen.dart           # Find & book parking
│   └── booking_history_screen.dart    # Manage bookings history
└── profile/                           # User profile screens
    ├── __init__.dart                  # Profile screens exports
    ├── profile_screen.dart            # Main profile screen
    ├── edit_profile_screen.dart       # Edit user profile
    ├── parking_slots_screen.dart      # Host parking slots
    ├── transactions_screen.dart       # Payment history
    ├── earnings_screen.dart           # Host earnings
    ├── support_screen.dart            # Help & support
    ├── rules_tips_screen.dart         # Parking rules
    └── report_issue_screen.dart       # Issue reporting
```

## 🎯 Organization Principles

### **Feature-Based Grouping**
- **home/**: Dashboard and overview functionality
- **booking/**: All booking-related screens (find, manage, history)
- **profile/**: User profile and account management

### **Clean Imports**
- Each folder has an `__init__.dart` file for clean imports
- Main navigation uses: `import 'feature/__init__.dart';`

### **Scalability**
- New features can be added as new folders
- Related screens stay together
- Easy to maintain and navigate

## 🔧 Usage Examples

### **Importing Screens**
```dart
// Clean imports using __init__.dart
import 'home/__init__.dart';
import 'booking/__init__.dart';
import 'profile/__init__.dart';

// Direct imports (also valid)
import 'home/home_screen.dart';
import 'booking/booking_history_screen.dart';
```

### **Adding New Features**
1. Create new folder: `lib/screens/new_feature/`
2. Add `__init__.dart` with exports
3. Update main navigation if needed
4. Import using the new folder structure

## 📱 Screen Categories

### **Authentication Flow**
- `splash_screen.dart` - App launch
- `login_screen.dart` - Sign in
- `signup_screen.dart` - Registration
- `onboarding_screen.dart` - Setup

### **Main App Navigation**
- `main_navigation_screen.dart` - Bottom nav (4 tabs)
- `home_screen.dart` - Dashboard
- `bookings_screen.dart` - Find parking
- `booking_history_screen.dart` - Manage bookings
- `profile_screen.dart` - User profile

### **Profile Management**
- User info, settings, history
- Host-specific features (earnings, slots)
- Support and help sections

## 🚀 Benefits

✅ **Better Organization** - Related files grouped together
✅ **Easy Maintenance** - Clear structure for developers
✅ **Scalability** - Simple to add new features
✅ **Clean Imports** - Consistent import patterns
✅ **Team Collaboration** - Intuitive file locations
✅ **Code Reusability** - Modular architecture
