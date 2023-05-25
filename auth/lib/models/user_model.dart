import 'package:conduit_core/conduit_core.dart';

/// @Column - settings for fields in db
/// omitByDefault - omit this field for response


/// @Serialize - serialize configuration
/// input: true - enable serialization if this field is input 
/// output: false - disable serialization if this field is output (disable this field in response)
class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;
  @Column(unique: true, indexed: true)
  String? username;
  @Serialize(input: true, output: false)
  String? password;
  @Column(unique: true, indexed: true)
  String? email;
  @Column(nullable: true)
  String? accessToken;
  @Column(nullable: true)
  String? refreshToken;
  @Column(omitByDefault: true)
  String? salt;
  @Column(omitByDefault: true)
  String? hashPassword;
}
