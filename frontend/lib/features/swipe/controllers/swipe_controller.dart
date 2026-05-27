import '../../../data/services/game_service.dart';
import '../../../data/services/rating_service.dart';
import '../../../data/models/game_model.dart';

class SwipeController {
  final GameService _service = GameService();
  final RatingService _ratingService = RatingService();

  List<GameModel> games = [];

  int currentIndex = 0;

  bool isLoading = false;

  final List<GameModel> likedGames = [];
  final List<GameModel> dislikedGames = [];
  final List<GameModel> favoriteGames = [];

  Future<void> loadGames() async {
    try {
      isLoading = true;

      games = await _service.fetchGames();
    } catch (e) {
      print("Erro ao carregar jogos: $e");
    } finally {
      isLoading = false;
    }
  }

  GameModel? get currentGame {
    if (games.isEmpty || currentIndex >= games.length) {
      return null;
    }
    return games[currentIndex];
  }

  bool get finished => currentIndex >= games.length;

  Future<void> likeGame(int userId) async {
    final game = currentGame;
    if (game == null) return;

    likedGames.add(game);

    await _ratingService.sendRating(
      userId: userId,
      gameId: game.id!,
      type: "LIKE",
    );

    nextGame();
  }

  Future<void> dislikeGame(int userId) async {
    final game = currentGame;
    if (game == null) return;

    dislikedGames.add(game);

    await _ratingService.sendRating(
      userId: userId,
      gameId: game.id!,
      type: "DISLIKE",
    );

    nextGame();
  }

  Future<void> favoriteGame(int userId) async {
    final game = currentGame;
    if (game == null) return;

    favoriteGames.add(game);

    await _ratingService.sendRating(
      userId: userId,
      gameId: game.id!,
      type: "FAVORITE",
    );

    nextGame();
  }

  void nextGame() {
    currentIndex++;
  }

  void reset() {
    currentIndex = 0;
    likedGames.clear();
    dislikedGames.clear();
    favoriteGames.clear();
  }
}
