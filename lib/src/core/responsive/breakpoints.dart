abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 1024;
}

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeForWidth(double width) {
  if (width < Breakpoints.compact) return ScreenSize.compact;
  if (width < Breakpoints.medium) return ScreenSize.medium;
  return ScreenSize.expanded;
}
