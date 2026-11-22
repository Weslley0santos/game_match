import '../../../data/services/game_service.dart';
import '../../../data/services/rating_service.dart';
import '../../../data/models/game_model.dart';

class SwipeController {
  final GameService _service = GameService();
  final RatingService _ratingService = RatingService();

  List<GameModel> games = [];

  int currentIndex = 0;

  bool isLoading = false;
  bool hasLoadError = false;

  final List<GameModel> likedGames = [];
  final List<GameModel> dislikedGames = [];
  final List<GameModel> favoriteGames = [];

  Future<void> loadGames(int userId, {bool includeRatedGames = false}) async {
    isLoading = true;
    hasLoadError = false;
    try {
      final allGames = await _service.fetchGames();

      if (includeRatedGames) {
        games = allGames;
      } else {
        final ratings = await _ratingService.getUserRatings(userId);
        final ratedGameIds = ratings
            .map((rating) => rating['gameId'])
            .whereType<int>()
            .toSet();

        games = allGames
            .where((game) => game.id != null && !ratedGameIds.contains(game.id))
            .toList();
      }

      currentIndex = 0;
    } catch (e) {
      hasLoadError = true;
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

    await _ratingService.sendRating(
      gameId: game.id!,
      type: "LIKE",
    );

    likedGames.add(game);
    nextGame();
  }

  Future<void> dislikeGame(int userId) async {
    final game = currentGame;
    if (game == null) return;

    await _ratingService.sendRating(
      gameId: game.id!,
      type: "DISLIKE",
    );

    dislikedGames.add(game);
    nextGame();
  }

  Future<void> favoriteGame(int userId) async {
    final game = currentGame;
    if (game == null) return;

    await _ratingService.sendRating(
      gameId: game.id!,
      type: "FAVORITE",
    );

    favoriteGames.add(game);
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
