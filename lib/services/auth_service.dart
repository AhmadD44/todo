import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_repository.dart';

/// Wraps Firebase email/password authentication.
class AuthService {
  AuthService._();

  // Resolved lazily so nothing throws if Firebase failed to initialise.
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Null-safe even when Firebase isn't ready (returns null instead of throwing).
  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? get uid => currentUser?.uid;

  /// Emits the signed-in user (or null) whenever auth state changes.
  static Stream<User?> authState() {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream<User?>.empty();
    }
  }

  /// Create an account, set the display name, and seed the user's doc.
  static Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(cred.user!.uid)
        .set({
      'email': email.trim(),
      'displayName': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Send the verification email right after signup.
    await cred.user?.sendEmailVerification();
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  static Future<void> signOut() => _auth.signOut();

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // --- Account management ---
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  static Future<void> reloadUser() => _auth.currentUser?.reload() ?? Future.value();

  static Future<void> sendEmailVerification() =>
      _auth.currentUser?.sendEmailVerification() ?? Future.value();

  static Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'displayName': name.trim()}, SetOptions(merge: true));
    await user.reload();
  }

  /// Re-authenticates then changes the password (Firebase requires a recent
  /// login for sensitive operations).
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  /// Deletes the account: removes the user's Firestore data, then the auth user
  /// (after re-authentication).
  static Future<void> deleteAccount(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await UserRepository.deleteAllUserData(user.uid);
    await user.delete();
  }

  /// Turns Firebase error codes into friendly, on-brand messages.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address doesn\'t look right.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'That email already has an account — try logging in.';
        case 'weak-password':
          return 'Please choose a stronger password (6+ characters).';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and retry.';
        default:
          return e.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
