import 'dart:io';

abstract class AppEnv {
  const AppEnv._();

  static final String secretKey = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
  static final String port = Platform.environment['PORT'] ?? '6200';

  /// DB.
  static final String dbUsername = Platform.environment['DB_USERNAME'] ?? 'admin';
  static final String dbPassword = Platform.environment['DB_PASSWORD'] ?? 'root';
  static final String dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  static final int? dbPort = int.tryParse(Platform.environment['DB_PORT'] ?? '6201');
  static final String dpDatabaseName = Platform.environment['DB_NAME'] ?? 'postgres';
}
