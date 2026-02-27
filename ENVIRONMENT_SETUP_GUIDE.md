# Environment Setup Guide

## ✅ Setup Completed!

Environment configuration telah berhasil diimplementasikan. Berikut adalah panduan untuk testing dan penggunaan.

---

## 📁 Files Created/Modified

### Created:
1. ✅ `lib/core/config/environment.dart` - Environment configuration class
2. ✅ `README.md` - Complete documentation with build commands
3. ✅ `test_environments.sh` - Script untuk test semua environment
4. ✅ `ENVIRONMENT_SETUP_GUIDE.md` - Panduan ini

### Modified:
1. ✅ `lib/core/network/api_client.dart` - Updated to use environment config
2. ✅ `lib/main.dart` - Added environment initialization

---

## 🧪 Testing Environments

### Method 1: Manual Testing (Recommended)

#### Test Development (Default)
```bash
flutter run
```

**Expected Output:**
```
=================================
Environment Configuration
=================================
Environment: Development
API Base URL: http://192.168.101.82:8000/api/
API Host: http://192.168.101.82:8000
Is Production: false
Debug Features: true
Connect Timeout: 60s
Receive Timeout: 60s
=================================
```

**App Title:** "LMS Student (Dev)"

---

#### Test Staging
```bash
flutter run --dart-define=ENV=staging
```

**Expected Output:**
```
=================================
Environment Configuration
=================================
Environment: Staging
API Base URL: https://staging-api.yourdomain.com/api/
API Host: https://staging-api.yourdomain.com
Is Production: false
Debug Features: true
Connect Timeout: 30s
Receive Timeout: 30s
=================================
```

**App Title:** "LMS Student (Staging)"

---

#### Test Production
```bash
flutter run --dart-define=ENV=production
```

**Expected Output:**
```
=================================
Environment Configuration
=================================
Environment: Production
API Base URL: https://api.yourdomain.com/api/
API Host: https://api.yourdomain.com
Is Production: true
Debug Features: false
Connect Timeout: 30s
Receive Timeout: 30s
=================================
```

**App Title:** "LMS Student"

**Note:** Configuration tidak akan di-print di production mode (debug features disabled)

---

### Method 2: Using Test Script

```bash
# Make script executable (first time only)
chmod +x test_environments.sh

# Run test script
./test_environments.sh
```

---

## 🔧 Configuration

### Update API URLs

Edit `lib/core/config/environment.dart`:

```dart
static String get apiBaseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://YOUR_LOCAL_IP:8000/api/'; // ← Update ini

    case Environment.staging:
      return 'https://staging.yourdomain.com/api/'; // ← Update ini

    case Environment.production:
      return 'https://api.yourdomain.com/api/'; // ← Update ini
  }
}
```

### Update Timeouts

```dart
static Duration get connectTimeout {
  return _environment == Environment.development
      ? const Duration(seconds: 60) // ← Development timeout
      : const Duration(seconds: 30); // ← Staging/Production timeout
}
```

---

## 📱 Build Commands Reference

### Development Builds

```bash
# Run on device/emulator
flutter run

# Run with specific device
flutter run -d <device-id>

# Build debug APK
flutter build apk --debug
```

### Staging Builds

```bash
# Run staging
flutter run --dart-define=ENV=staging

# Build staging APK
flutter build apk --dart-define=ENV=staging --debug

# Build staging AAB
flutter build appbundle --dart-define=ENV=staging --debug
```

### Production Builds

```bash
# Build production APK (with obfuscation)
flutter build apk \
  --dart-define=ENV=production \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --release

# Build production AAB (for Play Store)
flutter build appbundle \
  --dart-define=ENV=production \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --release
```

---

## ✅ Verification Checklist

Setelah setup, verify hal-hal berikut:

### 1. Environment Initialization
- [ ] Console menampilkan environment configuration saat app start
- [ ] Environment name sesuai dengan yang dipilih
- [ ] API URL sesuai dengan environment

### 2. API Client
- [ ] Dio menggunakan URL dari environment config
- [ ] Timeout sesuai dengan environment
- [ ] Log interceptor aktif di dev/staging, non-aktif di production

### 3. App Title
- [ ] Development: "LMS Student (Dev)"
- [ ] Staging: "LMS Student (Staging)"
- [ ] Production: "LMS Student"

### 4. Debug Features
- [ ] Development: Debug features enabled
- [ ] Staging: Debug features enabled
- [ ] Production: Debug features disabled

### 5. API Connectivity
- [ ] Test login di development environment
- [ ] Verify API calls menggunakan correct URL
- [ ] Check network logs di debug console

---

## 🐛 Troubleshooting

### Issue 1: Environment tidak berubah
**Symptom:** Selalu menggunakan development environment

**Solution:**
```bash
# Clean build
flutter clean
flutter pub get

# Run dengan explicit environment
flutter run --dart-define=ENV=staging
```

---

### Issue 2: API URL masih hardcoded
**Symptom:** Masih menggunakan URL lama

**Solution:**
1. Check `lib/core/network/api_client.dart`
2. Pastikan menggunakan `EnvironmentConfig.apiBaseUrl`
3. Restart app (hot reload tidak cukup untuk environment changes)

---

### Issue 3: Configuration tidak muncul di console
**Symptom:** Tidak ada output environment configuration

**Solution:**
1. Check `lib/main.dart` - pastikan `EnvironmentConfig.initialize()` dipanggil
2. Check `EnvironmentConfig.printConfig()` dipanggil
3. Pastikan running di debug mode (bukan release)

---

### Issue 4: Build failed dengan --dart-define
**Symptom:** Error saat build dengan environment variable

**Solution:**
```bash
# Pastikan format benar (no spaces around =)
flutter run --dart-define=ENV=production

# Bukan ini:
flutter run --dart-define=ENV = production  # ❌ Wrong
```

---

## 📊 Environment Comparison

| Feature | Development | Staging | Production |
|---------|------------|---------|------------|
| API URL | Local (192.168.x.x) | Staging server | Production server |
| Debug Features | ✅ Enabled | ✅ Enabled | ❌ Disabled |
| Logging | Verbose | Moderate | Minimal |
| Timeout | 60s | 30s | 30s |
| App Name Suffix | (Dev) | (Staging) | None |
| Obfuscation | ❌ No | ❌ No | ✅ Yes |
| Crashlytics | Optional | ✅ Yes | ✅ Yes |

---

## 🎯 Next Steps

Setelah environment configuration selesai:

1. ✅ **Test semua 3 environment** - Pastikan semuanya berfungsi
2. ⬜ **Update production URLs** - Ganti dengan URL server production yang sebenarnya
3. ⬜ **Setup CI/CD** - Automate builds untuk setiap environment
4. ⬜ **Add Firebase** - Setup Crashlytics & Analytics per environment
5. ⬜ **Document API endpoints** - Untuk setiap environment

---

## 📝 Notes

- Environment ditentukan saat **build time**, bukan runtime
- Untuk switch environment, harus **rebuild** aplikasi
- Production builds **harus** menggunakan `--dart-define=ENV=production`
- Jangan lupa **backup keystore** untuk production builds

---

## 🔗 Related Documentation

- [README.md](README.md) - Complete project documentation
- [QUICK_FIXES_CHECKLIST.md](QUICK_FIXES_CHECKLIST.md) - Production readiness checklist
- [PRODUCTION_READINESS_ANALYSIS.md](PRODUCTION_READINESS_ANALYSIS.md) - Full analysis

---

**Setup Date:** February 26, 2026
**Status:** ✅ Complete
**Next Task:** Clean up debug logs (Week 1, Day 3)
