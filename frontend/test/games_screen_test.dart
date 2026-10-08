import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_match/features/games/screens/games_screen.dart';

void main() {
  testWidgets('cabecalho identifica o jogo selecionado alem do nome', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameDetailHeader(
            title: 'Hogwarts Legacy',
            imageUrl: 'https://example.com/hogwarts.jpg',
            compatibleFriends: 3,
            favoriteFriends: 1,
          ),
        ),
      ),
    );

    expect(find.text('Hogwarts Legacy'), findsOneWidget);
    expect(find.text('3 amigos interessados · 1 quer jogar'), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;
    expect(provider.url, 'https://example.com/hogwarts.jpg');
  });
}
