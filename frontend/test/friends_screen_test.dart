import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/core/session/user_session.dart';
import 'package:game_match/features/friends/screens/friends_screen.dart';
import 'package:http/http.dart' as http;

import 'helpers/screen_test_data.dart';

void main() {
  setUp(() {
    UserSession.setUser({
      'id': screenTestUserId,
      'name': 'Jogador',
      'username': 'jogador_27',
      'accessToken': 'friends-widget-test-token',
    });
  });

  tearDown(UserSession.clear);

  testWidgets('exibe carregamento enquanto consulta os dados sociais', (
    tester,
  ) async {
    final usersResponse = Completer<http.Response>();
    final api = friendsScreenApi(
      override: (request) =>
          request.url.path == '/users' ? usersResponse.future : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      usersResponse.complete(jsonScreenResponse([screenUser()]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Você ainda não tem amigos aceitos'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('mostra estado de erro se falhar o carregamento inicial', (
    tester,
  ) async {
    final api = friendsScreenApi(
      override: (request) => request.url.path == '/users'
          ? jsonScreenResponse({'message': 'offline'}, status: 500)
          : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível carregar amigos'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('mostra estados vazios de amigos e solicitações', (tester) async {
    final api = friendsScreenApi(
      users: [screenUser(id: screenTestUserId, name: 'Jogador')],
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Você ainda não tem amigos aceitos'), findsOneWidget);

      await tester.tap(find.text('Solicitações'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Você não tem solicitações pendentes'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.textContaining('Nenhum usuário encontrado'), findsOneWidget);
    });
  });

  testWidgets('busca filtra outros usuários pelo nome', (tester) async {
    final api = friendsScreenApi(
      users: [
        screenUser(id: screenTestUserId, name: 'Jogador'),
        screenUser(id: 78, name: 'Bia'),
        screenUser(id: 79, name: 'Bruno'),
      ],
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitações'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bi');
      await tester.pumpAndSettle();
      expect(find.text('Bia'), findsOneWidget);
      expect(find.text('Bruno'), findsNothing);
      expect(find.text('Jogador'), findsNothing);
    });
  });

  testWidgets('envia solicitação e apresenta confirmação', (tester) async {
    final api = friendsScreenApi(
      users: [screenUser()],
      override: (request) =>
          request.method == 'POST' && request.url.path == '/friendships'
              ? jsonScreenResponse({'id': 57, 'status': 'PENDING'}, status: 201)
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitações'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bia');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitar amizade'));
      await tester.pumpAndSettle();

      expect(find.text('Solicitação de amizade enviada.'), findsOneWidget);
      expect(find.text('Solicitação enviada'), findsOneWidget);
      expect(
        api.requests.any(
          (request) =>
              request.method == 'POST' &&
              request.url.path == '/friendships' &&
              request.url.queryParameters['friendId'] == '$screenTestFriendId',
        ),
        isTrue,
      );
    });
  });

  testWidgets('mantém ação disponível e mostra erro ao falhar solicitação', (
    tester,
  ) async {
    final api = friendsScreenApi(
      users: [screenUser()],
      override: (request) =>
          request.method == 'POST' && request.url.path == '/friendships'
              ? jsonScreenResponse({'message': 'conflict'}, status: 409)
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitações'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bia');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitar amizade'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível enviar'), findsOneWidget);
      expect(find.text('Solicitar amizade'), findsOneWidget);
    });
  });

  for (final action in ['Aceitar', 'Recusar']) {
    testWidgets('atualiza solicitação pendente ao $action', (tester) async {
      var isPending = true;
      var isAccepted = false;
      final api = friendsScreenApi(
        override: (request) {
          if (request.method == 'GET' &&
              request.url.path == '/friendships/$screenTestUserId/pending') {
            return jsonScreenResponse(isPending ? [screenPendingRequest()] : []);
          }
          if (request.method == 'GET' &&
              request.url.path == '/friendships/$screenTestUserId') {
            return jsonScreenResponse(isAccepted ? [screenFriendship()] : []);
          }
          final endpoint = action == 'Aceitar' ? 'accept' : 'reject';
          if (request.method == 'PUT' &&
              request.url.path == '/friendships/56/$endpoint') {
            isPending = false;
            isAccepted = action == 'Aceitar';
            return jsonScreenResponse({'status': isAccepted ? 'ACCEPTED' : 'REJECTED'});
          }
          return null;
        },
      );

      await api.run(() async {
        await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Solicitações'));
        await tester.pumpAndSettle();
        expect(find.text('Bia'), findsOneWidget);

        await tester.tap(find.byTooltip(action));
        await tester.pumpAndSettle();

        expect(find.textContaining('Você não tem solicitações pendentes'), findsOneWidget);
        expect(
          find.text(action == 'Aceitar' ? 'Amizade aceita.' : 'Amizade recusada.'),
          findsOneWidget,
        );
        expect(
          api.requests.any(
            (request) => request.url.path ==
                '/friendships/56/${action == 'Aceitar' ? 'accept' : 'reject'}',
          ),
          isTrue,
        );
      });
    });
  }

  testWidgets('mostra estado vazio quando amigos não têm jogos em comum', (
    tester,
  ) async {
    final api = friendsScreenApi(acceptedFriends: [screenFriendship()]);

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bia'));
      await tester.pumpAndSettle();

      expect(find.text('Jogos em comum com Bia'), findsOneWidget);
      expect(find.textContaining('Nenhum jogo em comum encontrado'), findsOneWidget);
    });
  });

  testWidgets('exibe jogos compatíveis e envia convite para o amigo', (
    tester,
  ) async {
    final sentInvites = <Map<String, dynamic>>[];
    final api = friendsScreenApi(
      acceptedFriends: [screenFriendship()],
      matchesByFriend: {
        screenTestFriendId: [screenMatch()],
      },
      sentInvites: sentInvites,
      override: (request) {
        if (request.method == 'POST' && request.url.path == '/play-invites') {
          final invite = screenInvite(
            senderId: screenTestUserId,
            senderName: 'Jogador',
            receiverId: screenTestFriendId,
            receiverName: 'Bia',
          );
          sentInvites.add(invite);
          return jsonScreenResponse(invite, status: 201);
        }
        return null;
      },
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bia'));
      await tester.pumpAndSettle();

      expect(find.text('Portal 2'), findsOneWidget);
      expect(find.text('Quer jogar'), findsOneWidget);
      await tester.tap(find.text('Convidar para jogar'));
      await tester.pumpAndSettle();

      expect(find.text('Convite para jogar enviado.'), findsOneWidget);
      expect(
        api.requests.any(
          (request) =>
              request.method == 'POST' &&
              request.url.path == '/play-invites' &&
              request.url.queryParameters['receiverId'] == '$screenTestFriendId' &&
              request.url.queryParameters['gameId'] == '$screenTestGameId',
        ),
        isTrue,
      );
      expect(find.text('Convite enviado'), findsOneWidget);
    });
  });

  testWidgets('mantém ação disponível e mostra erro se envio de convite falha', (
    tester,
  ) async {
    final api = friendsScreenApi(
      acceptedFriends: [screenFriendship()],
      matchesByFriend: {
        screenTestFriendId: [screenMatch()],
      },
      override: (request) =>
          request.method == 'POST' && request.url.path == '/play-invites'
              ? jsonScreenResponse({'message': 'conflict'}, status: 500)
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Convidar para jogar'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível enviar o convite.'), findsOneWidget);
      expect(find.text('Convite para jogar enviado.'), findsNothing);
      expect(find.text('Convidar para jogar'), findsOneWidget);
    });
  });
}
