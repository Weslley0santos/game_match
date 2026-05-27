import 'package:flutter/material.dart';

import '../../../data/services/history_service.dart';
import '../../../data/services/game_service.dart';
import '../../../core/session/user_session.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final service = HistoryService();
  final gameService = GameService();

  List<dynamic> history = [];
  bool loading = true;
  String? error;

  Map<int, String> gameNames = {};
  Map<int, String> gameImages = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final user = UserSession.getUser();

      if (user == null || user['id'] == null) {
        setState(() {
          error = "Usuário não logado";
          loading = false;
        });
        return;
      }

      final games = await gameService.fetchGames();
      final data = await service.getUserHistory(user['id']);

      gameNames = {for (var g in games) g.id!: g.title};

      gameImages = {for (var g in games) g.id!: g.imageUrl};

      final Map<int, dynamic> grouped = {};
      for (var item in data) {
        grouped[item['gameId']] = item;
      }

      setState(() {
        history = grouped.values.toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Erro ao carregar histórico";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Histórico")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.white)),
            )
          : history.isEmpty
          ? const Center(
              child: Text(
                "Nenhum histórico encontrado",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];

                final gameId = item['gameId'];
                final type = item['type'];

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        gameImages[gameId] ?? "",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.games, color: Colors.white),
                      ),
                    ),

                    title: Text(
                      gameNames[gameId] ?? "Jogo desconhecido",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      type,
                      style: TextStyle(
                        color: type == "LIKE"
                            ? Colors.green
                            : type == "DISLIKE"
                            ? Colors.red
                            : Colors.amber,
                      ),
                    ),

                    trailing: Icon(
                      type == "LIKE"
                          ? Icons.favorite
                          : type == "DISLIKE"
                          ? Icons.close
                          : Icons.star,
                      color: type == "LIKE"
                          ? Colors.green
                          : type == "DISLIKE"
                          ? Colors.red
                          : Colors.amber,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
