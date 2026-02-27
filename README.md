# LMS Frontend - Flutter Application

Learning Management System (LMS) mobile application untuk siswa, dibangun dengan Flutter.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Build Commands](#build-commands)
- [Project Structure](#project-structure)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)

---

## ✨ Features

- 🔐 **Authentication** - Login, logout, change password
- 📚 **Course Management** - View materials, assignments, and quizzes
- 📝 **Quiz System** - Multiple question types with anti-cheating mechanism
- 📊 **Grades & Reports** - View grades and daily reports
- 🎥 **Online Class** - Jitsi Meet integration for virtual classes
- 👤 **Profile Management** - View and update profile
- 🌓 **Theme Support** - Light and dark mode
- 📱 **Responsive UI** - Works on various screen sizes

---

## 🛠 Tech Stack

- **Framework:** Flutter 3.x
- **Language:** Dart 3.x
- **State Management:** Riverpod 2.4.9
- **HTTP Client:** Dio 5.0.0
- **Secure Storage:** flutter_secure_storage 9.0.0
- **Architecture:** Clean Architecture with feature-based structure

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd lms_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🌍 Environment Configuration

Aplikasi ini mendukung 3 environment berbeda:

### 1. Development (Default)
- API URL: `http://192.168.101.82:8000/api/`
- Debug features: Enabled
- Logging: Verbose
- App name: "LMS Student (Dev)"

### 2. Staging
- API URL: `https://staging-api.yourdomain.com/api/`
- Debug features: Enabled
- Logging: Moderate
- App name: "LMS Student (Staging)"

### 3. Production
- API URL: `https://api.yourdomain.com/api/`
- Debug features: Disabled
- Logging: Minimal (errors only)
- App name: "LMS Student"

### Mengubah Environment

Environment dikonfigurasi di `lib/core/config/environment.dart`. Untuk mengubah URL API:

```dart
// lib/core/config/environment.dart
static String get apiBaseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://YOUR_DEV_IP:8000/api/';
    case Environment.staging:
      return 'https://staging-api.yourdomain.com/api/';
    case Environment.production:
      return 'https://api.yourdomain.com/api/';
  }
}
```

---

## 🔨 Build Commands

### Development

```bash
# Run in development mode (default)
flutter run

# Run with hot reload
flutter run --hot

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

### Staging

```bash
# Run in staging mode
flutter run --dart-define=ENV=staging

# Build APK for staging
flutter build apk --dart-define=ENV=staging --debug

# Build AAB for staging
flutter build appbundle --dart-define=ENV=staging --debug
```

### Production

```bash
# Build APK for production (with obfuscation)
flutter build apk \
  --dart-define=ENV=production \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --release

# Build AAB for Google Play Store (with obfuscation)
flutter build appbundle \
  --dart-define=ENV=production \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --release

# Build iOS for production
flutter build ios \
  --dart-define=ENV=production \
  --obfuscate \
  --split-debug-info=build/ios/symbols \
  --release
```

### Analyze & Clean

```bash
# Analyze code
flutter analyze

# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated
```

---

## 📁 Project Structure

```
lib/
├── core/                       # Core functionality
│   ├── config/                 # Configuration (environment, etc.)
│   ├── constants/              # App constants
│   ├── errors/                 # Error handling
│   ├── init/                   # App initialization
│   ├── network/                # API client & networking
│   ├── routes/                 # Navigation routes
│   ├── theme/                  # Theme configuration
│   ├── utils/                  # Utility functions
│   └── widgets/                # Reusable widgets
│
├── features/                   # Feature modules
│   ├── auth/                   # Authentication
│   │   ├── data/               # Data layer (repositories)
│   │   ├── domain/             # Domain layer (models, notifiers)
│   │   └── presentation/       # Presentation layer (screens, widgets)
│   │
│   ├── course/                 # Course management
│   ├── grades/                 # Grades & reports
│   ├── home/                   # Home dashboard
│   ├── laporan_harian/         # Daily reports
│   ├── online_class/           # Online classes
│   ├── profile/                # User profile
│   └── quiz/                   # Quiz system
│
├── auth_redirector.dart        # Auth state redirector
├── main.dart                   # App entry point
├── navigation_service.dart     # Navigation service
└── scaffold_messenger_key.dart # Global messenger key
```

---

## 💻 Development

### Code Style

Project ini menggunakan `flutter_lints` untuk code analysis. Pastikan code Anda mengikuti style guide:

```bash
# Run analyzer
flutter analyze

# Format code
flutter format lib/
```

### State Management

Menggunakan **Riverpod** untuk state management:

```dart
// Provider example
final myProvider = Provider<MyService>((ref) {
  return MyService();
});

// StateNotifier example
final myNotifierProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// Consumer widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myNotifierProvider);
    return Text(state.value);
  }
}
```

### API Client

API client dikonfigurasi di `lib/core/network/api_client.dart`:

```dart
// Make API call
final response = await dio.get('/endpoint');

// With authentication (automatic via TokenInterceptor)
final response = await dio.post('/protected-endpoint', data: {...});
```

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/domain/auth_notifier_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

### Test Structure

```
test/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   └── auth_notifier_test.dart
│   │   └── data/
│   │       └── auth_repository_test.dart
│   └── ...
└── core/
    ├── network/
    │   └── api_client_test.dart
    └── utils/
        └── logger_test.dart
```

---

## 🚢 Deployment

### Android

1. **Generate Keystore** (first time only)
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. **Configure Signing** in `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

3. **Build Release**
   ```bash
   flutter build appbundle \
     --dart-define=ENV=production \
     --obfuscate \
     --split-debug-info=build/app/outputs/symbols \
     --release
   ```

4. **Upload to Play Store**
   - Go to Google Play Console
   - Upload `build/app/outputs/bundle/release/app-release.aab`

### iOS

1. **Configure Signing** in Xcode
   - Open `ios/Runner.xcworkspace`
   - Select Runner > Signing & Capabilities
   - Configure Team and Bundle Identifier

2. **Build Release**
   ```bash
   flutter build ios \
     --dart-define=ENV=production \
     --obfuscate \
     --split-debug-info=build/ios/symbols \
     --release
   ```

3. **Archive & Upload**
   - Open Xcode
   - Product > Archive
   - Distribute App > App Store Connect

---

## 📝 Environment Variables

Aplikasi menggunakan `--dart-define` untuk environment variables:

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| ENV | development, staging, production | development | Application environment |

**Example:**
```bash
flutter run --dart-define=ENV=production
```

---

## 🔧 Troubleshooting

### Common Issues

**1. Gradle build failed**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**2. CocoaPods issues (iOS)**
```bash
cd ios
pod deintegrate
pod install
cd ..
```

**3. Network error / API not reachable**
- Check if backend server is running
- Verify API URL in `lib/core/config/environment.dart`
- Check device/emulator network connection

**4. Hot reload not working**
```bash
# Stop app and run again
flutter run
```

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

## 📄 License

[Add your license here]

---

## 👥 Contributors

[Add contributors here]

---

## 📞 Support

For support, email [your-email] or create an issue in the repository.

---

**Last Updated:** February 26, 2026
**Version:** 1.0.0+1
