class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  static const Duration pageTransition = normal;
  static const Duration dialogTransition = fast;
  static const Duration loadingMinDuration = Duration(milliseconds: 500);
}
