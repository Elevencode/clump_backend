import 'dart:io';

abstract class AppEnv {
  const AppEnv._();

  static final String secretKey = Platform.environment['SECRET_KEY'] ?? '';
  static final String port = Platform.environment['PORT'] ?? '';

  /// DB.
  static final String dbUsername = Platform.environment['DB_USERNAME'] ?? '';
  static final String dbPassword = Platform.environment['DB_PASSWORD'] ?? '';
  static final String dbHost = Platform.environment['DB_HOST'] ?? '';
  static final int? dbPort = int.tryParse(Platform.environment['DB_PORT'] ?? '');
  static final String dpDatabaseName = Platform.environment['DB_NAME'] ?? '';
}
