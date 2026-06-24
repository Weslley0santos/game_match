import 'package:flutter/material.dart';

import '../../../core/session/user_session.dart';
import '../../../data/services/friendship_service.dart';
import '../../../data/services/match_service.dart';
import '../../../data/services/play_invite_service.dart';
import '../../../data/services/user_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final UserService userService = UserService();
  final FriendshipService friendshipService = FriendshipService();
  final MatchService matchService = MatchService();
  final PlayInviteService playInviteService = PlayInviteService();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> pendingRequests = [];
  List<dynamic> acceptedFriends = [];
  List<dynamic> selectedMatches = [];
  List<dynamic> receivedInvites = [];
  List<dynamic> sentInvites = [];

  Map<int, int> matchCounts = {};
  final Set<int> sentFriendRequestIds = {};

  bool loading = true;
  bool loadingMatches = false;
  String searchQuery = "";
  String? error;
  String? selectedFriendName;
  int? selectedFriendId;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final userId = UserSession.userId;

    if (userId == null) {
      setState(() {
        error = "Usuário não logado";
        loading = false;
      });
      return;
    }

    try {
      final allUsers = await userService.getUsers();
      final friends = await friendshipService.getAcceptedFriends(userId);
      final pending = await friendshipService.getPendingRequests(userId);
      final received = await playInviteService.getReceivedInvites(userId);
      final sent = await playInviteService.getSentInvites(userId);
      final counts = await loadMatchCounts(userId, friends);

      setState(() {
        users = allUsers.where((user) => user['id'] != userId).toList();
        acceptedFriends = sortFriendsByMatchCount(friends, counts);
        pendingRequests = pending;
        receivedInvites = received;
        sentInvites = sent;
        matchCounts = counts;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error =
            "Não foi possível carregar amigos. Verifique se o backend está rodando.";
        loading = false;
      });
    }
  }

  Future<Map<int, int>> loadMatchCounts(
    int userId,
    List<dynamic> friendships,
  ) async {
    final counts = <int, int>{};

    for (final friendship in friendships) {
      final data = Map<String, dynamic>.from(friendship);
      final friendId = getOtherUserId(data);

      try {
        final matches = await matchService.getMatches(
          userId: userId,
          friendId: friendId,
        );
        counts[friendId] = matches.length;
      } catch (e) {
        counts[friendId] = 0;
      }
    }

    return counts;
  }

  List<dynamic> sortFriendsByMatchCount(
    List<dynamic> friendships,
    Map<int, int> counts,
  ) {
    final sortedFriendships = List<dynamic>.from(friendships);

    sortedFriendships.sort((first, second) {
      final firstId = getOtherUserId(Map<String, dynamic>.from(first));
      final secondId = getOtherUserId(Map<String, dynamic>.from(second));
      final firstCount = counts[firstId] ?? 0;
      final secondCount = counts[secondId] ?? 0;

      return secondCount.compareTo(firstCount);
    });

    return sortedFriendships;
  }

  List<dynamic> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    return users.where((user) {
      final name = (user['name'] ?? "").toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  Future<void> sendRequest(int friendId) async {
    final userId = UserSession.userId;
    if (userId == null) return;

    try {
      await friendshipService.sendRequest(userId: userId, friendId: friendId);
      setState(() {
        sentFriendRequestIds.add(friendId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitação de amizade enviada.")),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não foi possível enviar. Talvez já exista uma solicitação ou amizade com esse usuário.",
          ),
        ),
      );
    }
  }

  Future<void> acceptRequest(int friendshipId) async {
    try {
      await friendshipService.acceptRequest(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amizade aceita.")),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não foi possível aceitar. Verifique se o backend está rodando e tente novamente.",
          ),
        ),
      );
    }
  }

  Future<void> rejectRequest(int friendshipId) async {
    try {
      await friendshipService.rejectRequest(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amizade recusada.")),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não foi possível recusar. Verifique se o backend está rodando e tente novamente.",
          ),
        ),
      );
    }
  }

  Future<void> loadMatches(Map<String, dynamic> friendship) async {
    final userId = UserSession.userId;
    if (userId == null) return;

    final friendId = getOtherUserId(friendship);
    final friendName = getOtherUserName(friendship);

    setState(() {
      loadingMatches = true;
      selectedFriendName = friendName;
      selectedFriendId = friendId;
      selectedMatches = [];
    });

    try {
      final data = await matchService.getMatches(
        userId: userId,
        friendId: friendId,
      );

      setState(() {
        selectedMatches = data;
        loadingMatches = false;
        matchCounts[friendId] = data.length;
      });
    } catch (e) {
      setState(() {
        loadingMatches = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Não foi possível buscar jogos em comum. A amizade precisa estar aceita e o backend ativo.",
          ),
        ),
      );
    }
  }

  void clearSelectedFriend() {
    setState(() {
      selectedFriendName = null;
      selectedFriendId = null;
      selectedMatches = [];
      loadingMatches = false;
    });
  }

  Future<void> sendPlayInvite(dynamic match) async {
    final senderId = UserSession.userId;
    final receiverId = selectedFriendId;
    final gameId = match['gameId'];

    if (senderId == null || receiverId == null || gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível enviar o convite.")),
      );
      return;
    }

    try {
      await playInviteService.sendInvite(
        senderId: senderId,
        receiverId: receiverId,
        gameId: gameId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Convite para jogar enviado.")),
      );
      await loadInvites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível enviar o convite.")),
      );
    }
  }

  Future<void> loadInvites() async {
    final userId = UserSession.userId;
    if (userId == null) return;

    final received = await playInviteService.getReceivedInvites(userId);
    final sent = await playInviteService.getSentInvites(userId);

    setState(() {
      receivedInvites = received;
      sentInvites = sent;
    });
  }

  dynamic findInviteForSelectedFriendAndGame(int gameId) {
    final userId = UserSession.userId;
    final friendId = selectedFriendId;

    if (userId == null || friendId == null) return null;

    final invites = [...sentInvites, ...receivedInvites];

    for (final invite in invites) {
      final sameGame = invite['gameId'] == gameId;
      final sentToFriend =
          invite['senderId'] == userId && invite['receiverId'] == friendId;
      final receivedFromFriend =
          invite['senderId'] == friendId && invite['receiverId'] == userId;

      if (sameGame && (sentToFriend || receivedFromFriend)) {
        return invite;
      }
    }

    return null;
  }

  String inviteActionStatusText(String? status) {
    switch (status) {
      case "ACCEPTED":
        return "Convite aceito";
      case "REJECTED":
        return "Convite recusado";
      case "PENDING":
      default:
        return "Convite enviado";
    }
  }

  int getOtherUserId(Map<String, dynamic> friendship) {
    final currentUserId = UserSession.userId;
    return friendship['userId'] == currentUserId
        ? friendship['friendId']
        : friendship['userId'];
  }

  String getOtherUserName(Map<String, dynamic> friendship) {
    final currentUserId = UserSession.userId;
    return friendship['userId'] == currentUserId
        ? friendship['friendName']
        : friendship['userName'];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Amigos"),
              Tab(text: "Solicitações"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            friendsTab(),
            requestsTab(),
          ],
        ),
      ),
    );
  }

  Widget friendsTab() {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (selectedFriendName == null) ...[
            emptyText(
              "Escolha um amigo para ver jogos compatíveis entre vocês.",
            ),
            const SizedBox(height: 8),
            if (acceptedFriends.isEmpty)
              emptyText(
                "Você ainda não tem amigos aceitos. Use a aba Solicitações para buscar usuários ou responder convites.",
              )
            else
              ...acceptedFriends.map((friendship) => friendTile(friendship)),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: clearSelectedFriend,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Voltar para amigos"),
              ),
            ),
            matchesSection(),
          ],
        ],
      ),
    );
  }

  Widget requestsTab() {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          searchField(),
          const SizedBox(height: 12),
          sectionTitle("Resultados da busca"),
          if (searchQuery.trim().isEmpty)
            emptyText("Digite o nome de um usuário para enviar uma solicitação.")
          else if (filteredUsers.isEmpty)
            emptyText(
              "Nenhum usuário encontrado com esse nome. Confira a escrita ou tente outro nome.",
            )
          else
            ...filteredUsers.map((user) => userTile(user)),
          const SizedBox(height: 24),
          sectionTitle("Solicitações pendentes"),
          if (pendingRequests.isEmpty)
            emptyText(
              "Você não tem solicitações pendentes no momento.",
            )
          else
            ...pendingRequests.map((request) => pendingTile(request)),
        ],
      ),
    );
  }

  Widget searchField() {
    return TextField(
      controller: searchController,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        labelText: "Buscar pessoas",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget userTile(dynamic user) {
    final userId = user['id'];
    final isSentRequest = userId is int && sentFriendRequestIds.contains(userId);
    final isAcceptedFriend = userId is int && hasAcceptedFriendshipWith(userId);

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.white70),
        title: Text(
          user['name'] ?? "Usuário sem nome",
          style: const TextStyle(color: Colors.white),
        ),
        trailing: friendRequestTrailing(
          userId: userId,
          isSentRequest: isSentRequest,
          isAcceptedFriend: isAcceptedFriend,
        ),
      ),
    );
  }

  Widget friendRequestTrailing({
    required dynamic userId,
    required bool isSentRequest,
    required bool isAcceptedFriend,
  }) {
    if (isAcceptedFriend) {
      return const Text(
        "Amigo",
        style: TextStyle(color: Colors.white70),
      );
    }

    if (isSentRequest) {
      return const Text(
        "Solicitação enviada",
        style: TextStyle(color: Colors.white70),
      );
    }

    return ElevatedButton(
      onPressed: userId is int ? () => sendRequest(userId) : null,
      child: const Text("Solicitar amizade"),
    );
  }

  bool hasAcceptedFriendshipWith(int userId) {
    for (final friendship in acceptedFriends) {
      final data = Map<String, dynamic>.from(friendship);
      if (getOtherUserId(data) == userId) {
        return true;
      }
    }

    return false;
  }

  Widget pendingTile(dynamic request) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.person_add, color: Colors.white70),
        title: Text(
          request['userName'] ?? "Usuário",
          style: const TextStyle(color: Colors.white),
        ),
        trailing: SizedBox(
          width: 112,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: "Aceitar",
                onPressed: () => acceptRequest(request['id']),
                icon: const Icon(Icons.check, color: Colors.green),
              ),
              IconButton(
                tooltip: "Recusar",
                onPressed: () => rejectRequest(request['id']),
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget friendTile(dynamic friendship) {
    final data = Map<String, dynamic>.from(friendship);
    final friendId = getOtherUserId(data);
    final commonGames = matchCounts[friendId] ?? 0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => loadMatches(data),
        leading: const Icon(Icons.person, color: Colors.white70),
        title: Text(
          getOtherUserName(data),
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "$commonGames jogos em comum",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }

  Widget matchesSection() {
    if (selectedFriendName == null) {
      return emptyText(
        "Toque em um amigo aceito para ver jogos em comum.",
      );
    }

    if (loadingMatches) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle("Jogos em comum com $selectedFriendName"),
        if (selectedMatches.isEmpty)
          emptyText(
            "Nenhum jogo em comum encontrado. Vocês precisam avaliar o mesmo jogo com gostei ou quero jogar.",
          )
        else
          ...selectedMatches.map((match) => matchTile(match)),
      ],
    );
  }

  Widget matchTile(dynamic match) {
    final priorityInterest = match['priorityInterest'];
    final hasFavorite = priorityInterest == "FAVORITE";
    final gameId = match['gameId'];
    final existingInvite = gameId == null
        ? null
        : findInviteForSelectedFriendAndGame(gameId);

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            match['imageUrl'] ?? "",
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.games, color: Colors.white),
          ),
        ),
        title: Text(
          match['gameTitle'] ?? "Jogo",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          hasFavorite ? "Quer jogar" : "Tem interesse",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: existingInvite == null
            ? TextButton(
                onPressed: () => sendPlayInvite(match),
                child: const Text("Convidar para jogar"),
              )
            : Text(
                inviteActionStatusText(existingInvite['status']),
                style: const TextStyle(color: Colors.white70),
              ),
      ),
    );
  }
}
