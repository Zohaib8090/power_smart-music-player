import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Future<User?> login(String email, String password);
  Future<User?> register(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logout();
  User? get currentUser;
  Stream<User?> get authStateChanges;
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      // TODO: Handle specific Firebase errors (e.g. user-not-found, wrong-password)
      rethrow;
    }
  }

  @override
  Future<User?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      // TODO: Handle weak-password, email-already-in-use
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // TODO: Handle user-not-found
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}

// Keep a mock for testing or if Firebase is not setup
class MockAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return null; // Mock user
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User?> register(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
