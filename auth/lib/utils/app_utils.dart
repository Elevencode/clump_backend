import 'dart:io';

import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

abstract class AppUtils {
  AppUtils._();

  static int getIdFromToken(String token) {
    try {
      final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
      final jwtClaim = verifyJwtHS256Signature(token, key);
      return int.parse(jwtClaim['id'].toString());
    } catch (_) {
      rethrow;
    }
  }

  static int getIdFromHeader(String header) {
    try {
      final token = AuthorizationBearerParser().parse(header);
      return getIdFromToken(token ?? '');
    } catch (_) {
      rethrow;
    }
  }
}
