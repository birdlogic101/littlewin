// Stub for dart:html for mobile platforms
class Window {
  Navigator get navigator => Navigator();
  MediaQueryList matchMedia(String query) => MediaQueryList();
}

class Navigator {
  String get userAgent => '';
  bool get standalone => false;
}

class MediaQueryList {
  bool get matches => false;
}

final window = Window();
