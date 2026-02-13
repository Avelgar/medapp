import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/auth_data.dart';
import '../services/storage_service.dart';
import '../main.dart';

class AuthViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();

  AuthData? _authData;
  bool _isLoading = true;

  AuthData? get auth => _authData;
  bool get isLoggedIn => _authData != null;
  bool get isLoading => _isLoading;

  bool get isPremium {
    if (_authData == null) return false;
    final role = _authData!.role;
    return role == 'Premium' || role == 'Admin';
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final authJson = await _storage.loadAuth();
    if (authJson != null) {
      _authData = AuthData.fromJson(authJson);
      await _validateTokenOnServer();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String token, String role) async {
    final newAuth = AuthData(email: email, token: token, role: role);
    _authData = newAuth;
    await _storage.saveAuth(newAuth.toJson());
    notifyListeners();
  }

  Future<void> logout() async {
    _authData = null;
    await _storage.clearAuth();
    notifyListeners();
  }

  Future<void> _validateTokenOnServer() async {
    if (_authData == null) return;

    try {
      final url = Uri.parse(
        'https://health-sync.online/registration/api/validate_token',
      );
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_authData!.token}',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newRole = data['role'];
        final newEmail = data['email'];

        if (newRole != _authData!.role || newEmail != _authData!.email) {
          await login(newEmail, _authData!.token, newRole);
        }

        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("С возвращением, $newEmail!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text("Сессия истекла. Войдите снова."),
            backgroundColor: Colors.red,
          ),
        );
        await logout();
      }
    } catch (e) {
      debugPrint("Ошибка проверки токена: $e");
    }
  }
}
