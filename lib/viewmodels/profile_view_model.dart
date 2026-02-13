import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();

  UserProfile? _userProfile;
  bool _isLoading = true;

  UserProfile? get user => _userProfile;
  bool get isLoading => _isLoading;
  bool get hasProfile => _userProfile != null;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    final profileJson = await _storage.loadProfile();
    if (profileJson != null) {
      _userProfile = UserProfile.fromJson(profileJson);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserProfile(UserProfile newUser) async {
    _userProfile = newUser;
    await _storage.saveProfile(newUser.toJson());
    notifyListeners();
  }
}
