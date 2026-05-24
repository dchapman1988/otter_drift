# Deployment Guide

This guide provides step-by-step instructions for deploying Otter Drift to the Google Play Store and configuring advertisements.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AdMob Configuration](#admob-configuration)
3. [Android App Configuration](#android-app-configuration)
4. [Building for Release](#building-for-release)
5. [Play Store Submission](#play-store-submission)
6. [Post-Launch](#post-launch)

## Prerequisites

### Required Accounts

1. **Google Play Developer Account**
   - Sign up at [Google Play Console](https://play.google.com/console/)
   - Pay the one-time $25 registration fee
   - Complete your developer profile

2. **Google AdMob Account**
   - Sign up at [AdMob](https://apps.admob.com/)
   - Link your AdMob account to your Google Play account (recommended)

## AdMob Configuration

### Step 1: Create AdMob App

1. Sign in to your [AdMob account](https://apps.admob.com/)
2. Click **Apps** → **Add app**
3. Select **Android** platform
4. Enter app name: "Otter Drift"
5. Select app category: **Games**
6. Copy the **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

### Step 2: Create Ad Units

For each ad type, create an ad unit:

1. Go to your app → **Ad units** → **Add ad unit**
2. Create three ad units:
   - **Banner Ad** (for menu screens)
   - **Interstitial Ad** (for after game sessions)
   - **Rewarded Video Ad** (for extra lives)
3. Copy each **Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)

### Step 3: Update Application Configuration

#### Update Ad Unit IDs

1. Open `lib/services/ad_config.dart`
2. Replace the test ad unit IDs with your actual AdMob IDs:

```dart
class AdConfig {
  static const String bannerAdUnitId = 'ca-app-pub-YOUR-BANNER-ID';
  static const String interstitialAdUnitId = 'ca-app-pub-YOUR-INTERSTITIAL-ID';
  static const String rewardedAdUnitId = 'ca-app-pub-YOUR-REWARDED-ID';
  static const String appId = 'ca-app-pub-YOUR-APP-ID~XXXXXXXXXX';
}
```

#### Update AndroidManifest.xml

1. Open `android/app/src/main/AndroidManifest.xml`
2. Update the AdMob App ID in the meta-data tag:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR-APP-ID~XXXXXXXXXX"/>
```

## Android App Configuration

### Step 1: Update Application ID

1. Open `android/app/build.gradle.kts`
2. Replace the application ID with your unique package name:

```kotlin
applicationId = "com.yourcompany.otterdrift"  // Replace with your package name
```

**Important:** The application ID must be unique and cannot be changed after publishing.

### Step 2: Set Up App Signing

#### Create Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Enter a password (save this securely!)
- Fill in the certificate information
- Save the keystore file in a secure location

#### Create key.properties

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

#### Update build.gradle.kts

Add keystore configuration to `android/app/build.gradle.kts`:

```kotlin
// Add at the top of the file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Update buildTypes.release
buildTypes {
    release {
        signingConfig = signingConfigs.create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
        isMinifyEnabled = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

### Step 3: Update App Version

1. Open `pubspec.yaml`
2. Update the version number:

```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

- Increment `buildNumber` (the number after `+`) for each release
- Increment `major.minor.patch` for significant updates

## Building for Release

### Build App Bundle

```bash
flutter build appbundle --release
```

The `.aab` file will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Play Store Submission

### Step 1: Prepare Store Listing Assets

Required assets:

- **App Icon**: 512x512 PNG (no transparency)
- **Feature Graphic**: 1024x500 PNG
- **Screenshots**: 
  - Phone: At least 2, up to 8 (16:9 or 9:16)
  - Tablet (if supported): At least 2, up to 8
- **Short Description**: 80 characters max
- **Full Description**: 4000 characters max

### Step 2: Complete Store Listing

1. Go to [Play Console](https://play.google.com/console/)
2. Click **Create app**
3. Fill in app details:
   - App name: "Otter Drift"
   - Default language
   - App or game: **Game**
   - Free or paid: **Free**
   - Declarations: Check all applicable boxes

4. Complete the store listing:
   - Upload all required assets
   - Write descriptions
   - Add screenshots
   - Set up categories

### Step 3: Content Rating

1. Complete the content rating questionnaire in Play Console
2. Get your rating (typically "Everyone" for a game like Otter Drift)

### Step 4: Privacy Policy

You must provide a privacy policy URL that covers:

- Data collection (AdMob collects device IDs, location, etc.)
- Third-party services (AdMob, analytics)
- User rights

Create a privacy policy and host it online, then add the URL in Play Console.

### Step 5: Upload App Bundle

1. Go to **Production** → **Create new release**
2. Upload `app-release.aab`
3. Add release notes
4. Review and roll out

## Post-Launch

### Monitor Performance

1. **AdMob Dashboard**
   - Track revenue and eCPM (effective cost per mille)
   - Monitor ad performance metrics
   - Review fill rates

2. **Play Console**
   - Monitor app ratings and reviews
   - Track installs and user retention
   - Review crash reports

### Optimization

- A/B test different ad placements
- Optimize ad frequency based on user feedback
- Monitor user retention after ad implementation
- Adjust ad timing to minimize disruption

## Troubleshooting

### Ads Not Showing

1. Verify ad unit IDs are correct in `ad_config.dart`
2. Check AdMob App ID in `AndroidManifest.xml`
3. Ensure device is not in test mode (for production ads)
4. Review AdMob dashboard for policy violations
5. Check network connectivity

### Build Errors

1. Ensure all dependencies are up to date: `flutter pub get`
2. Clean build: `flutter clean && flutter build appbundle --release`
3. Check ProGuard rules if using minification
4. Verify keystore configuration

## Additional Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [AdMob Documentation](https://developers.google.com/admob)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Google Play Policy](https://play.google.com/about/developer-content-policy/)

## Summary Checklist

Before deployment, ensure you have:

- [ ] AdMob App ID
- [ ] Banner Ad Unit ID
- [ ] Interstitial Ad Unit ID
- [ ] Rewarded Video Ad Unit ID
- [ ] Updated `ad_config.dart` with production IDs
- [ ] Updated `AndroidManifest.xml` with App ID
- [ ] Unique application ID configured
- [ ] App signing keystore created
- [ ] Version number updated
- [ ] App bundle built successfully
- [ ] Store listing assets prepared
- [ ] Privacy policy URL ready



