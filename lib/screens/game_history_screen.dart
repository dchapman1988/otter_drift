import 'package:flutter/material.dart';
import '../models/game_history_entry.dart';
import '../models/game_history_response.dart';
import '../services/player_api_service.dart';

class GameHistoryScreen extends StatefulWidget {
  final String username;

  const GameHistoryScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  GameHistoryResponse? _gameHistory;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
  }

  Future<void> _loadGameHistory({bool loadMore = false}) async {
    if (_isLoading || (_isLoadingMore && loadMore)) {
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentOffset = 0;
        _errorMessage = null;
      }
    });

    try {
      final gameHistory = await PlayerApiService.getPlayerGameHistoryByUsername(
        widget.username,
        limit: _pageSize,
        offset: loadMore ? _currentOffset : 0,
      );

      if (mounted) {
        setState(() {
          if (loadMore && _gameHistory != null && gameHistory != null) {
            // Append new games to existing list
            final updatedGames = [
              ..._gameHistory!.games,
              ...gameHistory.games,
            ];
            _gameHistory = GameHistoryResponse(
              username: gameHistory.username,
              totalGames: gameHistory.totalGames,
              games: updatedGames,
              limit: gameHistory.limit,
              offset: gameHistory.offset,
              total: gameHistory.total,
              returned: updatedGames.length,
            );
            _currentOffset = updatedGames.length;
          } else {
            _gameHistory = gameHistory;
            _currentOffset = gameHistory?.returned ?? 0;
          }
          _isLoading = false;
          _isLoadingMore = false;
          if (gameHistory == null) {
            _errorMessage = 'Failed to load game history';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to load game history: $e';
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '${dateTime.year}-$month-$day';
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Game History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4ECDC4)),
            onPressed: (_isLoading || _isLoadingMore)
                ? null
                : () => _loadGameHistory(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _loadGameHistory(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ECDC4),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _gameHistory == null || _gameHistory!.games.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                color: Colors.white38,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No game history yet',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start playing to see your game history!',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadGameHistory(),
                        color: const Color(0xFF4ECDC4),
                        child: Column(
                          children: [
                            // Header with total games
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Games: ${_gameHistory!.totalGames}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Showing ${_gameHistory!.games.length} of ${_gameHistory!.total}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Game list
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _gameHistory!.games.length +
                                    (_gameHistory!.hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _gameHistory!.games.length) {
                                    // Load more button
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Center(
                                        child: _isLoadingMore
                                            ? const CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF4ECDC4),
                                                ),
                                              )
                                            : ElevatedButton.icon(
                                                onPressed: () =>
                                                    _loadGameHistory(
                                                      loadMore: true,
                                                    ),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text('Load More'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF4ECDC4),
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                      ),
                                    );
                                  }

                                  final game = _gameHistory!.games[index];
                                  return _buildGameHistoryEntry(game);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildGameHistoryEntry(GameHistoryEntry game) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with score and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFF4ECDC4),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatScore(game.finalScore),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(game.endedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatChip(
                Icons.timer,
                _formatDuration(game.gameDuration),
              ),
              _buildStatChip(
                Icons.landscape,
                '${game.obstaclesAvoided} obstacles',
              ),
              _buildStatChip(
                Icons.local_florist,
                '${game.liliesCollected} lilies',
              ),
              _buildStatChip(
                Icons.favorite,
                '${game.heartsCollected} hearts',
              ),
              _buildStatChip(
                Icons.speed,
                '${game.maxSpeedReached.toStringAsFixed(1)} max speed',
              ),
            ],
          ),
          // Achievements earned
          if (game.achievementsEarned > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Earned ${game.achievementsEarned} achievement${game.achievementsEarned > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white54,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

