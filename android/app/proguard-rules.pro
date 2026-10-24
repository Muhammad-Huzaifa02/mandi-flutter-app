# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase & PostgREST / GoTrue / Realtime / Storage
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }

# PDF & Printing
-keep class com.printing.** { *; }

# Keep data models & json serialization methods
-keepclassmembers class * {
    *** fromMap(...);
    *** toMap(...);
}

# Ignore warnings from missing optional references in transitive dependencies
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.protobuf.**
