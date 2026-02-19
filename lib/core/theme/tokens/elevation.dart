class LWElevation {
  LWElevation._();

  /// Flat — no shadow. Cards on white bg, nav bar.
  static const double none = 0.0;

  /// Subtle lift — inline cards, input fields.
  static const double low = 2.0;

  /// Moderate — raised cards, FABs.
  static const double medium = 4.0;

  /// Strong — sticky headers, popovers.
  static const double high = 8.0;

  /// Maximum — modals, bottom sheets, overlays.
  static const double overlay = 16.0;
}
