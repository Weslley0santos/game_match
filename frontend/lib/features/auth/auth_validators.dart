import 'dart:convert';

class AuthValidators {
  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_]{3,32}$');

  static String? validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Informe o nome de usuário';
    if (!_usernamePattern.hasMatch(username)) {
      return 'Use 3 a 32 letras, números ou _';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe a senha';
    if (utf8.encode(value).length > 72) {
      return 'A senha deve ter no máximo 72 bytes';
    }
    return null;
  }
}
