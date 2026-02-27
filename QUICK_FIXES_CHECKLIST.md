# Quick Fixes Checklist - Prioritas Tinggi

Checklist ini berisi perbaikan yang HARUS dilakukan sebelum production release, diurutkan berdasarkan prioritas dan kemudahan implementasi.

---

## ✅ WEEK 1: Critical Security & Configuration

### Day 1-2: Environment Configuration ✅ COMPLETED
- [x] Buat `lib/core/config/environment.dart`
- [x] Update `api_client.dart` untuk gunakan environment config
- [x] Test dengan 3 environment (dev/staging/prod)
- [x] Update build commands di README

**Files created:**
- `lib/core/config/environment.dart` ✅
- `README.md` ✅
- `test_environments.sh` ✅
- `ENVIRONMENT_SETUP_GUIDE.md` ✅

**Files modified:**
- `lib/core/network/api_client.dart` ✅
- `lib/main.dart` ✅

**Status:** ✅ DONE - Ready for testing

---

### Day 3: Clean Up Debug Logs ✅ COMPLETED
- [x] Ganti semua `debugPrint()` dengan `AppLogger.debug()`
- [x] Ganti `print()` di jitsi_helper.dart dengan `AppLogger`
- [x] Verify semua logs menggunakan `kDebugMode` check

**Files modified:**
- `lib/core/config/environment.dart` ✅
- `lib/features/quiz/domain/quiz_notifier.dart` ✅
- `lib/features/quiz/presentation/screens/lessons_quiz_screen.dart` ✅
- `lib/features/quiz/presentation/screens/exercise_list_screen.dart` ✅
- `lib/features/online_class/presentation/screens/jitsi_helper.dart` ✅

**Status:** ✅ DONE - All debug logs cleaned up

**Verification command:**
```bash
grep -r "debugPrint\|print(" lib/ --include="*.dart" | grep -v "AppLogger" | grep -v "printConfig"
```

---

### Day 4-5: Error Tracking Setup
- [ ] Add Firebase to project
- [ ] Install `firebase_core` & `firebase_crashlytics`
- [ ] Update `main.dart` dengan Crashlytics initialization
- [ ] Test crash reporting
- [ ] Setup Firebase console

**Dependencies to add:**
```yaml
firebase_core: ^2.24.2
firebase_crashlytics: ^3.4.9
```

**Files to modify:**
- `pubspec.yaml`
- `lib/main.dart`
- `android/app/build.gradle`
- `ios/Runner/Info.plist`

---

## ✅ WEEK 2: Analytics & Monitoring

### Day 1-2: Analytics Setup
- [ ] Install `firebase_analytics`
- [ ] Buat `lib/core/analytics/analytics_service.dart`
- [ ] Add analytics ke critical flows:
  - Login/Logout
  - Quiz start/complete
  - Assignment submit
  - Screen views
- [ ] Test analytics di Firebase console

**Files to create:**
- `lib/core/analytics/analytics_service.dart`

**Files to modify:**
- `lib/features/auth/domain/auth_notifier.dart`
- `lib/features/quiz/domain/quiz_notifier.dart`
- `lib/features/course/presentation/screens/*`

---

### Day 3: Version Check
- [ ] Install `package_info_plus`
- [ ] Buat `lib/core/services/version_service.dart`
- [ ] Buat version check dialog
- [ ] Integrate di app startup
- [ ] Create backend endpoint `/app/version`

**Dependencies to add:**
```yaml
package_info_plus: ^5.0.1
```

---

### Day 4-5: Error Handling UI
- [ ] Buat `lib/core/widgets/error_widget.dart`
- [ ] Buat `lib/core/widgets/loading_overlay.dart`
- [ ] Buat `lib/core/widgets/empty_state_widget.dart`
- [ ] Replace semua error handling dengan widget baru
- [ ] Add retry functionality

---

## ✅ WEEK 3: Testing & Quality

### Day 1-3: Unit Tests
- [ ] Setup test structure
- [ ] Write tests untuk `auth_notifier.dart`
- [ ] Write tests untuk `quiz_notifier.dart`
- [ ] Write tests untuk `question_model.dart`
- [ ] Write tests untuk `api_client.dart`
- [ ] Target: 50% coverage minimum

