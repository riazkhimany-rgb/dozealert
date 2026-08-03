# Keep only what reflection / Flutter channels need.
# Broad -keep on Flutter/GMS was suppressing R8 optimization/obfuscation rates
# (Play Console recommendation). Plugin consumer rules still apply via Gradle.

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn sun.misc.**
-dontwarn io.flutter.embedding.**

# MethodChannel / EventChannel entry points used from Dart.
-keep class app.dozealert.MainActivity { *; }
-keep class app.dozealert.wear.** { *; }

# Wearable / Maps SDKs use reflection for some APIs; keep model types, allow shrinking the rest.
-keep class com.google.android.gms.wearable.** { *; }
-keep class com.google.android.gms.maps.model.** { *; }
-dontwarn com.google.android.gms.**
