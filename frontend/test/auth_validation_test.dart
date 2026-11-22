import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/features/auth/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('requires a username', () {
      for (final username in [null, '', '   ']) {
        expect(AuthValidators.validateUsername(username), 'Informe o nome de usuário');
      }
    });

    test('accepts trimmed ASCII usernames from 3 to 32 characters', () {
      expect(AuthValidators.validateUsername('  Ab_09  '), isNull);
      expect(AuthValidators.validateUsername('a_b'), isNull);
      expect(AuthValidators.validateUsername(List.filled(32, 'a').join()), isNull);
    });

    test('rejects usernames outside the allowed length and character set', () {
      for (final username in [
        'ab',
        List.filled(33, 'a').join(),
        'joão',
        'nome de usuario',
        'a-b',
        'a.b',
      ]) {
        expect(AuthValidators.validateUsername(username), 'Use 3 a 32 letras, números ou _');
      }
    });

    test('requires password and enforces BCrypt UTF-8 byte limit without truncation', () {
      expect(AuthValidators.validatePassword(null), 'Informe a senha');
      expect(AuthValidators.validatePassword(''), 'Informe a senha');
      expect(AuthValidators.validatePassword('   '), 'Informe a senha');
      expect(AuthValidators.validatePassword(List.filled(72, 'x').join()), isNull);
      expect(
        AuthValidators.validatePassword(List.filled(73, 'x').join()),
        'A senha deve ter no máximo 72 bytes',
      );
      expect(AuthValidators.validatePassword(List.filled(36, 'é').join()), isNull);
      expect(
        AuthValidators.validatePassword(List.filled(37, 'é').join()),
        'A senha deve ter no máximo 72 bytes',
      );
    });
  });
}
