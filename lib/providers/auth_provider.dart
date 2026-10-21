import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthProvider({required this.apiService}) {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('tc_auth_user');
    final savedToken = prefs.getString('tc_mobile_api_token');

    // Only restore session if both user profile and token were explicitly saved
    if (userJson != null && userJson.isNotEmpty && savedToken != null && savedToken.trim().isNotEmpty) {
      try {
        _user = UserModel.fromJson(json.decode(userJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Error decoding cached user: $e');
      }

      // Refresh profile from server if token exists
      if (apiService.apiToken != null && apiService.apiToken!.isNotEmpty) {
        final res = await apiService.fetchMe();
        if (res != null && res['user'] != null) {
          _user = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
          await _saveUserLocally(_user!);
          notifyListeners();
        } else if (res != null && res['ok'] == false) {
          await logout();
        }
      }
    } else {
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled
      }

      final auth = await account.authentication;
      final res = await apiService.loginWithGoogle(
        email: account.email,
        idToken: auth.idToken,
        name: account.displayName,
        avatarUrl: account.photoUrl,
      );

      if (res != null && res['ok'] == true && res['user'] != null) {
        _user = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
        await _saveUserLocally(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['error'] ?? 'Google sign-in verification failed.';
      }
    } catch (e) {
      _errorMessage = 'Google sign-in error: $e';
      debugPrint('Google sign in exception: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.loginWithCredentials(
        username: username.trim(),
        password: password,
      );

      if (res != null && res['ok'] == true && res['user'] != null) {
        _user = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
        await _saveUserLocally(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['error'] ?? 'Invalid username or password.';
      }
    } catch (e) {
      _errorMessage = 'Login connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> continueAsDemoAgent({String role = 'tc_sales_agent'}) async {
    _user = UserModel(
      id: 999,
      name: 'Demo Agent Companion',
      email: 'demo@tripcosmos.co',
      username: 'demo_agent',
      role: role,
      roleLabel: role == 'administrator' ? 'Administrator' : 'Sales Representative',
      avatarUrl: '',
      permissions: const ['all'],
    );
    await apiService.setApiToken(AppConstants.defaultMobileToken);
    await _saveUserLocally(_user!);
    notifyListeners();
  }

  Future<void> _saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tc_auth_user', json.encode(user.toJson()));
  }

  Future<void> logout() async {
    _user = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tc_auth_user');
    await prefs.remove('tc_mobile_api_token');
    await apiService.setApiToken('');
    notifyListeners();
  }
}
