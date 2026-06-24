import 'package:flutter/material.dart';
import '../../../data/models/game_model.dart';

class GameCard extends StatelessWidget {
  final GameModel game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final hasImage = game.imageUrl.trim().isNotEmpty;
    final platforms = game.platforms.isEmpty
        ? ["Plataforma não informada"]
        : game.platforms;
    final visiblePlatforms = platforms.take(5).toList();
    final hiddenPlatformsCount = platforms.length - visiblePlatforms.length;
    final description = game.description.trim().isEmpty
        ? "Sem descrição disponível"
        : game.description;

    return Center(
      child: Container(
        height: 520,
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  game.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.games, color: Colors.white70, size: 80),
                  ),
                )
              else
                const Center(
                  child: Icon(Icons.games, color: Colors.white70, size: 80),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            game.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Abrir detalhes do jogo",
                          onPressed: () => showGameDetails(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            shape: const CircleBorder(),
                          ),
                          icon: const Icon(
                            Icons.expand_more,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ...visiblePlatforms.map((platform) {
                          return platformChip(platform);
                        }),
                        if (hiddenPlatformsCount > 0)
                          platformChip("+$hiddenPlatformsCount"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      game.genre,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget platformChip(String platform) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        platform,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void showGameDetails(BuildContext context) {
    final hasImage = game.imageUrl.trim().isNotEmpty;
    final platforms = game.platforms.isEmpty
        ? ["Plataforma não informada"]
        : game.platforms;
    final description = game.description.trim().isEmpty
        ? "Sem descrição disponível"
        : game.description;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: "Fechar detalhes",
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: hasImage
                        ? Image.network(
                            game.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.games,
                                color: Colors.white70,
                                size: 72,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.games,
                              color: Colors.white70,
                              size: 72,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.genre,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: platforms.map(platformChip).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
