# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
# Play Core (deferred components) - not used
-dontwarn com.google.android.play.core.**
# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**
