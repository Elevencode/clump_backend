import 'dart:io';

abstract class AppConst {
  const AppConst._();

  static final String key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
}
