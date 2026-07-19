# =============================================================================
# ProGuard / R8 rules for release builds
# =============================================================================
# Flutter-specific: keep all Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive model classes (they use reflection)
-keep class * extends com.hive.** { *; }
-keep class * extends io.hive.** { *; }

# Keep PdfDocument and other serialized models
-keep class com.yourname.legalassistant.** { *; }

# Keep Gson / JSON serialization
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service

# Syncfusion PDF — keep all native classes used via FFI/Dart
-keep class com.syncfusion.** { *; }
-keep class syncfusion.** { *; }
