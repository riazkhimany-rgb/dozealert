# Wear OS ambient / always-on
-keep class com.google.android.wearable.** { *; }
-keep interface com.google.android.wearable.** { *; }

# App entry points (activities, tile service, receivers)
-keep class app.dozealert.wear.** { *; }

# Wearable Data Layer / MessageClient
-keep class com.google.android.gms.wearable.** { *; }
-dontwarn com.google.android.gms.**

# Tiles / ProtoLayout (reflection + codegen)
-keep class androidx.wear.tiles.** { *; }
-keep class androidx.wear.protolayout.** { *; }
-keep class androidx.wear.watchface.** { *; }

-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
