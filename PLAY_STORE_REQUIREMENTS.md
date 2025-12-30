# Play Store Publishing Requirements - Parking Host App

## Overview
This document outlines all requirements and tasks needed to publish the Parking Host app on Google Play Store.

---

## 1. APP CONFIGURATION & METADATA

### 1.1 App Identity
- [ ] **App Name**: Choose final app name (currently "Parking Host")
  - Check availability on Play Store
  - Consider trademark conflicts
  - Maximum 50 characters

- [ ] **Package Name**: Verify unique package identifier
  - Current: `com.example.praking_host` (⚠️ MUST CHANGE - remove "example")
  - Recommended: `com.yourcompany.parkinghost`
  - Cannot be changed after first publish

- [ ] **App Version**
  - Version name: e.g., "1.0.0"
  - Version code: 1 (increment for each release)
  - Update in `pubspec.yaml`

### 1.2 App Description & Store Listing
- [ ] **Short Description** (80 characters max)
  - Example: "Manage your parking business with ease. Host parking spots and earn money."

- [ ] **Full Description** (4000 characters max)
  - Explain app features
  - Target audience (parking space hosts)
  - Key benefits
  - How it works
  - Support contact info

- [ ] **App Category**
  - Primary: Business or Productivity
  - Secondary: (optional)

- [ ] **Tags/Keywords**
  - parking, host, business, rental, parking management, etc.

### 1.3 Graphics & Visual Assets

#### App Icons
- [ ] **Adaptive Icon** (required)
  - Foreground: 108x108 dp (432x432 px at xxxhdpi)
  - Background: 108x108 dp (432x432 px at xxxhdpi)
  - Safe zone: 66x66 dp from center
  - ⚠️ Currently using default Flutter icon - MUST UPDATE

- [ ] **Legacy Icon** (512x512 px PNG)
  - For older Android versions
  - Must be uploaded to Play Console

#### Screenshots (REQUIRED - minimum 2, maximum 8 per device type)
- [ ] **Phone Screenshots** (minimum 2 required)
  - Recommended: 1080 x 1920 px or 1080 x 2340 px
  - JPEG or PNG (24-bit)
  - Max file size: 8MB each
  - Suggested screens to capture:
    1. Home screen with active bookings
    2. QR scanner in action
    3. Booking details/completion
    4. Earnings dashboard
    5. Profile/settings screen
    6. Parking slots management

- [ ] **Tablet Screenshots** (optional but recommended)
  - 7-inch: 1080 x 1920 px
  - 10-inch: 1920 x 1200 px

#### Feature Graphic
- [ ] **Feature Graphic** (required)
  - Size: 1024 x 500 px
  - JPEG or PNG (24-bit)
  - Used in Play Store listing header
  - Should include app name and key visual

#### Promotional Graphics (Optional)
- [ ] **Promo Video** (optional)
  - YouTube video URL
  - 30 seconds to 2 minutes recommended
  - Showcasing key features

- [ ] **TV Banner** (if supporting Android TV)
  - 1280 x 720 px

---

## 2. LEGAL & COMPLIANCE

### 2.1 Privacy Policy (REQUIRED)
- [ ] **Create Privacy Policy**
  - Must be hosted on publicly accessible URL
  - Required by Play Store
  - Must cover:
    - What data is collected
    - How data is used
    - Data storage and security
    - Third-party services (Supabase, location services)
    - User rights (access, deletion)
    - Contact information

- [ ] **Add Privacy Policy URL to Play Console**

- [ ] **Add Privacy Policy link in app**
  - ✅ Already implemented in ProfileScreen
  - Screen exists: `privacy_policy_screen.dart`
  - ⚠️ Need to populate with actual policy content

### 2.2 Terms of Service
- [ ] **Create Terms of Service**
  - User responsibilities
  - Service description
  - Liability limitations
  - Dispute resolution

- [ ] **Add Terms link in app**
  - ✅ Already implemented in ProfileScreen
  - Screen exists: `terms_of_service_screen.dart`
  - ⚠️ Need to populate with actual terms content

