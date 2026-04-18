import 'package:equity_echo/domain/models/user_entity.dart';

abstract class AuthService {
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity?> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  UserEntity? get currentUser;
  Stream<UserEntity?> get authStateChanges;

  /// Returns true if the currently signed-in user was authenticated with
  /// email and password (and can therefore be re-authenticated with a
  /// password).
  bool get currentUserHasPassword;

  /// Re-authenticate the currently signed-in user to confirm sensitive
  /// operations. For password-based accounts provide [password]; for
  /// Google-linked accounts the current credential is re-verified silently.
  /// Throws [AuthException] on failure.
  Future<void> reauthenticate({String? password});
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
