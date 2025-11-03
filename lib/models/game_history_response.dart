import 'game_history_entry.dart';

class GameHistoryResponse {
  final String username;
  final int totalGames;
  final List<GameHistoryEntry> games;
  final int limit;
  final int offset;
  final int total;
  final int returned;

  const GameHistoryResponse({
    required this.username,
    required this.totalGames,
    required this.games,
    required this.limit,
    required this.offset,
    required this.total,
    required this.returned,
  });

  factory GameHistoryResponse.fromJson(Map<String, dynamic> json) {
    final gamesList = json['game_history'] as List<dynamic>? ?? [];
    final player = json['player'] as Map<String, dynamic>? ?? {};
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return GameHistoryResponse(
      username: player['username'] as String? ?? '',
      totalGames: player['total_games'] as int? ?? 0,
      games: gamesList
          .map((gameJson) => GameHistoryEntry.fromJson(
                gameJson as Map<String, dynamic>,
              ))
          .toList(),
      limit: pagination['limit'] as int? ?? 20,
      offset: pagination['offset'] as int? ?? 0,
      total: pagination['total'] as int? ?? gamesList.length,
      returned: pagination['returned'] as int? ?? gamesList.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'total_games': totalGames,
      'game_history': games.map((g) => g.toJson()).toList(),
      'pagination': {
        'limit': limit,
        'offset': offset,
        'total': total,
        'returned': returned,
      },
    };
  }

  bool get hasMore => offset + returned < total;

  @override
  String toString() {
    return 'GameHistoryResponse(username: $username, totalGames: $totalGames, returned: $returned/$total)';
  }
}