### 2.3 Data Safety Section (REQUIRED)
- [ ] **Complete Data Safety Form in Play Console**
  - Data collection practices
  - Data sharing with third parties
  - Security practices
  - Data deletion capability

### 2.4 Content Rating Questionnaire
- [ ] **Complete IARC Content Rating**
  - Answer questions about app content
  - Violence, sexual content, language, etc.
  - Get rating for all regions

### 2.5 Target Audience & Content
- [ ] **Declare target age group**
- [ ] **Ads declaration** (contains ads: yes/no)
- [ ] **In-app purchases** (if applicable)

---

## 3. TECHNICAL REQUIREMENTS

### 3.1 App Permissions
- [ ] **Review and justify all permissions**
  - ✅ Camera (for QR scanner)
  - ✅ Location (for parking location services)
  - ⚠️ Add permission rationale dialogs
  - ⚠️ Remove any unused permissions from AndroidManifest.xml

- [ ] **Add runtime permission handling**
  - Proper permission request flow
  - Graceful handling of denials

### 3.2 Android API Levels
- [ ] **Set minimum SDK version**
  - Check `android/app/build.gradle`
  - Recommended: API 21 (Android 5.0) minimum
  - Target latest stable API (API 34 for 2024)

- [ ] **Target SDK version**
  - Must target recent API level
  - Google requires targeting API 33+ (as of 2024)

### 3.3 App Bundle
- [ ] **Build App Bundle (.aab)**
  - Use `flutter build appbundle --release`
  - Google Play requires .aab format (not .apk)
  - Enables Dynamic Delivery

- [ ] **Enable ProGuard/R8** (code shrinking)
  - For smaller app size
  - Configure in `android/app/build.gradle`

