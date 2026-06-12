class AppConstants {
  AppConstants._();

  static const String appName = 'eFordo';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String themeModeKey = 'theme_mode';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiConnectTimeout = Duration(seconds: 10);
}
