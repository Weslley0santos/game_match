import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/core/session/user_session.dart';
import 'package:game_match/features/swipe/screens/swipe_screen.dart';
import 'package:http/http.dart' as http;

import 'helpers/screen_test_data.dart';

void main() {
  const completedMessage = 'Você já avaliou todos os jogos disponíveis.';
  const loadError =
      'Não foi possível carregar a lista de jogos para avaliação.';
  final game = {
    'id': screenTestGameId,
    'title': 'Portal 2',
    'imageUrl': '',
  };

  setUp(() {
    UserSession.setUser({'id': screenTestUserId});
  });

  tearDown(UserSession.clear);

  testWidgets('mostra erro de catálogo e recupera após tentar novamente', (
    tester,
  ) async {
    final retryResponse = Completer<http.Response>();
    var catalogRequests = 0;
    final api = ScreenTestApi((request) async {
      if (request.url.path == '/games') {
        if (++catalogRequests == 1) throw http.ClientException('Offline');
        return retryResponse.future;
      }
      expect(request.url.path, '/ratings/user/$screenTestUserId');
      return jsonScreenResponse([]);
    });

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: SwipeScreen()));
      await tester.pumpAndSettle();

      expect(find.text(loadError), findsOneWidget);
      expect(find.text(completedMessage), findsNothing);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(loadError), findsNothing);

      retryResponse.complete(jsonScreenResponse([game]));
      await tester.pumpAndSettle();

      expect(find.text('Portal 2'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
      expect(catalogRequests, 2);
    });
  });

  testWidgets('preserva conclusão e modo de reinício ao repetir após erro', (
    tester,
  ) async {
    var catalogRequests = 0;
    var ratingsRequests = 0;
    final api = ScreenTestApi((request) {
      if (request.url.path == '/games') {
        if (++catalogRequests == 2) return jsonScreenResponse({}, status: 503);
        return jsonScreenResponse([game]);
      }
      expect(request.url.path, '/ratings/user/$screenTestUserId');
      ratingsRequests++;
      return jsonScreenResponse([
        {'gameId': screenTestGameId, 'type': 'LIKE'},
      ]);
    });

    await api.run(() async {
      await tester.pumpWidget(const MaterialApp(home: SwipeScreen()));
      await tester.pumpAndSettle();

      expect(find.text(completedMessage), findsOneWidget);
      expect(find.text(loadError), findsNothing);

      await tester.tap(find.text('Reiniciar avaliação'));
      await tester.pumpAndSettle();
      expect(find.text(loadError), findsOneWidget);
      expect(find.text(completedMessage), findsNothing);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Portal 2'), findsOneWidget);
      expect(ratingsRequests, 1);
    });
  });
}
