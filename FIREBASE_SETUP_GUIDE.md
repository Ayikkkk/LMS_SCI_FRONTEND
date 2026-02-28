# Firebase Crashlytics Setup Guide

## 📋 Overview

Panduan lengkap untuk setup Firebase Crashlytics di aplikasi LMS Frontend Flutter.

---

## ✅ What's Already Done (Code Side)

1. ✅ Dependencies added to `pubspec.yaml`
2. ✅ `CrashlyticsService` created
3. ✅ `main.dart` updated with Firebase initialization
4. ✅ `auth_notifier.dart` updated untuk track user
5. ✅ Error handlers configured

---

## 🔧 What You Need to Do (Firebase Console)

### Step 1: Create Firebase Project

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Click "Add project" atau "Create a project"

2. **Project Setup:**
   - Project name: `lms-frontend` (atau nama lain)
   - Enable Google Analytics: **Yes** (recommended)
   - Choose Analytics account atau create new
   - Click "Create project"

3. **Wait for project creation** (~30 seconds)

---

### Step 2: Add Android App to Firebase

1. **In Firebase Console:**
   - Click "Add app" → Select Android icon

2. **Register App:**
   - **Android package name:** `com.example.lms_frontend`
     (Cek di `android/app/build.gradle.kts` → `applicationId`)
   - **App nickname:** LMS Student (optional)
   - **Debug signing certificate SHA-1:** (optional untuk sekarang)
   - Click "Register app"

3. **Download config file:**
   - Download `google-services.json`
   - **IMPORTANT:** Save file ini, kita akan copy ke project

4. **Click "Next"** (skip SDK setup, sudah kita lakukan)

5. **Click "Continue to console"**

---

### Step 3: Enable Crashlytics

1. **In Firebase Console:**
   - Left sidebar → Click "Crashlytics"
   - Click "Enable Crashlytics"
   - Wait for setup to complete

2. **Crashlytics Dashboard:**
   - You'll see "Waiting for data..."
   - This is normal, data akan muncul setelah app running

---

### Step 4: Copy google-services.json to Project

**IMPORTANT:** File `google-services.json` harus di-copy ke folder yang benar!

```bash
# Copy google-services.json ke folder android/app/
# Struktur harus seperti ini:
android/
  app/
    google-services.json  ← File harus di sini
    build.gradle.kts
    src/
```

**Windows Command:**
```bash
# Ganti path sesuai lokasi download Anda
copy "C:\Users\YourName\Downloads\google-services.json" "android\app\google-services.json"
```

**Verify file location:**
```bash
ls android/app/google-services.json
```

---

### Step 5: Update Android Build Configuration

#### 5.1 Update `android/build.gradle.kts`

Add Google Services plugin:

```kotlin
// android/build.gradle.kts
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // ← ADD THIS
    id("com.google.firebase.crashlytics") version "2.9.9" apply false  // ← ADD THIS
}
```

#### 5.2 Update `android/app/build.gradle.kts`

Add plugins at the top:

```kotlin
// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← ADD THIS
    id("com.google.firebase.crashlytics")  // ← ADD THIS
}
```

---

### Step 6: Update .gitignore

**IMPORTANT:** Jangan commit `google-services.json` ke Git!

Add to `.gitignore`:
```
# Firebase
google-services.json
GoogleService-Info.plist
firebase_options.dart
```

---

## 🧪 Testing Crashlytics

### Test 1: Run App and Check Initialization

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run app
flutter run -d b1135bfc
```

**Check console output:**
```
I/flutter: ✅ [CrashlyticsService] Crashlytics initialized
```

---

### Test 2: Test Crash Reporting (Development Only)

Add test button di development mode:

```dart
// Temporary test code (remove after testing)
if (EnvironmentConfig.isDevelopment) {
  FloatingActionButton(
    onPressed: () {
      // Test non-fatal error
      CrashlyticsService.recordError(
        Exception('Test error'),
        StackTrace.current,
        reason: 'Testing Crashlytics',
      );

      // Test crash (app will crash!)
      // CrashlyticsService.forceCrash();
    },
    child: Icon(Icons.bug_report),
  );
}
```

---

### Test 3: Verify in Firebase Console

1. **Trigger test error** (using button above)
2. **Wait 5-10 minutes** (Crashlytics has delay)
3. **Check Firebase Console:**
   - Go to Crashlytics dashboard
   - You should see test error appear

---

## 📊 What Gets Tracked

### Automatic:
- ✅ All uncaught exceptions
- ✅ Flutter framework errors
- ✅ Async errors
- ✅ Fatal crashes

### Manual (via CrashlyticsService):
- ✅ Non-fatal errors
- ✅ Custom logs
- ✅ User identifiers
- ✅ Custom keys

### User Data Tracked:
- User ID (student ID)
- Student name
- Student NIS
- Environment (dev/staging/prod)
- API URL

---

## 🔍 Troubleshooting

### Issue 1: "google-services.json not found"

**Solution:**
```bash
# Verify file exists
ls android/app/google-services.json

# If not, copy again from Downloads
copy "Downloads\google-services.json" "android\app\"
```

---

### Issue 2: Build failed with "Could not find google-services.json"

**Solution:**
1. Make sure file is in `android/app/` (NOT `android/`)
2. File name must be exactly `google-services.json` (lowercase)
3. Run `flutter clean` then `flutter pub get`

---

### Issue 3: "Waiting for data..." in Firebase Console

**Normal!** Crashlytics has delay:
- First crash: Can take up to 24 hours
- Subsequent crashes: 5-10 minutes
- Be patient and keep testing

---

### Issue 4: Crashlytics not initializing

**Check:**
1. Firebase initialized before Crashlytics
2. `google-services.json` in correct location
3. Build.gradle plugins added correctly
4. Run `flutter clean` and rebuild

---

## 📝 Next Steps After Setup

### 1. Test in Development
```bash
flutter run -d b1135bfc
```

### 2. Test in Staging
```bash
flutter run -d b1135bfc --dart-define=ENV=staging
```

### 3. Build Release APK
```bash
flutter build apk --dart-define=ENV=production --release
```

### 4. Monitor Crashes
- Check Firebase Console daily
- Review crash reports
- Fix critical issues
- Deploy updates

---

## 🎯 Success Criteria

Setup berhasil jika:
- [x] Code changes completed
- [ ] Firebase project created
- [ ] Android app added to Firebase
- [ ] Crashlytics enabled
- [ ] `google-services.json` copied
- [ ] Build.gradle updated
- [ ] App builds successfully
- [ ] Console shows "Crashlytics initialized"
- [ ] Test error appears in Firebase Console

---

## 📚 Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [FlutterFire Crashlytics](https://firebase.flutter.dev/docs/crashlytics/overview)

---

## ⚠️ Important Notes

1. **google-services.json:**
   - NEVER commit to Git
   - Keep it secure
   - Different file for each environment

2. **Crashlytics Collection:**
   - Disabled in development (by default)
   - Enabled in staging/production
   - Can be toggled in code

3. **User Privacy:**
   - Only track necessary data
   - Follow GDPR/privacy laws
   - Inform users about crash reporting

4. **Testing:**
   - Test in development first
   - Verify data appears in console
   - Remove test code before production

---

**Created:** February 26, 2026
**Status:** ⏳ Waiting for Firebase Console Setup
**Next:** Follow steps above to complete setup
