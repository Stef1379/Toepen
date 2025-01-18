import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/cupertino.dart';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<String> signInWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return '';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
        case 'wrong-password':
        case 'invalid-credential':
          return AppLocalizations.of(context)!.errorIncorrectCredentials;
        case 'user-disabled':
          return AppLocalizations.of(context)!.errorUserDisabled;
        default:
          debugPrint(AppLocalizations.of(context)!.errorGeneric(e.message ?? ''));
          return AppLocalizations.of(context)!.errorGeneric(e.message ?? '');
      }
    }
  }

  Future<String> registerWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return '';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return AppLocalizations.of(context)!.errorEmailInUse;
        case 'invalid-email':
          return AppLocalizations.of(context)!.errorInvalidEmail;
        case 'weak-password':
          return AppLocalizations.of(context)!.errorWeakPassword;
        case 'operation-not-allowed':
          return AppLocalizations.of(context)!.errorOperationNotAllowed;
        default:
          debugPrint(AppLocalizations.of(context)!.errorGeneric(e.message ?? ''));
          return AppLocalizations.of(context)!.errorGeneric(e.message ?? '');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      /* Delay such that the display name is updated before any other operations are performed. */
      await Future.delayed(const Duration(milliseconds: 500));
      await reloadUser();
    } catch (e) {
      debugPrint('Error updating display name: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }
}
