import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/data/models/game_model.dart';
import 'package:game_match/features/swipe/widgets/game_card.dart';

void main() {
  testWidgets('card principal solicita a capa da IGDB em alta resolucao', (
    tester,
  ) async {
    const thumbnailUrl =
        'https://images.igdb.com/igdb/image/upload/t_thumb/example.jpg';
    final game = GameModel(
      title: 'Jogo',
      genre: 'Genero',
      description: 'Descricao',
      imageUrl: thumbnailUrl,
      platforms: const ['PC'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameCard(game: game)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;

    expect(
      provider.url,
      'https://images.igdb.com/igdb/image/upload/t_1080p/example.jpg',
    );
  });

  testWidgets('card principal exibe a capa inteira sem cortes', (tester) async {
    final game = GameModel(
      title: 'Jogo',
      genre: 'Genero',
      description: 'Descricao',
      imageUrl: 'https://example.com/capa.jpg',
      platforms: const ['PC'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameCard(game: game)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));

    expect(image.fit, BoxFit.contain);
  });
}
