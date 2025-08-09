import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<AuthResult> signUp(String email, String password) async {
    try {
      // Validate inputs
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }
      if (password.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters');
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send email verification
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }

      return AuthResult.success(result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Sign up error: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn(String email, String password) async {
    try {
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }
      if (password.isEmpty) {
        return AuthResult.failure('Password cannot be empty');
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult.success(result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Sign in error: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Reset password error: $e');
      return AuthResult.failure('Failed to send reset email');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user logged in');
      }

      await user.delete();
      return AuthResult.success(null, message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Delete account error: $e');
      return AuthResult.failure('Failed to delete account');
    }
  }

  // Private helper methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}

/// Result wrapper for auth operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(isSuccess: true, user: user, successMessage: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
