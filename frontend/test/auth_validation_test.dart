import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/features/auth/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('rejects a missing or whitespace-only name', () {
      expect(AuthValidators.validateName(null), 'Informe o nome');
      expect(AuthValidators.validateName('   '), 'Informe o nome');
    });

    test('accepts a name after trimming surrounding whitespace', () {
      expect(AuthValidators.validateName('  Jogador  '), isNull);
    });

    test('requires an email address', () {
      for (final email in [null, '', '   ']) {
        expect(AuthValidators.validateEmail(email), 'Informe o email');
      }
    });

    test('rejects malformed email addresses', () {
      for (final email in [
        'sem-arroba',
        'jogador@',
        'jogador@example',
        'jogador @example.com',
        '.jogador@example.com',
        'jogador.@example.com',
        'jo..gador@example.com',
        'jogador@example..com',
        'jogador@-example.com',
        'jogador@example-.com',
        'jogador@exam_ple.com',
        'jogador,nome@example.com',
      ]) {
        expect(
          AuthValidators.validateEmail(email),
          'Informe um email válido',
          reason: 'email: $email',
        );
      }
    });

    test('accepts a well-formed email with surrounding whitespace', () {
      expect(AuthValidators.validateEmail('  jogador@example.com  '), isNull);
    });

    test('requires a password but does not impose an undocumented length rule', () {
      expect(AuthValidators.validatePassword(null), 'Informe a senha');
      expect(AuthValidators.validatePassword(''), 'Informe a senha');
      expect(AuthValidators.validatePassword('   '), 'Informe a senha');
      expect(AuthValidators.validatePassword('x'), isNull);
    });
  });
}
