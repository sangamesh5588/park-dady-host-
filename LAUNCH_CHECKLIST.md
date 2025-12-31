# 🚀 Play Store Launch Checklist

Quick reference checklist for launching ParkDady Host app on Google Play Store.

**Last Updated**: 2025-12-30
**Target Launch Date**: _____________

---

## 🔴 CRITICAL - Must Complete Before Launch

### App Configuration
- [ ] Change package name from `com.example.praking_host` to production name
  - File: `android/app/build.gradle`
  - Recommended: `com.yourcompany.parkinghost`
- [ ] Update app version in `pubspec.yaml` to `1.0.0`
- [ ] Create release keystore file
- [ ] Configure signing in `android/app/build.gradle`
- [ ] Add `key.properties` to `.gitignore`

### App Assets (REQUIRED by Play Store)
- [ ] Design and create app icon (512x512 px)
- [ ] Create adaptive icon (foreground + background)
- [ ] Take minimum 2 phone screenshots (1080x1920 px)
  - [ ] Screenshot 1: Home screen with bookings
  - [ ] Screenshot 2: QR scanner or booking details
- [ ] Create feature graphic (1024x500 px)

### Privacy & Legal (REQUIRED by Play Store)
- [ ] Write Privacy Policy document
- [ ] Host Privacy Policy on public URL
- [ ] Update Privacy Policy screen with actual content
  - File: `lib/screens/profile/privacy_policy_screen.dart`
- [ ] Write Terms of Service
- [ ] Update Terms of Service screen with actual content
  - File: `lib/screens/profile/terms_of_service_screen.dart`
- [ ] Complete Data Safety form in Play Console

### Critical Features
- [ ] Implement account deletion functionality
  - Currently shows "Coming soon" in ProfileScreen
  - Required by Play Store policies
- [ ] Implement data deletion request functionality
  - File: `lib/screens/profile/data_deletion_screen.dart`
- [ ] Handle profile photo upload OR remove the feature
  - Currently marked "Coming soon"

### Security
- [ ] Move Supabase keys to environment variables
  - Use `flutter_dotenv` or `--dart-define`
  - Never hardcode credentials
- [ ] Review and remove any debug/test credentials
- [ ] Enable ProGuard/R8 code shrinking

### Testing
- [ ] Test on at least 3 different Android devices
- [ ] Test all booking flows (check-in, check-out, overtime)
- [ ] Test QR scanner functionality
- [ ] Test with no internet connection
- [ ] Test profile editing and settings
- [ ] Run release build and verify no crashes

---

## 🟡 HIGH PRIORITY - Strongly Recommended

### Play Console Setup
- [ ] Create Google Play Developer account ($25 one-time fee)
- [ ] Create new app in Play Console
- [ ] Complete app store listing
  - [ ] App name
  - [ ] Short description (80 chars)
  - [ ] Full description (up to 4000 chars)
  - [ ] App category: Business/Productivity
- [ ] Complete content rating questionnaire

### Support Infrastructure
- [ ] Create support email address
- [ ] Add support email to Play Store listing
- [ ] Update Support screen with real contact info
  - File: `lib/screens/profile/support_screen.dart`

### Technical
- [ ] Set target SDK to API 34+ (required by Google)
- [ ] Set minimum SDK to API 21+ (recommended)
  - File: `android/app/build.gradle`
- [ ] Add permission rationale dialogs
  - Camera permission (for QR scanning)
  - Location permission (for parking location)
- [ ] Test release build thoroughly
  ```bash
  flutter build appbundle --release
  ```

### Backend
- [ ] Setup production Supabase project (separate from dev)
- [ ] Enable Row Level Security (RLS) on all tables
- [ ] Verify database indexes for performance
- [ ] Test with production database

### Analytics & Monitoring
- [ ] Setup Firebase Analytics
- [ ] Setup Firebase Crashlytics
- [ ] Test analytics events

---

## 🟢 MEDIUM PRIORITY - Nice to Have

### Additional Assets
- [ ] Create 4-8 screenshots showcasing all features
- [ ] Create promotional video (30-120 seconds)
- [ ] Create tablet screenshots (optional)

### Testing
- [ ] Internal testing track (5-10 testers)
- [ ] Closed beta testing (50+ testers)
- [ ] Collect and address beta feedback

### Features
- [ ] Implement push notifications (optional)
- [ ] Setup payment integration (if needed)
- [ ] Add app rate/review prompt

### Marketing
- [ ] Create app website/landing page
- [ ] Prepare social media announcements
- [ ] Create promotional materials

---

## 🔵 LOW PRIORITY - After Launch

- [ ] Monitor crash reports daily
- [ ] Respond to user reviews
- [ ] Plan feature updates
- [ ] Add localization for other languages
- [ ] Optimize based on analytics data

---

## 📋 Pre-Submission Checklist

**Day Before Submission:**
- [ ] All critical items completed ✓
- [ ] Release build tested on multiple devices
- [ ] All screenshots uploaded to Play Console
- [ ] Privacy policy and terms URLs added
- [ ] Data safety form completed
- [ ] Content rating completed
- [ ] App description reviewed (no spelling errors)
- [ ] Support email verified working
- [ ] All "Coming soon" features implemented or removed

**Submission Day:**
- [ ] Build final release app bundle
  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
  ```
- [ ] Upload .aab file to Play Console
- [ ] Submit for review
- [ ] Save keystore and passwords securely
- [ ] Document all credentials

**Post-Submission:**
- [ ] Monitor Play Console for review status
- [ ] Prepare for launch day support
- [ ] Monitor crashes and reviews

---

## ⚠️ Common Rejection Reasons

Avoid these to speed up approval:
1. ❌ Missing privacy policy
2. ❌ Privacy policy not accessible
3. ❌ Missing data deletion functionality
4. ❌ Dangerous permissions not justified
5. ❌ App crashes on startup
6. ❌ Incomplete store listing
7. ❌ Low quality screenshots
8. ❌ Using "test" or "example" package names
9. ❌ Hardcoded API keys visible
10. ❌ Missing content rating

---

## 📞 Quick Reference

### Important Files to Update
```
android/app/build.gradle          - Package name, versions, signing
pubspec.yaml                      - App version
AndroidManifest.xml               - Permissions, app name
lib/screens/profile/*_screen.dart - Privacy, Terms, Support, Deletion
.gitignore                        - Add key.properties, .env files
```

### Build Commands
```bash
# Debug build
flutter build apk --debug

# Release build (for testing)
flutter build apk --release

# Final production build
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# Check app size
flutter build appbundle --release --analyze-size
```

### Key URLs
- Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com
- Supabase Dashboard: https://app.supabase.com

---

## 🎯 Current Status

**Completion Progress**: 0/30 critical items

**Blockers**:
- Package name needs changing
- App icon needed
- Screenshots needed
- Privacy policy needed
- Account deletion not implemented

**Next Steps**:
1. Change package name
2. Create app icon and screenshots
3. Write privacy policy and terms
4. Implement account/data deletion
5. Test release build

---

**Good luck with your launch! 🚀**
