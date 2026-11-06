import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  // Current authenticated user
  User? get user => _user;

  // Check whether a user is logged in
  bool get isAuthenticated => _user != null;

  // Loading state
  bool get isLoading => _isLoading;

  // Check whether Firebase authentication has initialized
  bool get isInitialized => _isInitialized;

  // Register a new user
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
    } finally {
      _setLoading(false);
    }
  }

  // Update the current user's display name
  Future<void> updateProfile({required String name}) async {
    _setLoading(true);

    try {
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found.');
      }

      await currentUser.updateDisplayName(name.trim());
      await currentUser.reload();

      _user = _authService.currentUser;

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Change the current user's password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } finally {
      _setLoading(false);
    }
  }

  // Login an existing user
  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);

    try {
      await _authService.signIn(email: email, password: password);
    } finally {
      _setLoading(false);
    }
  }

  // Logout the current user
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
