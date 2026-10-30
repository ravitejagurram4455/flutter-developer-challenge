abstract final class AppConfig {
  /// Override per target with `--dart-define=API_BASE_URL=...`, see the README.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Identifies this app to the OpenStreetMap tile servers.
  static const appId = 'com.tuichallenege.tripplanner';
}