**Command to run tests:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

### Day 4-5: Manual Testing
- [ ] Test di Android (minimal 3 devices berbeda)
- [ ] Test di iOS (jika ada)
- [ ] Test dengan slow network (Network Link Conditioner)
- [ ] Test offline mode
- [ ] Test dengan berbagai screen sizes
- [ ] Document bugs di issue tracker

---

## ✅ WEEK 4: Optimization & Release Prep

### Day 1-2: Performance Optimization
- [ ] Add image caching (`cached_network_image`)
- [ ] Implement pagination untuk list panjang
- [ ] Add pull-to-refresh
- [ ] Optimize build size
- [ ] Profile dengan DevTools

**Dependencies to add:**
```yaml
cached_network_image: ^3.3.1
```

---

### Day 3: Build Configuration
- [ ] Setup ProGuard rules (Android)
- [ ] Enable obfuscation
- [ ] Test release build
- [ ] Verify obfuscation works
- [ ] Upload symbols ke Crashlytics

**Build commands:**
```bash
# Android APK
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols --release

# Android AAB (for Play Store)
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols --release

# iOS
flutter build ios --obfuscate --split-debug-info=build/ios/symbols --release
```

---

### Day 4: App Store Preparation
- [ ] Prepare app icons (all sizes)
- [ ] Take screenshots (5-8 per platform)
- [ ] Write app description (ID & EN)
- [ ] Create privacy policy
- [ ] Create terms of service
- [ ] Setup support email

---

### Day 5: Final QA & Release
- [ ] Final testing di release build
- [ ] Check all checklist items
- [ ] Create release notes
- [ ] Tag version di Git
- [ ] Upload ke Play Store (internal testing)
- [ ] Monitor Crashlytics for 24 hours

---

## 📝 QUICK COMMANDS REFERENCE

### Development
```bash
# Run in development
flutter run

# Run in staging
flutter run --dart-define=ENV=staging

# Hot reload
r

# Hot restart
R
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test
flutter test test/features/auth/domain/auth_notifier_test.dart

# Run with coverage
flutter test --coverage

# View coverage
genhtml coverage/lcov.info -o coverage/html
```

### Build
```bash
# Clean build
flutter clean
flutter pub get

# Build APK (debug)
flutter build apk --debug

# Build APK (release with obfuscation)
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols --release

# Build AAB (Play Store)
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols --release

# Check app size
flutter build apk --analyze-size
```

### Analysis
```bash
# Run analyzer
flutter analyze

# Check outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

---

## 🚨 CRITICAL REMINDERS

1. **NEVER commit:**
   - API keys
   - Passwords
   - Keystore files
   - `.env` files

2. **ALWAYS:**
   - Test di release build sebelum upload
   - Backup keystore file
   - Increment version number
   - Create Git tag untuk setiap release
   - Monitor Crashlytics setelah release

3. **BEFORE RELEASE:**
   - [ ] All tests passing
   - [ ] No critical bugs
   - [ ] Crashlytics working
   - [ ] Analytics working
   - [ ] Version check working
   - [ ] Obfuscation enabled
   - [ ] Release build tested

---

## 📊 PROGRESS TRACKING

Update checklist ini setiap hari:

**Week 1:** ✅✅✅⬜⬜ (3/5 days)
**Week 2:** ⬜⬜⬜⬜⬜ (0/5 days)
**Week 3:** ⬜⬜⬜⬜⬜ (0/5 days)
**Week 4:** ⬜⬜⬜⬜⬜ (0/5 days)

**Overall Progress:** 15% (3/20 days)

---

## 🎯 SUCCESS CRITERIA

Aplikasi siap production jika:
- ✅ All critical fixes completed
- ✅ Test coverage > 50%
- ✅ No critical bugs
- ✅ Crashlytics integrated
- ✅ Analytics integrated
- ✅ Release build tested
- ✅ App store assets ready

**Target Launch Date:** [ISI TANGGAL TARGET]

---

**Last Updated:** 26 Februari 2026
**Status:** 🔴 Not Started