### 3.4 Signing Configuration
- [ ] **Create release keystore**
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
    -keysize 2048 -validity 10000 -alias upload
  ```

- [ ] **Configure signing in build.gradle**
  - Store keystore safely
  - Never commit keystore to git
  - Document keystore password securely

- [ ] **Create key.properties file**
  - Add to `.gitignore`
  - Contains keystore credentials

### 3.5 App Performance
- [ ] **Test app performance**
  - App startup time < 5 seconds
  - Smooth scrolling (60fps)
  - No ANR (Application Not Responding) errors
  - No crashes

- [ ] **Optimize app size**
  - Remove unused resources
  - Compress images
  - Use app bundles for size optimization

### 3.6 Testing
- [ ] **Test on multiple devices**
  - Different screen sizes
  - Different Android versions
  - Phone and tablet

- [ ] **Test all features**
  - QR scanning
  - Booking flow (check-in, check-out, overtime)
  - Location services
  - Database operations
  - Profile editing
  - Payment/earnings display

- [ ] **Test offline scenarios**
  - No internet connection
  - Poor connection
  - Proper error messages

- [ ] **Test edge cases**
  - Empty states
  - Long text handling
  - Invalid inputs
  - Permission denials

### 3.7 Security
- [ ] **Secure API keys and secrets**
  - ⚠️ Move Supabase keys to environment variables
  - Use `flutter_dotenv` or similar
  - Never hardcode sensitive data

- [ ] **Enable network security**
  - HTTPS only
  - Certificate pinning (optional but recommended)

- [ ] **Code obfuscation**
  - Enable in release build
  - `--obfuscate --split-debug-info=/<directory>`

---

## 4. FUNCTIONAL COMPLETENESS

### 4.1 Core Features Checklist
- [ ] **Authentication**
  - ✅ Login/Signup
  - ✅ Password reset
  - [ ] Email verification (if required)
  - [ ] Social login (Google/Apple) - verify working

- [ ] **Home Screen**
  - ✅ Active bookings display
  - ✅ Stats (orders, earnings)
  - ✅ Empty states
  - ✅ Profile header with location

- [ ] **QR Scanner**
  - ✅ Check-in functionality
  - ✅ Listing price storage
  - ✅ Error handling
  - [ ] Test with various QR code formats

- [ ] **Booking Management**
  - ✅ Check-out functionality
  - ✅ Overtime calculation
  - ✅ Booking history
  - ✅ Booking details
  - [ ] Verify all edge cases

- [ ] **Profile & Settings**
  - ✅ Edit profile
  - ✅ View earnings
  - ✅ Transaction history
  - ✅ Support/Help
  - ✅ Legal pages (Privacy, Terms, etc.)
  - [ ] Account deletion functionality

- [ ] **Parking Slots Management**
  - ✅ View parking slots
  - ✅ Add/edit slots
  - [ ] Verify slot availability logic

### 4.2 Missing/Incomplete Features
- [ ] **Data Deletion Implementation**
  - Screen exists but marked "Coming soon"
  - Must implement actual deletion flow
  - Required by Play Store policies

- [ ] **Photo Upload**
  - Profile photo change marked "Coming soon"
  - Implement camera/gallery integration
  - Or remove the option

- [ ] **Account Deletion**
  - Currently shows "Coming soon"
  - Must implement actual deletion
  - Required by Play Store policies

- [ ] **Push Notifications** (if needed)
  - Booking updates
  - Payment confirmations
  - System announcements

- [ ] **Payment Integration** (if needed)
  - Payment gateway setup
  - Test transactions
  - Refund handling

---

## 5. BACKEND & INFRASTRUCTURE

### 5.1 Supabase Configuration
- [ ] **Production Supabase project**
  - Separate from development
  - Proper security rules
  - Database indexes for performance

- [ ] **Database Schema Verification**
  - All tables created
  - Proper relationships
  - Migrations applied

- [ ] **Row Level Security (RLS)**
  - Enable RLS on all tables
  - Verify policies are correct
  - Test with different user roles

- [ ] **API Rate Limiting**
  - Prevent abuse
  - Configure in Supabase dashboard

- [ ] **Backup Strategy**
  - Regular database backups
  - Disaster recovery plan

### 5.2 Environment Configuration
- [ ] **Separate environments**
  - Development
  - Staging/Testing
  - Production

- [ ] **Environment variables**
  - Supabase URL and keys
  - API endpoints
  - Feature flags

---

## 6. MONETIZATION (If Applicable)

- [ ] **AdMob Integration** (if using ads)
  - AdMob account setup
  - Ad unit IDs configured
  - Test ads working
  - Comply with ad policies

- [ ] **In-App Purchases** (if applicable)
  - Google Play Billing setup
  - Products configured
  - Test purchases

- [ ] **Subscription Model** (if applicable)
  - Subscription tiers defined
  - Billing integration
  - Subscription management UI

---

## 7. SUPPORT & MAINTENANCE

### 7.1 Support Infrastructure
- [ ] **Support Email**
  - Create dedicated support email
  - Add to Play Store listing
  - Add to app (in Support screen)

- [ ] **Website** (optional but recommended)
  - Landing page
  - Privacy policy hosting
  - Terms of service hosting
  - Support/contact page

- [ ] **Bug Reporting System**
  - ✅ Report Issue screen exists
  - [ ] Integrate with ticketing system
  - [ ] Or setup email forwarding

### 7.2 Analytics
- [ ] **Firebase Analytics** (recommended)
  - Track user behavior
  - Monitor crashes
  - Understand usage patterns

- [ ] **Crashlytics**
  - Track and fix crashes
  - Monitor app stability

---

## 8. PLAY CONSOLE SETUP

### 8.1 Developer Account
- [ ] **Google Play Developer account**
  - One-time $25 registration fee
  - Verified payment method

### 8.2 App Creation
- [ ] **Create new app in Play Console**
- [ ] **Set up store listing**
  - App name, description
  - Screenshots, graphics
  - Categorization

### 8.3 Release Tracks
- [ ] **Internal Testing** (recommended first step)
  - Limited testers
  - Quick iteration
  - No review required

- [ ] **Closed Testing** (Alpha/Beta)
  - Larger test group
  - Pre-launch testing
  - Feedback collection

- [ ] **Open Testing** (optional)
  - Public beta
  - Anyone can join

- [ ] **Production Release**
  - Final release to all users
  - Requires full review

### 8.4 Pre-Launch Report
- [ ] **Review automated testing results**
  - Google runs automated tests
  - Fix any critical issues found
  - Check compatibility issues

---

## 9. FINAL CHECKS BEFORE RELEASE

### 9.1 Code Review
- [ ] **Remove all debug code**
  - Console logs
  - Test credentials
  - Debug flags

- [ ] **Remove TODO comments** (or address them)

- [ ] **Code quality**
  - No compiler warnings
  - Proper error handling
  - Clean code standards

### 9.2 Build Configuration
- [ ] **Release build configuration**
  - `flutter build appbundle --release`
  - Verify no debug dependencies
  - Test release build thoroughly

- [ ] **Version numbers**
  - Update version in pubspec.yaml
  - Update version in build.gradle
  - Maintain changelog

### 9.3 Testing Release Build
- [ ] **Install release build on test devices**
- [ ] **Test all critical flows**
- [ ] **Verify no crashes**
- [ ] **Check performance**

### 9.4 Legal Compliance
- [ ] **GDPR Compliance** (if targeting EU)
- [ ] **COPPA Compliance** (if targeting children)
- [ ] **Region-specific requirements**

---

## 10. POST-LAUNCH

### 10.1 Monitoring
- [ ] **Monitor crash reports**
- [ ] **Monitor user reviews**
- [ ] **Monitor analytics**
- [ ] **Monitor performance metrics**

### 10.2 Updates
- [ ] **Plan update schedule**
- [ ] **Bug fix releases**
- [ ] **Feature updates**
- [ ] **Security patches**

### 10.3 User Feedback
- [ ] **Respond to reviews**
- [ ] **Address user complaints**
- [ ] **Implement feature requests**

---

## Priority Levels

### 🔴 CRITICAL (Must fix before launch)
1. Change package name from `com.example.*`
2. Create and upload app icon
3. Take and upload screenshots (minimum 2)
4. Create Privacy Policy and host it
5. Complete Data Safety questionnaire
6. Setup signing configuration
7. Implement account/data deletion
8. Remove/implement "Coming soon" features
9. Secure Supabase keys (environment variables)
10. Test on multiple devices

### 🟡 HIGH PRIORITY (Should fix before launch)
1. Complete Terms of Service
2. Setup support email
3. Implement analytics
4. Test all features thoroughly
5. Optimize app size and performance
6. Add permission rationale dialogs
7. Test offline scenarios
8. Complete content rating questionnaire

### 🟢 MEDIUM PRIORITY (Nice to have)
1. Create promotional video
2. Setup website
3. Implement push notifications (if needed)
4. Add tablet screenshots
5. Internal testing with real users
6. Beta testing phase

### 🔵 LOW PRIORITY (Can do after launch)
1. Feature graphic variations
2. Localization to other languages
3. TV banner (if supporting Android TV)
4. Advanced analytics

---

## Estimated Timeline

- **Immediate fixes (Critical)**: 2-3 days
- **High priority items**: 3-5 days
- **Testing phase**: 3-5 days
- **Play Console setup & submission**: 1-2 days
- **Google review process**: 1-7 days (typically 3 days)

**Total estimated time to launch**: 2-3 weeks

---

## Notes

- Keep all keystore files and passwords in a secure location (password manager)
- Document all credentials and configurations
- Create a rollback plan in case of critical issues
- Have a support plan ready for launch day
- Monitor the app closely for the first 48 hours after launch

---

## Support Contacts

- **Play Console Help**: https://support.google.com/googleplay/android-developer
- **Flutter Documentation**: https://docs.flutter.dev/deployment/android
- **Supabase Support**: https://supabase.com/docs

