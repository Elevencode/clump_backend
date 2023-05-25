import 'package:auth/models/app_response_model.dart';
import 'package:auth/models/user_model.dart';
import 'package:conduit_core/conduit_core.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.username == null || user.password == null) {
      return Response.badRequest(
        body: AppResponseModel(message: 'Username and Password are required'),
      );
    }

    final User fetchedUser = User();
    return Response.ok(AppResponseModel(
      data: {
        'id': '0',
        'refreshToken': 'refreshToken',
        'accessToken': 'accessToken',
      },
      message: 'SignIn OK',
    ).toJson());
  }

  @Operation.put()
  Future<Response> signUp() async {
    return Response.ok(AppResponseModel(
      data: {
        'id': '0',
        'refreshToken': 'refreshToken',
        'accessToken': 'accessToken',
      },
      message: 'SignUp OK',
    ).toJson());
  }

  @Operation.post('refresh')
  Future<Response> refreshToken() async {
    return Response.unauthorized(body: AppResponseModel(error: 'token is not valid').toJson());
  }
}
