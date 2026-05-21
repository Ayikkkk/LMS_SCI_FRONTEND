# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Facebook Fresco / WebpTranscoder (dipakai oleh beberapa image library)
-dontwarn com.facebook.imagepipeline.nativecode.WebpTranscoder
-dontwarn com.facebook.imagepipeline.nativecode.WebpTranscoderImpl
-dontwarn com.facebook.imagepipeline.**
-dontwarn com.facebook.fresco.**

# Google Play Core (Flutter deferred components — tidak dipakai tapi direferensikan)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**

# Jitsi Meet
-keep class org.jitsi.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn org.jitsi.**
-dontwarn org.webrtc.**

# OkHttp / Dio
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# General missing class suppression
-dontwarn java.lang.invoke.**
-dontwarn **$$Lambda$*
