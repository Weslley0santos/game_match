import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/core/session/user_session.dart';
import 'package:game_match/features/auth/screens/login_screen.dart';
import 'package:game_match/features/auth/screens/register_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(UserSession.clear);

  testWidgets('login displays username and password errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o nome de usuário'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('registration displays two required field errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    expect(find.text('Informe o nome de usuário'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('registration posts username and returns to login on success', (tester) async {
    var requestBody = <String, dynamic>{};
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => Scaffold(body: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Abrir cadastro'),
        ))),
      ));
      await tester.tap(find.text('Abrir cadastro'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '  Jogador_27 ');
      await tester.enterText(find.byType(TextFormField).at(1), ' senha com espaço ');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('Cadastro realizado com sucesso'), findsOneWidget);
      expect(find.text('Abrir cadastro'), findsOneWidget);
    }, () => MockClient((request) async {
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{"id":42,"name":"jogador_27","username":"jogador_27"}', 200);
    }));
    expect(requestBody, {'username': 'Jogador_27', 'password': ' senha com espaço '});
  });

  testWidgets('registration shows a specific duplicate username message', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
        child: const Text('Abrir cadastro'),
      )))));
      await tester.tap(find.text('Abrir cadastro'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Jogador');
      await tester.enterText(find.byType(TextFormField).at(1), 'senha');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('Esse nome de usuário já está em uso'), findsOneWidget);
      expect(find.text('detalhe interno do servidor'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    }, () => MockClient((_) async => http.Response(
      '{"message":"detalhe interno do servidor"}', 409,
    )));
  });

  testWidgets('login authenticates and keeps username and token in session', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), ' Jogador_27 ');
      await tester.enterText(find.byType(TextFormField).at(1), 'senha');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(UserSession.userId, 42);
      expect(UserSession.username, 'jogador_27');
      expect(UserSession.accessToken, 'jwt-token');
      expect(UserSession.isLogged, isTrue);
      expect(find.text('Entrar'), findsNothing);
    }, () => MockClient((request) async {
      if (request.url.path == '/users/login') {
        return http.Response(
          '{"id":42,"name":"Jogador","username":"jogador_27","accessToken":"jwt-token"}', 200,
        );
      }
      return http.Response('[]', 200);
    }));
  });

  testWidgets('login rejects invalid credentials without creating a session', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), 'Jogador');
      await tester.enterText(find.byType(TextFormField).at(1), 'senha');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Nome de usuário ou senha inválidos'), findsOneWidget);
      expect(UserSession.isLogged, isFalse);
      expect(find.text('detalhe interno do servidor'), findsNothing);
      final passwordField = tester.widget<EditableText>(find.byType(EditableText).last);
      expect(passwordField.obscureText, isTrue);
    }, () => MockClient((_) async => http.Response(
      '{"message":"detalhe interno do servidor"}', 401,
    )));
  });

  for (final (status, message) in [
    (429, 'Muitas tentativas de login. Aguarde antes de tentar novamente.'),
    (500, 'O servidor está temporariamente indisponível. Tente novamente.'),
    (503, 'O servidor está temporariamente indisponível. Tente novamente.'),
  ]) {
    testWidgets('login shows a retryable message for HTTP $status', (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.enterText(find.byType(TextFormField).at(0), 'Jogador');
        await tester.enterText(find.byType(TextFormField).at(1), 'senha');
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        expect(find.text('Nome de usuário ou senha inválidos'), findsNothing);
        expect(find.text('Entrar'), findsOneWidget);
        expect(UserSession.isLogged, isFalse);
      }, () => MockClient((_) async => http.Response('{}', status)));
    });
  }

  testWidgets('login reports a connection problem after the request times out', (tester) async {
    final response = Completer<http.Response>();
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), 'Jogador');
      await tester.enterText(find.byType(TextFormField).at(1), 'senha');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível conectar ao servidor. Tente novamente em instantes.'),
        findsOneWidget,
      );
      expect(find.text('Nome de usuário ou senha inválidos'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
      expect(UserSession.isLogged, isFalse);
      response.complete(http.Response(
        '{"id":42,"name":"Jogador","username":"jogador","accessToken":"late-token"}',
        200,
      ));
      await tester.pump();
      expect(UserSession.isLogged, isFalse);
      expect(find.text('Entrar'), findsOneWidget);
    }, () => MockClient((_) => response.future));
  });
}
