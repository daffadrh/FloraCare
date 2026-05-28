import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';

class AuthService {
  final _mockController = StreamController<AppUser?>.broadcast();
  AppUser? _mockUser;

  AuthService() {
    // If not using Firebase, initialize mock auth state
    if (!_isFirebaseAvailable) {
      _mockController.add(null);
    }
  }

  // Check if Firebase was successfully initialized
  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Get current user
  AppUser? get currentUser {
    if (_isFirebaseAvailable) {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      return user != null ? AppUser(uid: user.uid, email: user.email ?? '') : null;
    } else {
      return _mockUser;
    }
  }

  // Stream of auth changes
  Stream<AppUser?> get onAuthStateChanged {
    if (_isFirebaseAvailable) {
      return fb_auth.FirebaseAuth.instance.authStateChanges().map((user) {
        return user != null ? AppUser(uid: user.uid, email: user.email ?? '') : null;
      });
    } else {
      return _mockController.stream;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final user = credential.user;
        return user != null ? AppUser(uid: user.uid, email: user.email ?? '') : null;
      } on fb_auth.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'An error occurred during sign in.');
      }
    } else {
      // Mock Sign In: Accept any login, simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty.');
      }
      _mockUser = AppUser(uid: 'mock_uid_${email.hashCode}', email: email);
      _mockController.add(_mockUser);
      return _mockUser;
    }
  }

  // Sign up with email and password
  Future<AppUser?> signUpWithEmailAndPassword(String email, String password) async {
    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final user = credential.user;
        return user != null ? AppUser(uid: user.uid, email: user.email ?? '') : null;
      } on fb_auth.FirebaseAuthException catch (e) {
        throw Exception(e.message ?? 'An error occurred during registration.');
      }
    } else {
      // Mock Sign Up: Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long.');
      }
      _mockUser = AppUser(uid: 'mock_uid_${email.hashCode}', email: email);
      _mockController.add(_mockUser);
      return _mockUser;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      await fb_auth.FirebaseAuth.instance.signOut();
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockUser = null;
      _mockController.add(null);
    }
  }
}
