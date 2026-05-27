import 'package:flutter/material.dart';
import '../../../data/models/game_model.dart';

class GameCard extends StatelessWidget {
  final GameModel game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 520,
        width: double.infinity,
        margin: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(game.imageUrl),
            fit: BoxFit.cover,
          ),
        ),

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.85), Colors.transparent],
            ),
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // 🎮 PLATAFORMAS AGORA AQUI EMBAIXO DO TÍTULO
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: game.platforms.map((platform) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        platform,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),

                Text(
                  game.genre,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 10),

                Text(
                  game.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
