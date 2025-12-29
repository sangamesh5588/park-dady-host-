# Google Maps Setup Guide for Parking Host App

This guide will help you configure Google Maps for the location picker feature in the host onboarding form.

## 🚀 Quick Setup

### Step 1: Get Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** (if you plan to build for iOS)
   - **Geocoding API** (optional, for address lookup)
4. Create credentials (API Key)
5. Restrict the API key to your app:
   - **Android**: Add package name `com.example.praking_host`
   - **iOS**: Add bundle ID `com.example.praking_host`

### Step 2: Configure API Key in Your App

Update your `.env` file with your API key:
```env
# Replace with your actual Google Maps API key
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

### Step 3: Optional - Add Custom Map Styling

If you want custom map styling:
1. Go to [Google Maps Platform](https://mapsplatform.google.com/)
2. Create a new Map ID in the "Map Management" section
3. Choose your styling options
4. Add the Map ID to your `.env` file:
```env
# Optional: Google Maps Map ID for custom styling
GOOGLE_MAPS_MAP_ID=your_actual_map_id_here
```

## 🛠️ Troubleshooting

### App Crashes on "Select on Map"
- **Cause**: Missing or invalid API key
- **Solution**: Ensure `GOOGLE_MAPS_API_KEY` in `.env` is correct

### Map Shows Blank/Gray Screen
- **Cause**: API key restrictions or billing issues
- **Solution**: Check API key restrictions and enable billing if required

### Location Permissions Not Working
- **Cause**: Missing location permissions in AndroidManifest.xml
- **Solution**: Ensure these permissions are present:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## 📋 Required Permissions

Your `android/app/src/main/AndroidManifest.xml` should include:

```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />

<!-- Google Play Services Version -->
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />
```

## 🔄 Testing the Setup

1. Run your app on a physical Android device (Google Maps doesn't work well on emulators)
2. Go through the host onboarding flow
3. Tap "Select on Map" in the location selection step
4. Verify the map loads and you can select locations

## 💡 Additional Configuration

### For iOS (if needed later):
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to help you select parking locations.</string>

<key>io.flutter.embedded_views_preview</key>
<true/>
```

### For Production:
- Enable billing on your Google Cloud project
- Set up proper API key restrictions
- Monitor API usage in Google Cloud Console

## ❓ Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Google Maps API key is invalid" | Check API key in `.env` and ensure it's not restricted incorrectly |
| Map loads but is blank | Enable Maps SDK for Android in Google Cloud Console |
| Location permissions denied | Check AndroidManifest.xml permissions |
| Build fails | Ensure `google_maps_flutter: ^2.6.1` is in pubspec.yaml |

## 📞 Support

If you continue having issues:
1. Check the [Google Maps Flutter documentation](https://pub.dev/packages/google_maps_flutter)
2. Verify your API key in Google Cloud Console
3. Ensure all required APIs are enabled
4. Test on a physical device rather than emulator

---

**Note**: Google Maps requires billing to be enabled for production use. You get a generous free tier, but monitor your usage.
