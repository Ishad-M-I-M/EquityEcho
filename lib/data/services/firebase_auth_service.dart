import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:equity_echo/core/services/auth_service.dart';
import 'package:equity_echo/domain/models/user_entity.dart';

class FirebaseAuthService implements AuthService {
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '779114244435-4aq3df7un2pc3hgqnhu43jsl8gl7agk3.apps.googleusercontent.com',
  );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleSignInInit;

  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );
  }

  UserEntity? _userFromFirebase(User? user) {
    if (user == null) return null;
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }

  @override
  UserEntity? get currentUser => _userFromFirebase(_firebaseAuth.currentUser);

  AuthException _handleException(dynamic e, [StackTrace? stackTrace]) {
    developer.log('Authentication Error', error: e, stackTrace: stackTrace);

    if (e is GoogleSignInException) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return AuthException('Sign-in was cancelled.');
      }
      return AuthException(e.description ?? 'Google sign-in failed.');
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return AuthException('The password provided is too weak.');
        case 'email-already-in-use':
          return AuthException('An account already exists for that email.');
        case 'user-not-found':
          return AuthException('No user found for that email.');
        case 'wrong-password':
          return AuthException('Incorrect password provided.');
        case 'invalid-email':
          return AuthException('The email address is not valid.');
        case 'invalid-credential':
          return AuthException(
            'The email or password you entered is incorrect.',
          );
        case 'network-request-failed':
          return AuthException(
            'Network error. Please check your internet connection.',
          );
        default:
          return AuthException(
            e.message ?? 'An unknown authentication error occurred.',
          );
      }
    }
    return AuthException(
      'An unknown authentication error occurred. Please try again later.',
    );
  }

  @override
  Future<UserEntity?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } catch (e, stackTrace) {
      throw _handleException(e, stackTrace);
    }
  }

  @override
  Future<UserEntity?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } catch (e, stackTrace) {
      throw _handleException(e, stackTrace);
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      return _userFromFirebase(userCredential.user);
    } catch (e, stackTrace) {
      throw _handleException(e, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore sign-out errors from Google (e.g., not signed in).
    }
    await _firebaseAuth.signOut();
  }

  @override
  bool get currentUserHasPassword {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  @override
  Future<void> reauthenticate({String? password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in.');
    }

    try {
      final hasPassword = user.providerData.any(
        (p) => p.providerId == 'password',
      );

      if (hasPassword) {
        if (password == null || password.isEmpty) {
          throw AuthException('Password is required to confirm this action.');
        }
        final credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return;
      }

      // Google-linked account — re-verify with a fresh Google credential.
      await _ensureGoogleSignInInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;
      throw _handleException(e, stackTrace);
    }
  }
}
