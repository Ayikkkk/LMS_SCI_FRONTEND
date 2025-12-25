# lms_frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


```
lms_frontend
├─ .flutter-plugins-dependencies
├─ analysis_options.yaml
├─ android
│  ├─ .kotlin
│  │  ├─ errors
│  │  └─ sessions
│  ├─ app
│  │  ├─ build.gradle.kts
│  │  └─ src
│  │     ├─ debug
│  │     ├─ main
│  │     │  ├─ AndroidManifest.xml
│  │     │  ├─ java
│  │     │  │  └─ io
│  │     │  │     └─ flutter
│  │     │  │        └─ plugins
│  │     │  │           └─ GeneratedPluginRegistrant.java
│  │     │  ├─ kotlin
│  │     │  │  └─ com
│  │     │  └─ res
│  │     │     ├─ drawable
│  │     │     │  ├─ background.png
│  │     │     │  └─ launch_background.xml
│  │     │     ├─ drawable-hdpi
│  │     │     ├─ drawable-mdpi
│  │     │     ├─ drawable-v21
│  │     │     │  ├─ background.png
│  │     │     │  └─ launch_background.xml
│  │     │     ├─ drawable-xhdpi
│  │     │     ├─ drawable-xxhdpi
│  │     │     ├─ drawable-xxxhdpi
│  │     │     ├─ mipmap-hdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-mdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-xhdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-xxhdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-xxxhdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ values
│  │     │     │  └─ styles.xml
│  │     │     ├─ values-night
│  │     │     │  └─ styles.xml
│  │     │     ├─ values-night-v31
│  │     │     │  └─ styles.xml
│  │     │     ├─ values-v31
│  │     │     │  └─ styles.xml
│  │     │     └─ xml
│  │     │        └─ file_paths.xml
│  │     └─ profile
│  │        └─ AndroidManifest.xml
│  ├─ build.gradle.kts
│  ├─ gradle
│  │  └─ wrapper
│  │     ├─ gradle-wrapper.jar
│  │     └─ gradle-wrapper.properties
│  ├─ gradle.properties
│  ├─ gradlew
│  ├─ gradlew.bat
│  └─ settings.gradle.kts
├─ assets
│  └─ images
│     ├─ logosci.png
│     ├─ onboarding_1.png
│     └─ splashscreen.png
├─ ios
│  ├─ Flutter
│  │  ├─ AppFrameworkInfo.plist
│  │  ├─ Debug.xcconfig
│  │  ├─ flutter_export_environment.sh
│  │  ├─ Generated.xcconfig
│  │  └─ Release.xcconfig
│  ├─ Runner
│  │  ├─ AppDelegate.swift
│  │  ├─ Assets.xcassets
│  │  │  ├─ AppIcon.appiconset
│  │  │  │  ├─ Contents.json
│  │  │  │  ├─ Icon-App-1024x1024@1x.png
│  │  │  │  ├─ Icon-App-20x20@1x.png
│  │  │  │  ├─ Icon-App-20x20@2x.png
│  │  │  │  ├─ Icon-App-20x20@3x.png
│  │  │  │  ├─ Icon-App-29x29@1x.png
│  │  │  │  ├─ Icon-App-29x29@2x.png
│  │  │  │  ├─ Icon-App-29x29@3x.png
│  │  │  │  ├─ Icon-App-40x40@1x.png
│  │  │  │  ├─ Icon-App-40x40@2x.png
│  │  │  │  ├─ Icon-App-40x40@3x.png
│  │  │  │  ├─ Icon-App-60x60@2x.png
│  │  │  │  ├─ Icon-App-60x60@3x.png
│  │  │  │  ├─ Icon-App-76x76@1x.png
│  │  │  │  ├─ Icon-App-76x76@2x.png
│  │  │  │  └─ Icon-App-83.5x83.5@2x.png
│  │  │  ├─ LaunchBackground.imageset
│  │  │  │  ├─ background.png
│  │  │  │  └─ Contents.json
│  │  │  └─ LaunchImage.imageset
│  │  │     ├─ Contents.json
│  │  │     ├─ LaunchImage.png
│  │  │     ├─ LaunchImage@2x.png
│  │  │     ├─ LaunchImage@3x.png
│  │  │     └─ README.md
│  │  ├─ Base.lproj
│  │  │  ├─ LaunchScreen.storyboard
│  │  │  └─ Main.storyboard
│  │  ├─ GeneratedPluginRegistrant.h
│  │  ├─ GeneratedPluginRegistrant.m
│  │  ├─ Info.plist
│  │  └─ Runner-Bridging-Header.h
│  ├─ Runner.xcodeproj
│  │  ├─ project.pbxproj
│  │  ├─ project.xcworkspace
│  │  │  ├─ contents.xcworkspacedata
│  │  │  └─ xcshareddata
│  │  │     ├─ IDEWorkspaceChecks.plist
│  │  │     └─ WorkspaceSettings.xcsettings
│  │  └─ xcshareddata
│  │     └─ xcschemes
│  │        └─ Runner.xcscheme
│  └─ RunnerTests
│     └─ RunnerTests.swift
├─ lib
│  ├─ auth_redirector.dart
│  ├─ core
│  │  ├─ constants
│  │  ├─ errors
│  │  ├─ init
│  │  │  └─ app_initializer.dart
│  │  ├─ network
│  │  │  └─ api_client.dart
│  │  └─ routes
│  ├─ features
│  │  ├─ auth
│  │  │  ├─ data
│  │  │  │  ├─ auth_repository.dart
│  │  │  │  ├─ models
│  │  │  │  │  ├─ guru_model.dart
│  │  │  │  │  └─ student_model.dart
│  │  │  │  └─ repository
│  │  │  │     └─ onboarding_repository.dart
│  │  │  ├─ domain
│  │  │  │  └─ auth_notifier.dart
│  │  │  └─ presentation
│  │  │     ├─ login_screen.dart
│  │  │     └─ onboarding_screen.dart
│  │  ├─ course
│  │  │  ├─ data
│  │  │  │  ├─ course_repository.dart
│  │  │  │  └─ task_repository.dart
│  │  │  ├─ domain
│  │  │  │  ├─ models
│  │  │  │  │  ├─ assignment_model.dart
│  │  │  │  │  └─ course_material_model.dart
│  │  │  │  └─ providers
│  │  │  │     └─ course_providers.dart
│  │  │  └─ presentation
│  │  │     └─ screens
│  │  │        ├─ assignment_detail_screen.dart
│  │  │        ├─ course_screen.dart
│  │  │        ├─ material_detail_screen.dart
│  │  │        └─ submit_task_screen.dart
│  │  ├─ dashboard
│  │  │  └─ data
│  │  │     └─ dashboard_model.dart
│  │  ├─ home
│  │  │  ├─ data
│  │  │  │  ├─ models
│  │  │  │  │  └─ dashboard_model.dart
│  │  │  │  └─ repository
│  │  │  │     └─ home_repository.dart
│  │  │  └─ presentation
│  │  │     ├─ providers
│  │  │     │  └─ home_provider.dart
│  │  │     └─ screens
│  │  │        └─ home_screen.dart
│  │  ├─ laporan_harian
│  │  │  ├─ data
│  │  │  │  └─ laporan_repository.dart
│  │  │  └─ presentation
│  │  │     ├─ providers
│  │  │     │  └─ laporan_provider.dart
│  │  │     └─ screens
│  │  │        └─ laporan_harian_screen.dart
│  │  ├─ online_class
│  │  │  └─ presentation
│  │  │     └─ screens
│  │  │        └─ online_class_screen.dart
│  │  ├─ profile
│  │  │  ├─ data
│  │  │  │  └─ profile_repository.dart
│  │  │  └─ presentation
│  │  │     ├─ providers
│  │  │     │  └─ profile_provider.dart
│  │  │     └─ screens
│  │  │        ├─ profile_detail_screen.dart
│  │  │        └─ profile_screen.dart
│  │  └─ quiz
│  │     ├─ data
│  │     │  ├─ quiz_repository.dart
│  │     │  └─ remote_quiz_repository.dart
│  │     ├─ domain
│  │     │  ├─ models
│  │     │  │  └─ question_model.dart
│  │     │  └─ quiz_notifier.dart
│  │     └─ presentation
│  │        ├─ providers
│  │        │  └─ quiz_provider.dart
│  │        └─ screens
│  │           ├─ exercise_list_screen.dart
│  │           ├─ lessons_quiz_screen.dart
│  │           ├─ quiz_remote_screen.dart
│  │           ├─ quiz_screen.dart
│  │           └─ quiz_view.dart
│  ├─ main.dart
│  └─ navigation_service.dart
├─ linux
│  ├─ CMakeLists.txt
│  ├─ flutter
│  │  ├─ CMakeLists.txt
│  │  └─ generated_plugins.cmake
│  └─ runner
│     ├─ CMakeLists.txt
│     ├─ main.cc
│     ├─ my_application.cc
│     └─ my_application.h
├─ macos
│  ├─ Flutter
│  │  ├─ Flutter-Debug.xcconfig
│  │  ├─ Flutter-Release.xcconfig
│  │  └─ GeneratedPluginRegistrant.swift
│  ├─ Runner
│  │  ├─ AppDelegate.swift
│  │  ├─ Assets.xcassets
│  │  │  └─ AppIcon.appiconset
│  │  │     ├─ app_icon_1024.png
│  │  │     ├─ app_icon_128.png
│  │  │     ├─ app_icon_16.png
│  │  │     ├─ app_icon_256.png
│  │  │     ├─ app_icon_32.png
│  │  │     ├─ app_icon_512.png
│  │  │     ├─ app_icon_64.png
│  │  │     └─ Contents.json
│  │  ├─ Base.lproj
│  │  │  └─ MainMenu.xib
│  │  ├─ Configs
│  │  │  ├─ AppInfo.xcconfig
│  │  │  ├─ Debug.xcconfig
│  │  │  ├─ Release.xcconfig
│  │  │  └─ Warnings.xcconfig
│  │  ├─ DebugProfile.entitlements
│  │  ├─ Info.plist
│  │  ├─ MainFlutterWindow.swift
│  │  └─ Release.entitlements
│  ├─ Runner.xcodeproj
│  │  ├─ project.pbxproj
│  │  ├─ project.xcworkspace
│  │  │  └─ xcshareddata
│  │  │     └─ IDEWorkspaceChecks.plist
│  │  └─ xcshareddata
│  │     └─ xcschemes
│  │        └─ Runner.xcscheme
│  └─ RunnerTests
│     └─ RunnerTests.swift
├─ pubspec.lock
├─ pubspec.yaml
├─ README.md
├─ test
│  └─ widget_test.dart
├─ web
│  ├─ favicon.png
│  ├─ icons
│  │  ├─ Icon-192.png
│  │  ├─ Icon-512.png
│  │  ├─ Icon-maskable-192.png
│  │  └─ Icon-maskable-512.png
│  ├─ index.html
│  ├─ manifest.json
│  └─ splash
│     └─ img
│        └─ light-background.png
└─ windows
   ├─ CMakeLists.txt
   ├─ flutter
   │  ├─ CMakeLists.txt
   │  └─ generated_plugins.cmake
   └─ runner
      ├─ CMakeLists.txt
      ├─ flutter_window.cpp
      ├─ flutter_window.h
      ├─ main.cpp
      ├─ resource.h
      ├─ resources
      │  └─ app_icon.ico
      ├─ runner.exe.manifest
      ├─ Runner.rc
      ├─ utils.cpp
      ├─ utils.h
      ├─ win32_window.cpp
      └─ win32_window.h

```