import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const screenTestUserId = 12;
const screenTestFriendId = 78;
const screenTestGameId = 34;

typedef ScreenApiOverride = FutureOr<http.Response?> Function(
  http.Request request,
);

class ScreenTestApi {
  ScreenTestApi(this._responder);

  final FutureOr<http.Response> Function(http.Request request) _responder;
  final List<http.Request> requests = [];

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    return _responder(request);
  }

  Future<T> run<T>(Future<T> Function() callback) {
    return http.runWithClient(callback, () => MockClient(_handle));
  }
}

http.Response jsonScreenResponse(Object? body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> screenUser({
  int id = screenTestFriendId,
  String name = 'Bia',
}) =>
    {'id': id, 'name': name};

Map<String, dynamic> screenFriendship({
  int id = 56,
  int userId = screenTestUserId,
  String userName = 'Jogador',
  int friendId = screenTestFriendId,
  String friendName = 'Bia',
  String status = 'ACCEPTED',
}) =>
    {
      'id': id,
      'userId': userId,
      'userName': userName,
      'friendId': friendId,
      'friendName': friendName,
      'status': status,
    };

Map<String, dynamic> screenPendingRequest({
  int id = 56,
  int userId = screenTestFriendId,
  String userName = 'Bia',
  int friendId = screenTestUserId,
  String friendName = 'Jogador',
}) =>
    screenFriendship(
      id: id,
      userId: userId,
      userName: userName,
      friendId: friendId,
      friendName: friendName,
      status: 'PENDING',
    );

Map<String, dynamic> screenMatch({
  int gameId = screenTestGameId,
  String gameTitle = 'Portal 2',
  String? imageUrl,
  String priorityInterest = 'FAVORITE',
}) =>
    {
      'gameId': gameId,
      'gameTitle': gameTitle,
      'imageUrl': imageUrl,
      'userInterest': 'LIKE',
      'friendInterest': priorityInterest,
      'priorityInterest': priorityInterest,
    };

Map<String, dynamic> screenCompatibleGame({
  int gameId = screenTestGameId,
  String gameTitle = 'Portal 2',
  String? imageUrl,
  int compatibleFriendsCount = 2,
  int favoriteFriendsCount = 1,
}) =>
    {
      'gameId': gameId,
      'gameTitle': gameTitle,
      'imageUrl': imageUrl,
      'compatibleFriendsCount': compatibleFriendsCount,
      'favoriteFriendsCount': favoriteFriendsCount,
      'userInterest': 'LIKE',
      'priorityInterest': 'FAVORITE',
    };

Map<String, dynamic> screenInterestedFriend({
  int friendId = screenTestFriendId,
  String friendName = 'Bia',
  String interestType = 'FAVORITE',
}) =>
    {
      'friendId': friendId,
      'friendName': friendName,
      'interestType': interestType,
    };

Map<String, dynamic> screenInvite({
  int id = 90,
  int senderId = screenTestFriendId,
  String senderName = 'Bia',
  int receiverId = screenTestUserId,
  String receiverName = 'Jogador',
  int gameId = screenTestGameId,
  String gameTitle = 'Portal 2',
  String? gameImageUrl,
  String status = 'PENDING',
}) =>
    {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'gameId': gameId,
      'gameTitle': gameTitle,
      'gameImageUrl': gameImageUrl,
      'status': status,
    };

ScreenTestApi friendsScreenApi({
  List<Map<String, dynamic>>? users,
  List<Map<String, dynamic>>? acceptedFriends,
  List<Map<String, dynamic>>? pendingRequests,
  List<Map<String, dynamic>>? receivedInvites,
  List<Map<String, dynamic>>? sentInvites,
  Map<int, List<Map<String, dynamic>>> matchesByFriend = const {},
  ScreenApiOverride? override,
}) {
  return ScreenTestApi((request) async {
    final overridden = await override?.call(request);
    if (overridden != null) return overridden;

    final path = request.url.path;
    if (request.method == 'GET' && path == '/users') {
      return jsonScreenResponse(
        users ?? [screenUser(), screenUser(id: screenTestUserId, name: 'Jogador')],
      );
    }
    if (request.method == 'GET' && path == '/friendships/$screenTestUserId') {
      return jsonScreenResponse(acceptedFriends ?? []);
    }
    if (request.method == 'GET' &&
        path == '/friendships/$screenTestUserId/pending') {
      return jsonScreenResponse(pendingRequests ?? []);
    }
    if (request.method == 'GET' &&
        path == '/play-invites/$screenTestUserId/received') {
      return jsonScreenResponse(receivedInvites ?? []);
    }
    if (request.method == 'GET' &&
        path == '/play-invites/$screenTestUserId/sent') {
      return jsonScreenResponse(sentInvites ?? []);
    }
    if (request.method == 'GET' && path.startsWith('/matches/$screenTestUserId/')) {
      final friendId = int.parse(path.split('/').last);
      return jsonScreenResponse(matchesByFriend[friendId] ?? []);
    }
    if (request.method == 'POST' && path == '/friendships') {
      return jsonScreenResponse({'id': 57, 'status': 'PENDING'}, status: 201);
    }
    if (request.method == 'PUT' && path.contains('/accept')) {
      return jsonScreenResponse({'status': 'ACCEPTED'});
    }
    if (request.method == 'PUT' && path.contains('/reject')) {
      return jsonScreenResponse({'status': 'REJECTED'});
    }
    if (request.method == 'POST' && path == '/play-invites') {
      return jsonScreenResponse({'id': 91, 'status': 'PENDING'}, status: 201);
    }
    return jsonScreenResponse({'message': 'No mock for ${request.method} $path'}, status: 404);
  });
}

ScreenTestApi gamesScreenApi({
  List<Map<String, dynamic>>? games,
  Map<int, List<Map<String, dynamic>>> interestedFriendsByGame = const {},
  List<Map<String, dynamic>>? receivedInvites,
  List<Map<String, dynamic>>? sentInvites,
  ScreenApiOverride? override,
}) {
  return ScreenTestApi((request) async {
    final overridden = await override?.call(request);
    if (overridden != null) return overridden;

    final path = request.url.path;
    if (request.method == 'GET' && path == '/matches/users/$screenTestUserId/games') {
      return jsonScreenResponse(games ?? []);
    }
    if (request.method == 'GET' && path.startsWith('/matches/users/$screenTestUserId/games/')) {
      final gameId = int.parse(path.split('/')[5]);
      return jsonScreenResponse(interestedFriendsByGame[gameId] ?? []);
    }
    if (request.method == 'GET' &&
        path == '/play-invites/$screenTestUserId/received') {
      return jsonScreenResponse(receivedInvites ?? []);
    }
    if (request.method == 'GET' &&
        path == '/play-invites/$screenTestUserId/sent') {
      return jsonScreenResponse(sentInvites ?? []);
    }
    if (request.method == 'PUT' && path.contains('/accept')) {
      return jsonScreenResponse({'status': 'ACCEPTED'});
    }
    if (request.method == 'PUT' && path.contains('/reject')) {
      return jsonScreenResponse({'status': 'REJECTED'});
    }
    if (request.method == 'POST' && path == '/play-invites') {
      return jsonScreenResponse({'id': 91, 'status': 'PENDING'}, status: 201);
    }
    return jsonScreenResponse({'message': 'No mock for ${request.method} $path'}, status: 404);
  });
}
