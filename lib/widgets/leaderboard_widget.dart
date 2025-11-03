import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../models/leaderboard_response.dart';
import '../services/player_api_service.dart';
import '../services/player_auth_service.dart';

class LeaderboardWidget extends StatefulWidget {
  final int initialLimit;
  final bool showLimitSelector;

  const LeaderboardWidget({
    Key? key,
    this.initialLimit = 100,
    this.showLimitSelector = true,
  }) : super(key: key);

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  LeaderboardResponse? _leaderboard;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _currentLimit = 100;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.initialLimit;
    _loadCurrentUser();
    _loadLeaderboard();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final player = await PlayerAuthService.getCurrentPlayer();
      if (mounted) {
        setState(() {
          _currentUsername = player?.username;
        });
      }
    } catch (e) {
      // Ignore errors loading current user
    }
  }

  Future<void> _loadLeaderboard({bool isRefresh = false}) async {
    // Prevent multiple concurrent calls - only block if we're already loading/refreshing
    if ((_isRefreshing || _isLoading) && !isRefresh) {
      return;
    }

    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final leaderboard = await PlayerApiService.getGlobalLeaderboard(
        limit: _currentLimit,
      );

      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
          _isLoading = false;
          _isRefreshing = false;
          if (leaderboard == null) {
            _errorMessage = 'Failed to load leaderboard';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Failed to load leaderboard: $e';
        });
      }
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1B15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: const Text(
          'Select Leaderboard Size',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLimitOption(10, 'Top 10'),
            const SizedBox(height: 8),
            _buildLimitOption(25, 'Top 25'),
            const SizedBox(height: 8),
            _buildLimitOption(50, 'Top 50'),
            const SizedBox(height: 8),
            _buildLimitOption(100, 'Top 100'),
            const SizedBox(height: 8),
            _buildLimitOption(500, 'Top 500'),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitOption(int limit, String label) {
    final isSelected = _currentLimit == limit;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4ECDC4) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF4ECDC4))
          : null,
      onTap: () {
        Navigator.pop(context);
        if (_currentLimit != limit) {
          setState(() {
            _currentLimit = limit;
          });
          _loadLeaderboard();
        }
      },
    );
  }

  String _getRankBadge(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
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
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      // Format as date
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '${dateTime.year}-$month-$day';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with limit selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.leaderboard,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Global Leaderboard',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_leaderboard != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_leaderboard!.totalEntries})',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (widget.showLimitSelector)
                    IconButton(
                      icon: const Icon(
                        Icons.tune,
                        color: Color(0xFF4ECDC4),
                      ),
                      onPressed: _showLimitDialog,
                      tooltip: 'Change limit',
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF4ECDC4)),
                    onPressed: (_isLoading || _isRefreshing) ? null : () => _loadLeaderboard(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            ),
          )
        else if (_errorMessage != null)
          Center(
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
                    onPressed: (_isLoading || _isRefreshing)
                        ? null
                        : () => _loadLeaderboard(),
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
        else if (_leaderboard == null || _leaderboard!.leaderboard.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.leaderboard_outlined,
                    color: Colors.white38,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No leaderboard entries yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to appear on the leaderboard!',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadLeaderboard(isRefresh: true),
              color: const Color(0xFF4ECDC4),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _leaderboard!.leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = _leaderboard!.leaderboard[index];
                  final isCurrentUser = entry.player?.username == _currentUsername;
                  return _buildLeaderboardEntry(entry, isCurrentUser);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF4ECDC4).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF4ECDC4).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              _getRankBadge(entry.rank),
              style: TextStyle(
                fontSize: entry.rank <= 3 ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: entry.rank <= 3 ? Colors.white : const Color(0xFF4ECDC4),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: entry.isGuest
                ? const Center(
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 24,
                    ),
                  )
                : entry.player?.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          entry.player!.avatarUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: 24,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4ECDC4),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          entry.playerName.isNotEmpty
                              ? entry.playerName.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
          ),
          const SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.playerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser
                              ? const Color(0xFF4ECDC4)
                              : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isGuest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Guest',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(entry.achievedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    if (entry.player?.username != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '@${entry.player!.username}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFF4ECDC4),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                _formatScore(entry.score),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}

