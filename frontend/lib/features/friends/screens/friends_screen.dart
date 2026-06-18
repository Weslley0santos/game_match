import 'package:flutter/material.dart';

import '../../../core/session/user_session.dart';
import '../../../data/services/friendship_service.dart';
import '../../../data/services/match_service.dart';
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
  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> pendingRequests = [];
  List<dynamic> acceptedFriends = [];
  List<dynamic> selectedMatches = [];

  Map<int, int> matchCounts = {};

  bool loading = true;
  bool loadingMatches = false;
  String searchQuery = "";
  String? error;
  String? selectedFriendName;

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
        error = "Usuario nao logado";
        loading = false;
      });
      return;
    }

    try {
      final allUsers = await userService.getUsers();
      final friends = await friendshipService.getAcceptedFriends(userId);
      final pending = await friendshipService.getPendingRequests(userId);
      final counts = await loadMatchCounts(userId, friends);

      setState(() {
        users = allUsers.where((user) => user['id'] != userId).toList();
        acceptedFriends = friends;
        pendingRequests = pending;
        matchCounts = counts;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error =
            "Nao foi possivel carregar amigos. Verifique se o backend esta rodando.";
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitacao enviada")),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Nao foi possivel enviar. Talvez ja exista uma solicitacao ou amizade com esse usuario.",
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
        const SnackBar(content: Text("Solicitacao aceita")),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Nao foi possivel aceitar. Verifique se o backend esta rodando e tente novamente.",
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
        const SnackBar(content: Text("Solicitacao recusada")),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Nao foi possivel recusar. Verifique se o backend esta rodando e tente novamente.",
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
            "Nao foi possivel buscar jogos em comum. A amizade precisa estar aceita e o backend ativo.",
          ),
        ),
      );
    }
  }

  void clearSelectedFriend() {
    setState(() {
      selectedFriendName = null;
      selectedMatches = [];
      loadingMatches = false;
    });
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
        appBar: AppBar(title: const Text("Amigos")),
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
          title: const Text("Amigos"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Amigos"),
              Tab(text: "Solicitacoes"),
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
              "Escolha um amigo para ver jogos compativeis entre voces.",
            ),
            const SizedBox(height: 8),
            if (acceptedFriends.isEmpty)
              emptyText(
                "Voce ainda nao tem amigos aceitos. Use a aba Solicitacoes para buscar usuarios ou responder convites.",
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
            emptyText("Digite o nome de um usuario para enviar uma solicitacao.")
          else if (filteredUsers.isEmpty)
            emptyText(
              "Nenhum usuario encontrado com esse nome. Confira a escrita ou tente outro nome.",
            )
          else
            ...filteredUsers.map((user) => userTile(user)),
          const SizedBox(height: 24),
          sectionTitle("Solicitacoes pendentes"),
          if (pendingRequests.isEmpty)
            emptyText(
              "Voce nao tem solicitacoes pendentes no momento.",
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
        labelText: "Buscar por nome",
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
    return Card(
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        title: Text(
          user['name'] ?? "Usuario sem nome",
          style: const TextStyle(color: Colors.white),
        ),
        trailing: ElevatedButton(
          onPressed: () => sendRequest(user['id']),
          child: const Text("Solicitar amizade"),
        ),
      ),
    );
  }

  Widget pendingTile(dynamic request) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        title: Text(
          request['userName'] ?? "Usuario",
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
      child: ListTile(
        onTap: () => loadMatches(data),
        title: Text(
          getOtherUserName(data),
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "$commonGames jogos em comum",
          style: const TextStyle(color: Colors.white70),
        ),
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
            "Nenhum jogo em comum encontrado. Voces precisam avaliar o mesmo jogo com gostei ou quero jogar.",
          )
        else
          ...selectedMatches.map((match) => matchTile(match)),
      ],
    );
  }

  Widget matchTile(dynamic match) {
    final priorityInterest = match['priorityInterest'];
    final hasFavorite = priorityInterest == "FAVORITE";

    return Card(
      color: const Color(0xFF1E1E1E),
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
      ),
    );
  }
}
