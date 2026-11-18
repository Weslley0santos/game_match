import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/features/swipe/controllers/swipe_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const userId = 17;

  Map<String, dynamic> game(int id, String title) => {
        'id': id,
        'title': title,
        'genre': 'RPG',
        'description': 'Game $id',
        'imageUrl': '',
        'platforms': ['PC'],
      };

  test('filtra jogos avaliados antes de exibir o catálogo', () async {
    await http.runWithClient(
      () async {
        final controller = SwipeController();

        await controller.loadGames(userId);

        expect(controller.games.map((item) => item.id), [1, 3]);
        expect(controller.currentGame?.title, 'Game 1');
      },
      () => MockClient((request) async {
        if (request.url.path == '/games') {
          return http.Response(jsonEncode([game(1, 'Game 1'), game(2, 'Game 2'), game(3, 'Game 3')]), 200);
        }
        if (request.url.path == '/ratings/user/$userId') {
          return http.Response(jsonEncode([{'gameId': 2, 'type': 'LIKE'}]), 200);
        }
        return http.Response('', 404);
      }),
    );
  });

  test('inclui jogos avaliados quando a avaliação é reiniciada', () async {
    var ratingsRequested = false;

    await http.runWithClient(
      () async {
        final controller = SwipeController();

        await controller.loadGames(userId, includeRatedGames: true);

        expect(controller.games.map((item) => item.id), [1, 2]);
        expect(ratingsRequested, isFalse);
      },
      () => MockClient((request) async {
        if (request.url.path == '/games') {
          return http.Response(jsonEncode([game(1, 'Game 1'), game(2, 'Game 2')]), 200);
        }
        if (request.url.path == '/ratings/user/$userId') {
          ratingsRequested = true;
        }
        return http.Response('', 404);
      }),
    );
  });

  test('registra o tipo de avaliação e avança após salvar', () async {
    final submittedTypes = <String>[];

    await http.runWithClient(
      () async {
        final controller = SwipeController();
        await controller.loadGames(userId, includeRatedGames: true);

        await controller.likeGame(userId);
        await controller.dislikeGame(userId);
        await controller.favoriteGame(userId);

        expect(submittedTypes, ['LIKE', 'DISLIKE', 'FAVORITE']);
        expect(controller.currentIndex, 3);
        expect(controller.likedGames.single.id, 1);
        expect(controller.dislikedGames.single.id, 2);
        expect(controller.favoriteGames.single.id, 3);
        expect(controller.finished, isTrue);
      },
      () => MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/games') {
          return http.Response(
            jsonEncode([game(1, 'Game 1'), game(2, 'Game 2'), game(3, 'Game 3')]),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/ratings') {
          submittedTypes.add(jsonDecode(request.body)['type'] as String);
          return http.Response('', 201);
        }
        return http.Response('', 404);
      }),
    );
  });

  final failedRatingActions = <String, Future<void> Function(SwipeController)>{
    'LIKE': (controller) => controller.likeGame(userId),
    'DISLIKE': (controller) => controller.dislikeGame(userId),
    'FAVORITE': (controller) => controller.favoriteGame(userId),
  };

  for (final entry in failedRatingActions.entries) {
    test('não registra ${entry.key} nem avança se salvar falhar', () async {
      await http.runWithClient(
        () async {
          final controller = SwipeController();
          await controller.loadGames(userId, includeRatedGames: true);

          await expectLater(entry.value(controller), throwsException);

          expect(controller.currentIndex, 0);
          expect(controller.likedGames, isEmpty);
          expect(controller.dislikedGames, isEmpty);
          expect(controller.favoriteGames, isEmpty);
          expect(controller.currentGame?.id, 1);
        },
        () => MockClient((request) async {
          if (request.method == 'GET' && request.url.path == '/games') {
            return http.Response(jsonEncode([game(1, 'Game 1')]), 200);
          }
          if (request.method == 'POST' && request.url.path == '/ratings') {
            return http.Response('', 500);
          }
          return http.Response('', 404);
        }),
      );
    });
  }
}
