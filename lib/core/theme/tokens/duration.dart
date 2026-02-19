class LWDuration {
  LWDuration._();

  /// Immediate state change — no visible animation.
  static const Duration instant = Duration.zero;

  /// Quick micro-interaction — icon press, toggle.
  static const Duration fast = Duration(milliseconds: 100);

  /// Standard UI transition — route push, card expand.
  static const Duration normal = Duration(milliseconds: 200);

  /// Emphasised motion — drawer slide, modal rise.
  static const Duration slow = Duration(milliseconds: 350);

  /// Celebration / confetti burst.
  static const Duration xslow = Duration(milliseconds: 500);
}
