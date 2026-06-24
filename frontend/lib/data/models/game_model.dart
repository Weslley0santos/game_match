class GameModel {
  final int? id;
  final String title;
  final String genre;
  final String description;
  final String imageUrl;
  final List<String> platforms;

  GameModel({
    this.id,
    required this.title,
    required this.genre,
    required this.description,
    required this.imageUrl,
    required this.platforms,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    final platformsData = json['platforms'];
    final parsedPlatforms = platformsData is List
        ? platformsData
            .map((platform) => platform?.toString().trim() ?? "")
            .where((platform) => platform.isNotEmpty)
            .toList()
        : <String>[];

    return GameModel(
      id: json['id'] is int ? json['id'] : null,
      title: _textOrFallback(json['title'], "Jogo sem nome"),
      genre: _textOrFallback(json['genre'], "Gênero não informado"),
      description: _textOrFallback(
        json['description'],
        "Sem descrição disponível",
      ),
      imageUrl: _textOrFallback(json['imageUrl'], ""),
      platforms: parsedPlatforms.isEmpty
          ? ["Plataforma não informada"]
          : parsedPlatforms,
    );
  }

  static String _textOrFallback(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
