import 'package:equity_echo/domain/models/user_entity.dart';

abstract class AuthService {
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity?> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  UserEntity? get currentUser;
  Stream<UserEntity?> get authStateChanges;
}
