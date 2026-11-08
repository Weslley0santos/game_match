import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/features/auth/screens/login_screen.dart';
import 'package:game_match/features/auth/screens/register_screen.dart';

void main() {
  testWidgets('login displays required field errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o email'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('registration displays required field errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe o email'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('registration rejects a malformed email address', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), 'Jogador');
    await tester.enterText(find.byType(TextFormField).at(1), 'jogador@example..com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha');

    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    expect(find.text('Informe um email válido'), findsOneWidget);
  });

  testWidgets('login rejects a malformed email address', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), '.jogador@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha');

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um email válido'), findsOneWidget);
  });
}
