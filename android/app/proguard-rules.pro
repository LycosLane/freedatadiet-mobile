# R8 rules for FreeDataDiet Mobile.
# The Flutter Gradle plugin and plugins ship their own consumer rules.

# Strip Android logging in release builds to prevent data leakage in logcat
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}
