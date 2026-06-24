# Flutter engine and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# App Kotlin (Wear bridge, MainActivity)
-keep class app.dozealert.** { *; }

# Google Play Services / Maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Gson (used by some Google SDKs)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
