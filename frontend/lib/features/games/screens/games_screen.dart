import 'package:flutter/material.dart';

import '../../../core/session/user_session.dart';
import '../../../data/services/match_service.dart';
import '../../../data/services/play_invite_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final MatchService matchService = MatchService();
  final PlayInviteService playInviteService = PlayInviteService();

  List<dynamic> games = [];
  List<dynamic> selectedFriends = [];
  List<dynamic> receivedInvites = [];
  List<dynamic> sentInvites = [];

  bool loading = true;
  bool loadingFriends = false;
  bool loadingInvites = true;
  String? error;
  String? invitesError;
  String? selectedGameTitle;
  int? selectedGameId;

  @override
  void initState() {
    super.initState();
    loadGames();
    loadInvites();
  }

  Future<void> loadGames() async {
    final userId = UserSession.userId;

    if (userId == null) {
      setState(() {
        error = "Usuário não logado";
        loading = false;
      });
      return;
    }

    try {
      final data = await matchService.getCompatibleGames(userId: userId);

      setState(() {
        games = sortCompatibleGames(data);
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error =
            "Não foi possível carregar jogos compatíveis. Verifique se o backend está rodando.";
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
      selectedGameId = game['gameId'];
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
          content: Text("Não foi possível buscar amigos interessados."),
        ),
      );
    }
  }

  void clearSelectedGame() {
    setState(() {
      selectedGameTitle = null;
      selectedGameId = null;
      selectedFriends = [];
      loadingFriends = false;
    });
  }

  Future<void> loadInvites() async {
    final userId = UserSession.userId;

    if (userId == null) {
      setState(() {
        invitesError = "Usuário não logado";
        loadingInvites = false;
      });
      return;
    }

    try {
      final received = await playInviteService.getReceivedInvites(userId);
      final sent = await playInviteService.getSentInvites(userId);

      setState(() {
        receivedInvites = sortInvitesByStatus(received);
        sentInvites = sortInvitesByStatus(sent);
        invitesError = null;
        loadingInvites = false;
      });
    } catch (e) {
      setState(() {
        invitesError = "Não foi possível carregar convites.";
        loadingInvites = false;
      });
    }
  }

  Future<void> sendPlayInvite(dynamic friend) async {
    final senderId = UserSession.userId;
    final gameId = selectedGameId;
    final receiverId = friend['friendId'];

    if (senderId == null || gameId == null || receiverId == null) {
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

  dynamic findInviteForFriendAndGame({
    required int friendId,
    required int gameId,
  }) {
    final userId = UserSession.userId;
    if (userId == null) return null;

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

  String inviteStatusText(String? status) {
    switch (status) {
      case "ACCEPTED":
        return "Aceito";
      case "REJECTED":
        return "Recusado";
      case "PENDING":
      default:
        return "Pendente";
    }
  }

  List<dynamic> sortInvitesByStatus(List<dynamic> invites) {
    final sortedInvites = List<dynamic>.from(invites);

    sortedInvites.sort((first, second) {
      final firstPriority = inviteStatusPriority(first['status']);
      final secondPriority = inviteStatusPriority(second['status']);

      return firstPriority.compareTo(secondPriority);
    });

    return sortedInvites;
  }

  int inviteStatusPriority(String? status) {
    switch (status) {
      case "ACCEPTED":
        return 0;
      case "PENDING":
        return 1;
      case "REJECTED":
        return 2;
      default:
        return 3;
    }
  }

  String inviteCardStatusText(String? status) {
    return "Status: ${inviteStatusText(status)}";
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

  Future<void> acceptInvite(dynamic invite) async {
    final inviteId = invite['id'];
    if (inviteId == null) return;

    try {
      await playInviteService.acceptInvite(inviteId);
      await loadInvites();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Convite para jogar aceito.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível aceitar o convite.")),
      );
    }
  }

  Future<void> rejectInvite(dynamic invite) async {
    final inviteId = invite['id'];
    if (inviteId == null) return;

    try {
      await playInviteService.rejectInvite(inviteId);
      await loadInvites();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Convite para jogar recusado.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível recusar o convite.")),
      );
    }
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
              Tab(text: "Compatíveis"),
              Tab(text: "Convites"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            compatibleGamesTab(),
            invitesTab(),
          ],
        ),
      ),
    );
  }

  Widget compatibleGamesTab() {
    return RefreshIndicator(
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
                "Nenhum jogo compatível encontrado ainda.\nAvalie mais jogos ou adicione amigos para encontrar interesses em comum.",
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
    );
  }

  Widget invitesTab() {
    if (loadingInvites) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadInvites,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (invitesError != null) emptyText(invitesError!),
          sectionTitle("Recebidos"),
          if (receivedInvites.isEmpty)
            emptyText("Nenhum convite recebido no momento.")
          else
            ...receivedInvites.map((invite) => receivedInviteTile(invite)),
          const SizedBox(height: 16),
          sectionTitle("Enviados"),
          if (sentInvites.isEmpty)
            emptyText("Nenhum convite enviado ainda.")
          else
            ...sentInvites.map((invite) => sentInviteTile(invite)),
        ],
      ),
    );
  }

  Widget gameTile(dynamic game) {
    final compatibleFriends = game['compatibleFriendsCount'] ?? 0;
    final favoriteFriends = game['favoriteFriendsCount'] ?? 0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          interestSummary(compatibleFriends, favoriteFriends),
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }

  List<dynamic> sortCompatibleGames(List<dynamic> games) {
    final sortedGames = List<dynamic>.from(games);

    sortedGames.sort((first, second) {
      final firstFavorite = first['favoriteFriendsCount'] ?? 0;
      final secondFavorite = second['favoriteFriendsCount'] ?? 0;

      if (firstFavorite != secondFavorite) {
        return secondFavorite.compareTo(firstFavorite);
      }

      final firstTotal = first['compatibleFriendsCount'] ?? 0;
      final secondTotal = second['compatibleFriendsCount'] ?? 0;

      return secondTotal.compareTo(firstTotal);
    });

    return sortedGames;
  }

  String interestSummary(int compatibleFriends, int favoriteFriends) {
    final interestedText = compatibleFriends == 1
        ? "1 amigo interessado"
        : "$compatibleFriends amigos interessados";

    if (favoriteFriends <= 0) {
      return interestedText;
    }

    final favoriteText = favoriteFriends == 1
        ? "1 quer jogar"
        : "$favoriteFriends querem jogar";

    return "$interestedText\n$favoriteText";
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
          emptyText(
            "Nenhum amigo interessado encontrado para este jogo.\nConvites poderão aparecer quando amigos também demonstrarem interesse.",
          )
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
    final friendId = friend['friendId'];
    final gameId = selectedGameId;
    final existingInvite = friendId == null || gameId == null
        ? null
        : findInviteForFriendAndGame(friendId: friendId, gameId: gameId);

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.white70),
        title: Text(
          friend['friendName'] ?? "Amigo",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          wantsToPlay ? "Quer jogar" : "Gostou",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: existingInvite == null
            ? TextButton(
                onPressed: () => sendPlayInvite(friend),
                child: const Text("Convidar para jogar"),
              )
            : Text(
                inviteActionStatusText(existingInvite['status']),
                style: const TextStyle(color: Colors.white70),
              ),
      ),
    );
  }

  Widget receivedInviteTile(dynamic invite) {
    final status = invite['status'] ?? "PENDING";
    final isPending = status == "PENDING";

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: inviteImage(invite),
        title: Text(
          invite['gameTitle'] ?? "Jogo",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "De: ${invite['senderName'] ?? 'Amigo'}\n${inviteCardStatusText(status)}",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: isPending
            ? Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => acceptInvite(invite),
                    child: const Text("Aceitar"),
                  ),
                  TextButton(
                    onPressed: () => rejectInvite(invite),
                    child: const Text("Recusar"),
                  ),
                ],
              )
            : Text(
                inviteStatusText(status),
                style: const TextStyle(color: Colors.white70),
              ),
      ),
    );
  }

  Widget sentInviteTile(dynamic invite) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: inviteImage(invite),
        title: Text(
          invite['gameTitle'] ?? "Jogo",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "Para: ${invite['receiverName'] ?? 'Amigo'}",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          inviteStatusText(invite['status']),
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget inviteImage(dynamic invite) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        invite['gameImageUrl'] ?? "",
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.games, color: Colors.white),
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

