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
    return GameModel(
      id: json['id'],
      title: json['title'],
      genre: json['genre'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      platforms: (json['platforms'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}
