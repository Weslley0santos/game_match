import 'package:flutter/material.dart';

import '../../../core/session/user_session.dart';
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

    controller.loadGames().then((_) {
      setState(() {});
    });
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Nenhum jogo encontrado',
            style: TextStyle(color: Colors.white),
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
                'Você avaliou todos os jogos 🎮',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    controller.reset();
                  });
                },
                child: const Text('Recomeçar'),
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
