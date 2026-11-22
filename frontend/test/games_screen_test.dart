import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/core/session/user_session.dart';
import 'package:game_match/features/games/screens/games_screen.dart';
import 'package:http/http.dart' as http;

import 'helpers/screen_test_data.dart';

void main() {
  setUp(() {
    UserSession.setUser({
      'id': screenTestUserId,
      'name': 'Jogador',
      'username': 'jogador_27',
      'accessToken': 'games-widget-test-token',
    });
  });

  tearDown(UserSession.clear);

  testWidgets('cabecalho identifica o jogo selecionado alem do nome', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameDetailHeader(
            title: 'Hogwarts Legacy',
            imageUrl: 'https://example.com/hogwarts.jpg',
            compatibleFriends: 3,
            favoriteFriends: 1,
          ),
        ),
      ),
    );

    expect(find.text('Hogwarts Legacy'), findsOneWidget);
    expect(find.text('3 amigos interessados · 1 quer jogar'), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;
    expect(provider.url, 'https://example.com/hogwarts.jpg');
  });
  testWidgets('exibe carregamento enquanto busca jogos compatíveis', (
    tester,
  ) async {
    final gamesResponse = Completer<http.Response>();
    final api = gamesScreenApi(
      override: (request) =>
          request.url.path == '/matches/users/$screenTestUserId/games'
              ? gamesResponse.future
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gamesResponse.complete(jsonScreenResponse([screenCompatibleGame()]));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Portal 2'), findsOneWidget);
    });
  });

  testWidgets('mostra erro se falhar ao carregar compatibilidade', (
    tester,
  ) async {
    final api = gamesScreenApi(
      override: (request) =>
          request.url.path == '/matches/users/$screenTestUserId/games'
              ? jsonScreenResponse({'message': 'offline'}, status: 500)
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Não foi possível carregar jogos compatíveis'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('mostra jogos compatíveis vazios e convites sem itens', (
    tester,
  ) async {
    final api = gamesScreenApi();

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nenhum jogo compatível encontrado ainda'),
        findsOneWidget,
      );

      await tester.tap(find.textContaining('Convites'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum convite recebido no momento.'), findsOneWidget);
      expect(find.text('Nenhum convite enviado ainda.'), findsOneWidget);
    });
  });

  testWidgets('mostra erro de convites sem esconder estados vazios', (
    tester,
  ) async {
    final api = gamesScreenApi(
      override: (request) =>
          request.url.path == '/play-invites/$screenTestUserId/received'
              ? jsonScreenResponse({'message': 'offline'}, status: 500)
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Convites'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar convites.'), findsOneWidget);
      expect(find.text('Nenhum convite recebido no momento.'), findsOneWidget);
    });
  });

  testWidgets('separa amigos que gostaram dos que querem jogar', (
    tester,
  ) async {
    final api = gamesScreenApi(
      games: [screenCompatibleGame()],
      interestedFriendsByGame: {
        screenTestGameId: [
          screenInterestedFriend(interestType: 'LIKE'),
          screenInterestedFriend(friendId: 79, friendName: 'Caio'),
        ],
      },
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portal 2'));
      await tester.pumpAndSettle();

      expect(find.text('Gostaram'), findsOneWidget);
      expect(find.text('Querem jogar'), findsOneWidget);
      expect(find.text('Bia'), findsOneWidget);
      expect(find.text('Caio'), findsOneWidget);
      expect(find.text('Gostou'), findsOneWidget);
      expect(find.text('Quer jogar'), findsOneWidget);
    });
  });

  testWidgets('mostra estado vazio para jogo sem amigos interessados', (
    tester,
  ) async {
    final api = gamesScreenApi(games: [screenCompatibleGame()]);

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portal 2'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nenhum amigo interessado encontrado'),
        findsOneWidget,
      );
    });
  });

  for (final action in ['Aceitar', 'Recusar']) {
    testWidgets('atualiza o convite recebido após $action', (tester) async {
      final receivedInvite = screenInvite();
      final endpoint = action == 'Aceitar' ? 'accept' : 'reject';
      final api = gamesScreenApi(
        receivedInvites: [receivedInvite],
        override: (request) {
          if (request.method == 'PUT' &&
              request.url.path == '/play-invites/90/$endpoint') {
            receivedInvite['status'] =
                action == 'Aceitar' ? 'ACCEPTED' : 'REJECTED';
            return jsonScreenResponse(receivedInvite);
          }
          return null;
        },
      );

      await api.run(() async {
        await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Convites'));
        await tester.pumpAndSettle();
        expect(find.text('Portal 2'), findsOneWidget);

        await tester.tap(find.text(action));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            action == 'Aceitar' ? 'Status: Aceito' : 'Status: Recusado',
          ),
          findsOneWidget,
        );
        expect(
          api.requests.any((request) => request.url.path == '/play-invites/90/$endpoint'),
          isTrue,
        );
      });
    });
  }

  for (final action in ['Aceitar', 'Recusar']) {
    testWidgets('mantém convite pendente e mostra erro ao $action falhar', (
      tester,
    ) async {
      final endpoint = action == 'Aceitar' ? 'accept' : 'reject';
      final errorText = action == 'Aceitar'
          ? 'Não foi possível aceitar o convite.'
          : 'Não foi possível recusar o convite.';
      final api = gamesScreenApi(
        receivedInvites: [screenInvite()],
        override: (request) =>
            request.method == 'PUT' &&
                    request.url.path == '/play-invites/90/$endpoint'
                ? jsonScreenResponse({'message': 'offline'}, status: 500)
                : null,
      );

      await api.run(() async {
        await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Convites'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(action));
        await tester.pumpAndSettle();

        expect(find.text(errorText), findsOneWidget);
        expect(find.textContaining('Status: Pendente'), findsOneWidget);
        expect(find.text(action), findsOneWidget);
        expect(find.text('Convite para jogar aceito.'), findsNothing);
        expect(find.text('Convite para jogar recusado.'), findsNothing);
      });
    });
  }

  testWidgets('envia convite a amigo interessado e mostra status', (
    tester,
  ) async {
    final sentInvites = <Map<String, dynamic>>[];
    final api = gamesScreenApi(
      games: [screenCompatibleGame()],
      interestedFriendsByGame: {
        screenTestGameId: [screenInterestedFriend()],
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
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portal 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Convidar para jogar'));
      await tester.pumpAndSettle();

      expect(find.text('Convite para jogar enviado.'), findsOneWidget);
      expect(find.text('Convite enviado'), findsOneWidget);
      expect(
        api.requests.any(
          (request) =>
              request.method == 'POST' &&
              request.url.path == '/play-invites' &&
              request.url.queryParameters['receiverId'] ==
                  '$screenTestFriendId' &&
              request.url.queryParameters['gameId'] == '$screenTestGameId',
        ),
        isTrue,
      );

      await tester.tap(find.text('Convites'));
      await tester.pumpAndSettle();

      expect(find.text('Portal 2'), findsOneWidget);
      expect(find.text('Para: Bia'), findsOneWidget);
    });
  });

  testWidgets('usa ícone de fallback se a capa do jogo falhar', (
    tester,
  ) async {
    final api = gamesScreenApi(
      games: [screenCompatibleGame(imageUrl: 'https://invalid.example/game.jpg')],
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Portal 2'), findsOneWidget);
      expect(find.byIcon(Icons.games), findsOneWidget);
    });
  });

  testWidgets('mantém ação disponível e mostra erro se envio de convite falha', (
    tester,
  ) async {
    final api = gamesScreenApi(
      games: [screenCompatibleGame()],
      interestedFriendsByGame: {
        screenTestGameId: [screenInterestedFriend()],
      },
      override: (request) =>
          request.method == 'POST' && request.url.path == '/play-invites'
              ? jsonScreenResponse({'message': 'conflict'}, status: 500)
              : null,
    );

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: GamesScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portal 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Convidar para jogar'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível enviar o convite.'), findsOneWidget);
      expect(find.text('Convite para jogar enviado.'), findsNothing);
      expect(find.text('Convidar para jogar'), findsOneWidget);
    });
  });
}
