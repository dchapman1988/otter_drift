import 'leaderboard_entry.dart';

class LeaderboardResponse {
  final List<LeaderboardEntry> leaderboard;
  final int totalEntries;
  final int limit;

  const LeaderboardResponse({
    required this.leaderboard,
    required this.totalEntries,
    required this.limit,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final leaderboardList = json['leaderboard'] as List<dynamic>? ?? [];
    return LeaderboardResponse(
      leaderboard: leaderboardList
          .map(
            (entryJson) =>
                LeaderboardEntry.fromJson(entryJson as Map<String, dynamic>),
          )
          .toList(),
      totalEntries: json['total_entries'] as int,
      limit: json['limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      'total_entries': totalEntries,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'LeaderboardResponse(totalEntries: $totalEntries, limit: $limit, entries: ${leaderboard.length})';
  }
}
