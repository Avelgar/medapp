import 'dart:convert';

class AuthData {
  String email;
  String token;
  String role;

  AuthData({required this.email, required this.token, required this.role});

  String toJson() => jsonEncode({'email': email, 'token': token, 'role': role});

  factory AuthData.fromJson(String source) {
    final map = jsonDecode(source);
    return AuthData(
      email: map['email'],
      token: map['token'],
      role: map['role'],
    );
  }
}
