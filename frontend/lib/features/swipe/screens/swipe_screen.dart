import 'package:flutter/material.dart';

import '../../../core/session/user_session.dart';
import '../../navegation/widgets/main_navegation.dart';
import '../controllers/swipe_controller.dart';
import '../widgets/action_buttons.dart';
import '../widgets/game_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final controller = SwipeController();

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  Future<void> loadGames({bool includeRatedGames = false}) async {
    final userId = UserSession.userId;

    if (userId == null) {
      return;
    }

    await controller.loadGames(userId, includeRatedGames: includeRatedGames);

    if (mounted) {
      setState(() {});
    }
  }

  void openTab(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigation(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.games.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Voce ja avaliou todos os jogos disponiveis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Reinicie a avaliacao para revisar suas escolhas e atualizar seus interesses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => openTab(2),
                    child: const Text('Ver jogos compativeis'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => openTab(1),
                    child: const Text('Ver amigos'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => loadGames(includeRatedGames: true),
                  child: const Text('Reiniciar avaliacao'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.finished) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Game Match')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Voce avaliou todos os jogos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => openTab(2),
                  child: const Text('Ver jogos compativeis'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => openTab(1),
                  child: const Text('Ver amigos'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => loadGames(includeRatedGames: true),
                  child: const Text('Reiniciar avaliacao'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final game = controller.currentGame;

    if (game == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Carregando jogos...",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final userId = UserSession.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Text(
              "Avalie jogos para encontrar compatibilidades com seus amigos.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          GameCard(game: game),
          ActionButtons(
            onDislike: () async {
              if (userId == null) return;

              await controller.dislikeGame(userId);
              setState(() {});
            },
            onLike: () async {
              if (userId == null) return;

              await controller.likeGame(userId);
              setState(() {});
            },
            onFavorite: () async {
              if (userId == null) return;

              await controller.favoriteGame(userId);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
