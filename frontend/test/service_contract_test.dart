import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/core/config/api_config.dart';
import 'package:game_match/core/session/user_session.dart';
import 'package:game_match/data/services/friendship_service.dart';
import 'package:game_match/data/services/match_service.dart';
import 'package:game_match/data/services/play_invite_service.dart';
import 'package:game_match/data/services/rating_service.dart';
import 'package:game_match/data/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef _Call = Future<dynamic> Function();

void main() {
  setUp(() {
    UserSession.clear();
    UserSession.setUser({
      'id': 12,
      'name': 'Jogador',
      'username': 'jogador_27',
      'accessToken': 'contract-test-token',
    });
  });
  tearDown(UserSession.clear);

  test('session exposes username and token-backed identity', () {
    expect(UserSession.getUser(), {
      'id': 12,
      'name': 'Jogador',
      'username': 'jogador_27',
    });
  });

  test('registration posts to the local or configured API', () async {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    const registration = {
      'username': 'Jogador_27',
      'password': 'test-password',
    };
    const createdUser = {
      'id': 42,
      'name': 'jogador_27',
      'username': 'jogador_27',
    };

    late http.Request sent;
    final result = await http.runWithClient(
      () => UserService().createUser(
        registration['username']!,
        registration['password']!,
      ),
      () => MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode(createdUser), 200);
      }),
    );

    expect(sent.method, 'POST');
    expect(
      sent.url,
      configuredUrl.isEmpty
          ? Uri.http(kIsWeb ? 'localhost:8080' : '10.0.2.2:8080', '/users')
          : Uri.parse(configuredUrl.endsWith('/')
              ? '${configuredUrl}users'
              : '$configuredUrl/users'),
    );
    expect(jsonDecode(sent.body), registration);
    expect(result, createdUser);
  });

  test('login posts username and password and decodes token response', () async {
    const credentials = {'username': 'Jogador_27', 'password': 'secret'};
    const authenticated = {
      'id': 42,
      'name': 'jogador_27',
      'username': 'jogador_27',
      'accessToken': 'jwt-token',
    };
    late http.Request sent;
    final result = await http.runWithClient(
      () => UserService().login(credentials['username']!, credentials['password']!),
      () => MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode(authenticated), 200);
      }),
    );
    expect(sent.method, 'POST');
    expect(sent.url, Uri.parse('${ApiConfig.baseUrl}/users/login'));
    expect(jsonDecode(sent.body), credentials);
    expect(result, authenticated);
  });

  test('duplicate username returns a safe specific error', () async {
    await expectLater(
      http.runWithClient(
        () => UserService().createUser('Jogador', 'secret'),
        () => MockClient((_) async => http.Response('{"message":"secret"}', 409)),
      ),
      throwsA(isA<UsernameUnavailableException>()),
    );
  });

  const rating = {'id': 91, 'userId': 12, 'gameId': 34, 'type': 'LIKE'};
  const friendship = {
    'id': 56,
    'userId': 12,
    'userName': 'Jogador',
    'friendId': 78,
    'friendName': 'Amigo',
    'status': 'PENDING',
  };
  const invite = {
    'id': 90,
    'senderId': 12,
    'senderName': 'Jogador',
    'receiverId': 78,
    'receiverName': 'Amigo',
    'gameId': 34,
    'gameTitle': 'Portal 2',
    'gameImageUrl': null,
    'status': 'PENDING',
  };

  final contracts = <_Contract>[
    _Contract(
      'RatingService.getUserRatings',
      () => RatingService().getUserRatings(12),
      '/ratings/user/12',
      [rating],
    ),
    _Contract(
      'FriendshipService.sendRequest',
      () => FriendshipService().sendRequest(friendId: 78),
      '/friendships',
      friendship,
      method: 'POST',
      query: {'friendId': '78'},
    ),
    _Contract(
      'FriendshipService.getAcceptedFriends',
      () => FriendshipService().getAcceptedFriends(12),
      '/friendships/12',
      [
        {...friendship, 'status': 'ACCEPTED'},
      ],
    ),
    _Contract(
      'FriendshipService.getPendingRequests',
      () => FriendshipService().getPendingRequests(12),
      '/friendships/12/pending',
      [friendship],
    ),
    _Contract(
      'FriendshipService.acceptRequest',
      () => FriendshipService().acceptRequest(56),
      '/friendships/56/accept',
      {...friendship, 'status': 'ACCEPTED'},
      method: 'PUT',
    ),
    _Contract(
      'FriendshipService.rejectRequest',
      () => FriendshipService().rejectRequest(56),
      '/friendships/56/reject',
      {...friendship, 'status': 'REJECTED'},
      method: 'PUT',
    ),
    _Contract(
      'MatchService.getMatches',
      () => MatchService().getMatches(userId: 12, friendId: 78),
      '/matches/12/78',
      [
        {
          'gameId': 34,
          'gameTitle': 'Portal 2',
          'imageUrl': null,
          'userInterest': 'LIKE',
          'friendInterest': 'FAVORITE',
          'priorityInterest': 'FAVORITE',
        },
      ],
    ),
    _Contract(
      'MatchService.getCompatibleGames',
      () => MatchService().getCompatibleGames(userId: 12),
      '/matches/users/12/games',
      [
        {
          'gameId': 34,
          'gameTitle': 'Portal 2',
          'imageUrl': null,
          'compatibleFriendsCount': 2,
          'favoriteFriendsCount': 1,
          'userInterest': 'LIKE',
          'priorityInterest': 'FAVORITE',
        },
      ],
    ),
    _Contract(
      'MatchService.getInterestedFriends',
      () => MatchService().getInterestedFriends(userId: 12, gameId: 34),
      '/matches/users/12/games/34/friends',
      [
        {'friendId': 78, 'friendName': 'Amigo', 'interestType': 'FAVORITE'},
      ],
    ),
    _Contract(
      'PlayInviteService.sendInvite',
      () => PlayInviteService().sendInvite(receiverId: 78, gameId: 34),
      '/play-invites',
      invite,
      method: 'POST',
      query: {'receiverId': '78', 'gameId': '34'},
    ),
    _Contract(
      'PlayInviteService.getReceivedInvites',
      () => PlayInviteService().getReceivedInvites(12),
      '/play-invites/12/received',
      [
        {
          ...invite,
          'senderId': 78,
          'senderName': 'Amigo',
          'receiverId': 12,
          'receiverName': 'Jogador',
        },
      ],
    ),
    _Contract(
      'PlayInviteService.getSentInvites',
      () => PlayInviteService().getSentInvites(12),
      '/play-invites/12/sent',
      [invite],
    ),
    _Contract(
      'PlayInviteService.acceptInvite',
      () => PlayInviteService().acceptInvite(90),
      '/play-invites/90/accept',
      {...invite, 'status': 'ACCEPTED'},
      method: 'PUT',
    ),
    _Contract(
      'PlayInviteService.rejectInvite',
      () => PlayInviteService().rejectInvite(90),
      '/play-invites/90/reject',
      {...invite, 'status': 'REJECTED'},
      method: 'PUT',
    ),
  ];

  for (final contract in contracts) {
    group(contract.name, () {
      test('sends the authenticated HTTP contract and decodes JSON', () async {
        late http.Request sent;
        final result = await http.runWithClient(
          contract.call,
          () => MockClient((request) async {
            sent = request;
            return http.Response(jsonEncode(contract.response), 200);
          }),
        );

        expect(sent.method, contract.method);
        expect(sent.url.path, contract.path);
        expect(sent.url.queryParameters, contract.query);
        expect(sent.headers['authorization'], 'Bearer contract-test-token');
        expect(sent.body, isEmpty);
        expect(result, contract.response);
      });

      if (contract.response is List) {
        test('returns an empty list when the server has no items', () async {
          final result = await _respond(contract.call, '[]');
          expect(result, isEmpty);
        });
      }
    });
  }

  group('RatingService.sendRating', () {
    for (final type in ['LIKE', 'DISLIKE', 'FAVORITE']) {
      test('posts $type as JSON with bearer authentication', () async {
        late http.Request sent;
        await http.runWithClient(
          () => RatingService().sendRating(gameId: 34, type: type),
          () => MockClient((request) async {
            sent = request;
            return http.Response('', 204);
          }),
        );

        expect(sent.method, 'POST');
        expect(sent.url.path, '/ratings');
        expect(sent.url.queryParameters, isEmpty);
        expect(sent.headers['authorization'], 'Bearer contract-test-token');
        expect(sent.headers['content-type'], contains('application/json'));
        expect(jsonDecode(sent.body), {'gameId': 34, 'type': type});
      });
    }
  });

  group('HTTP failures', () {
    final failures = [
      (
        name: 'invalid rating',
        call: () => RatingService().sendRating(gameId: 34, type: 'LIKE'),
        status: 400,
        message: 'Dados inválidos. Verifique as informações enviadas.',
      ),
      (
        name: 'missing friendship',
        call: () => FriendshipService().acceptRequest(56),
        status: 404,
        message: 'Registro não encontrado.',
      ),
      (
        name: 'duplicate invite',
        call: () => PlayInviteService().sendInvite(receiverId: 78, gameId: 34),
        status: 409,
        message:
            'Essa operação já existe ou entra em conflito com os dados atuais.',
      ),
      (
        name: 'match server error',
        call: () => MatchService().getMatches(userId: 12, friendId: 78),
        status: 500,
        message: 'Erro interno do servidor. Tente novamente mais tarde.',
      ),
      (
        name: 'rate limited ratings',
        call: () => RatingService().getUserRatings(12),
        status: 429,
        message:
            'Muitas tentativas de login. Aguarde antes de tentar novamente.',
      ),
      for (final status in [401, 403])
        (
          name: 'invite access denied ($status)',
          call: () => PlayInviteService().acceptInvite(90),
          status: status,
          message: 'Não foi possível concluir a operação.',
        ),
    ];

    for (final failure in failures) {
      test('maps ${failure.name} to a user-facing error', () async {
        await expectLater(
          _respond(failure.call, '<html>error</html>', status: failure.status),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              'Exception: ${failure.message}',
            ),
          ),
        );
      });
    }
  });

  group('Invalid responses', () {
    for (final body in ['not JSON', '{}']) {
      test('rejects an invalid list response: $body', () async {
        await expectLater(
          _respond(() => MatchService().getCompatibleGames(userId: 12), body),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              'Exception: Resposta inválida do servidor.',
            ),
          ),
        );
      });
    }
    for (final body in ['not JSON', '[]', '']) {
      test('rejects an invalid object response: "$body"', () async {
        await expectLater(
          _respond(() => FriendshipService().sendRequest(friendId: 78), body),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              'Exception: Resposta inválida do servidor.',
            ),
          ),
        );
      });
    }
  });

  test('maps a transport failure without exposing its details', () async {
    await expectLater(
      http.runWithClient(
        () => PlayInviteService().getSentInvites(12),
        () => MockClient((_) async => throw http.ClientException('offline')),
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          'Exception: Não foi possível conectar ao servidor.',
        ),
      ),
    );
  });

  test('omits bearer authentication after the session is cleared', () async {
    UserSession.clear();
    late http.Request sent;
    await http.runWithClient(
      () => RatingService().getUserRatings(12),
      () => MockClient((request) async {
        sent = request;
        return http.Response('[]', 200);
      }),
    );
    expect(sent.headers, isNot(contains('authorization')));
  });
}

Future<dynamic> _respond(_Call call, String body, {int status = 200}) {
  return http.runWithClient(
    call,
    () => MockClient((_) async => http.Response(body, status)),
  );
}

class _Contract {
  const _Contract(
    this.name,
    this.call,
    this.path,
    this.response, {
    this.method = 'GET',
    this.query = const {},
  });

  final String name;
  final _Call call;
  final String path;
  final Object response;
  final String method;
  final Map<String, String> query;
}
