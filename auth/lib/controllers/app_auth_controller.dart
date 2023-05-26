import 'dart:io';

import 'package:auth/models/app_response_model.dart';
import 'package:auth/models/user_model.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  /// Log in.
  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.username == null || user.password == null) {
      return Response.badRequest(
        body: AppResponseModel(message: 'Username and Password are required fields'),
      );
    }

    try {
      final qFindUser = Query<User>(managedContext)
        ..where((table) => table.username).equalTo(user.username)
        ..returningProperties((table) => [table.id, table.salt, table.hashPassword]);

      final findUser = await qFindUser.fetchOne();

      if (findUser == null) {
        throw QueryException.input('User not found', []);
      }
      final requestHashPassword = generatePasswordHash(user.password ?? '', findUser.salt ?? '');

      if (requestHashPassword == findUser.hashPassword) {
        _updateTokens(findUser.id ?? -1, managedContext);
        final newUser = await managedContext.fetchObjectWithID<User>(findUser.id);
        return Response.ok(AppResponseModel(data: newUser?.backing.contents, message: 'Auth success'));
      } else {
        throw QueryException.input('Invalid password', []);
      }
    } on QueryException catch (error) {
      return Response.serverError(body: AppResponseModel(message: error.message));
    }
  }

  /// Sign up.
  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.username == null || user.password == null || user.email == null) {
      return Response.badRequest(
        body: AppResponseModel(message: 'Username, Password and Email are required fields'),
      );
    }

    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password ?? '', salt);

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();

        id = createdUser.asMap()['id'];

        await _updateTokens(id, transaction);
      });

      final userData = await managedContext.fetchObjectWithID<User>(id);

      return Response.ok(AppResponseModel(
        data: userData?.backing.contents,
        message: 'Sign up success',
      ));
    } on QueryException catch (error) {
      return Response.serverError(body: AppResponseModel(message: error.message));
    }
  }

  Future<void> _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, dynamic> tokens = _getTokens(id);

    final qUpdateTokens = Query<User>(transaction)
      ..where((user) => user.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTokens.updateOne();
  }

  /// Tokens refresh.
  @Operation.post('refresh')
  Future<Response> refreshToken(@Bind.path('refresh') String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);
      if (user?.refreshToken != refreshToken) {
        return Response.unauthorized(body: AppResponseModel(message: 'Invalid token'));
      } else {
        await _updateTokens(id, managedContext);
        return Response.ok(AppResponseModel(data: user?.backing.contents, message: 'Tokens update success'));
      }
    } catch (error) {
      return Response.serverError(body: AppResponseModel(message: error.toString()));
    }
  }

  Map<String, dynamic> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(maxAge: Duration(hours: 1), otherClaims: {'id': id});
    final refreshClaimSet = JwtClaim(otherClaims: {'id': id});
    final tokens = <String, dynamic>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);

    return tokens;
  }
}
