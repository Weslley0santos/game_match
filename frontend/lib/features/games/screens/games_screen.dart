import 'package:flutter/material.dart';

import '../../../core/session/user_session.dart';
import '../../../data/services/match_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final MatchService matchService = MatchService();

  List<dynamic> games = [];
  List<dynamic> selectedFriends = [];

  bool loading = true;
  bool loadingFriends = false;
  String? error;
  String? selectedGameTitle;

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  Future<void> loadGames() async {
    final userId = UserSession.userId;

    if (userId == null) {
      setState(() {
        error = "Usuario nao logado";
        loading = false;
      });
      return;
    }

    try {
      final data = await matchService.getCompatibleGames(userId: userId);

      setState(() {
        games = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error =
            "Nao foi possivel carregar jogos compativeis. Verifique se o backend esta rodando.";
        loading = false;
      });
    }
  }

  Future<void> loadInterestedFriends(dynamic game) async {
    final userId = UserSession.userId;
    if (userId == null) return;

    setState(() {
      loadingFriends = true;
      selectedGameTitle = game['gameTitle'] ?? "Jogo";
      selectedFriends = [];
    });

    try {
      final data = await matchService.getInterestedFriends(
        userId: userId,
        gameId: game['gameId'],
      );

      setState(() {
        selectedFriends = data;
        loadingFriends = false;
      });
    } catch (e) {
      setState(() {
        loadingFriends = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nao foi possivel buscar amigos interessados."),
        ),
      );
    }
  }

  void clearSelectedGame() {
    setState(() {
      selectedGameTitle = null;
      selectedFriends = [];
      loadingFriends = false;
    });
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
        appBar: AppBar(title: const Text("Jogos")),
        body: Center(
          child: Text(error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Jogos")),
      body: RefreshIndicator(
        onRefresh: loadGames,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (selectedGameTitle == null) ...[
              emptyText(
                "Escolha um jogo para ver quais amigos demonstraram interesse.",
              ),
              const SizedBox(height: 8),
              if (games.isEmpty)
                emptyText(
                  "Nenhum jogo compativel encontrado. Avalie jogos e adicione amigos para ver interesses em comum.",
                )
              else
                ...games.map((game) => gameTile(game)),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: clearSelectedGame,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Voltar para jogos"),
                ),
              ),
              interestedFriendsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget gameTile(dynamic game) {
    final compatibleFriends = game['compatibleFriendsCount'] ?? 0;
    final favoriteFriends = game['favoriteFriendsCount'] ?? 0;

    return Card(
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        onTap: () => loadInterestedFriends(game),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            game['imageUrl'] ?? "",
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.games, color: Colors.white),
          ),
        ),
        title: Text(
          game['gameTitle'] ?? "Jogo",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          favoriteFriends > 0
              ? "$favoriteFriends querem jogar - $compatibleFriends interessados"
              : "$compatibleFriends interessados",
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget interestedFriendsSection() {
    if (selectedGameTitle == null) {
      return emptyText(
        "Toque em um jogo para ver quais amigos demonstraram interesse nele.",
      );
    }

    if (loadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    final friendsWhoWantToPlay = selectedFriends
        .where((friend) => friend['interestType'] == "FAVORITE")
        .toList();
    final friendsWhoLiked = selectedFriends
        .where((friend) => friend['interestType'] == "LIKE")
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle("Amigos interessados em $selectedGameTitle"),
        if (selectedFriends.isEmpty)
          emptyText("Nenhum amigo interessado encontrado para este jogo.")
        else ...[
          if (friendsWhoWantToPlay.isNotEmpty) ...[
            sectionTitle("Querem jogar"),
            ...friendsWhoWantToPlay.map((friend) => friendTile(friend)),
            const SizedBox(height: 12),
          ],
          if (friendsWhoLiked.isNotEmpty) ...[
            sectionTitle("Gostaram"),
            ...friendsWhoLiked.map((friend) => friendTile(friend)),
          ],
        ],
      ],
    );
  }

  Widget friendTile(dynamic friend) {
    final interestType = friend['interestType'];
    final wantsToPlay = interestType == "FAVORITE";

    return Card(
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        title: Text(
          friend['friendName'] ?? "Amigo",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          wantsToPlay ? "Quer jogar" : "Gostou",
          style: const TextStyle(color: Colors.white70),
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
}
