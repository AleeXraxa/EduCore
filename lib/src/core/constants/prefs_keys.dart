abstract final class PrefsKeys {
  static const rememberMe = 'auth.rememberMe';

  /// Set to true after a successful login, cleared on explicit logout.
  /// Used by [SplashView] to route instantly without waiting on the
  /// Firebase Auth stream (which emits null on cold start on Windows/web).
  static const signedIn = 'auth.signedIn';
}

