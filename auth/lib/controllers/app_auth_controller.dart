import 'dart:io';

import 'package:auth/models/app_response_model.dart';
import 'package:auth/models/user_model.dart';
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

    final User fetchedUser = User();
    return Response.ok(AppResponseModel(
      data: {
        'id': fetchedUser.id,
        'refreshToken': fetchedUser.refreshToken,
        'accessToken': fetchedUser.accessToken,
      },
      message: 'Auth success',
    ).toJson());
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

        final Map<String, dynamic> tokens = _getTokens(id);

        final qUpdateTokens = Query<User>(transaction)
          ..where((user) => user.id).equalTo(id)
          ..values.accessToken = tokens['access']
          ..values.refreshToken = tokens['refresh'];

        await qUpdateTokens.updateOne();
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

  /// Tokens refresh.
  @Operation.post('refresh')
  Future<Response> refreshToken(@Bind.path('refresh') String refreshToken) async {
    final User fetchedUser = User();
    return Response.ok(AppResponseModel(
      data: {
        'id': fetchedUser.id,
        'refreshToken': fetchedUser.refreshToken,
        'accessToken': fetchedUser.accessToken,
      },
      message: 'Success refreshed tokens',
    ).toJson());
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
