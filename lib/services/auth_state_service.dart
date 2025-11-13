import 'dart:async';
import '../models/player.dart';
import 'player_api_service.dart';
import 'player_auth_service.dart';
import 'secure_logger.dart';

class AuthStateService {
  static final AuthStateService _instance = AuthStateService._internal();
  factory AuthStateService() => _instance;
  AuthStateService._internal();

  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();
  final StreamController<Player?> _playerController =
      StreamController<Player?>.broadcast();

  Stream<AuthState> get authStateStream => _authStateController.stream;
  Stream<Player?> get playerStream => _playerController.stream;

  AuthState _currentState = AuthState.unknown;
  Player? _currentPlayer;

  AuthState get currentState => _currentState;
  Player? get currentPlayer => _currentPlayer;

  /// Initialize the auth state service
  Future<void> initialize() async {
    await _checkAuthState();
  }

  /// Check current authentication state
  Future<void> _checkAuthState() async {
    try {
      SecureLogger.logDebug(
        'AuthStateService: Checking authentication state...',
      );
      final isAuthenticated = await PlayerAuthService.isAuthenticated();
      SecureLogger.logDebug(
        'AuthStateService: isAuthenticated = $isAuthenticated',
      );

      if (isAuthenticated) {
        final player = await PlayerAuthService.getCurrentPlayer();
        SecureLogger.logDebug(
          'AuthStateService: Got player: ${player?.username}',
        );
        _updateState(AuthState.authenticated, player);
        await _refreshPlayerFromApi();
      } else {
        SecureLogger.logDebug(
          'AuthStateService: Setting state to unauthenticated',
        );
        _updateState(AuthState.unauthenticated, null);
      }
    } catch (e) {
      SecureLogger.logError(
        'AuthStateService: Error checking auth state',
        error: e,
      );
      _updateState(AuthState.unauthenticated, null);
    }
  }

  /// Update authentication state
  void _updateState(AuthState state, Player? player) {
    SecureLogger.logDebug(
      'AuthStateService: Updating state to $state with player: ${player?.username ?? "null"}',
    );
    _currentState = state;
    _currentPlayer = player;
    _authStateController.add(state);
    _playerController.add(player);
  }

  /// Handle successful login/signup
  void onAuthSuccess(Player player) {
    SecureLogger.logDebug(
      'AuthStateService: onAuthSuccess called with player: ${player.username}',
    );
    SecureLogger.logDebug(
      'AuthStateService: Current state before update: $_currentState',
    );
    _updateState(AuthState.authenticated, player);
    SecureLogger.logDebug('AuthStateService: State updated to: $_currentState');
    SecureLogger.logDebug(
      'AuthStateService: Current player set to: ${_currentPlayer?.username}',
    );
    unawaited(_refreshPlayerFromApi());
  }

  /// Handle logout
  Future<void> onLogout() async {
    await PlayerAuthService.signOut();
    _updateState(AuthState.unauthenticated, null);
  }

  /// Handle guest mode
  void onGuestMode() {
    _updateState(AuthState.guest, null);
  }

  /// Refresh player data
  Future<void> refreshPlayer() async {
    if (_currentState == AuthState.authenticated) {
      final player = await PlayerAuthService.getCurrentPlayer();
      _updateState(AuthState.authenticated, player);
      await _refreshPlayerFromApi();
    }
  }

  /// Update player from storage (without fetching from API)
  /// Useful when player data has been updated locally (e.g., stats)
  Future<void> updatePlayerFromStorage() async {
    if (_currentState == AuthState.authenticated) {
      final player = await PlayerAuthService.getCurrentPlayer();
      if (player != null) {
        _updateState(AuthState.authenticated, player);
      }
    }
  }

  /// Check if user is in guest mode
  bool get isGuestMode => _currentState == AuthState.guest;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentState == AuthState.authenticated;

  /// Check if user is unauthenticated
  bool get isUnauthenticated => _currentState == AuthState.unauthenticated;

  /// Dispose resources
  void dispose() {
    _authStateController.close();
    _playerController.close();
  }

  Future<void> _refreshPlayerFromApi() async {
    if (_currentState != AuthState.authenticated) {
      return;
    }

    try {
      SecureLogger.logDebug('AuthStateService: Refreshing player from API');

      // Preserve current stats in case API doesn't return them or returns zeros
      final currentTotalScore = _currentPlayer?.totalScore ?? 0;
      final currentGamesPlayed = _currentPlayer?.gamesPlayed ?? 0;

      final latestPlayer = await PlayerApiService.getPlayerProfile();
      if (latestPlayer != null) {
        SecureLogger.logDebug(
          'AuthStateService: Player refreshed from API: ${latestPlayer.username}',
        );

        // Merge stats: prefer API stats if non-zero, otherwise preserve current stats
        // This prevents the profile API from overwriting valid stats with zeros
        // (The profile API might not have the latest stats, so we preserve what we have)
        final mergedPlayer = latestPlayer.copyWith(
          totalScore: (latestPlayer.totalScore > 0)
              ? latestPlayer.totalScore
              : currentTotalScore,
          gamesPlayed: (latestPlayer.gamesPlayed > 0)
              ? latestPlayer.gamesPlayed
              : currentGamesPlayed,
        );

        // Update stored player with merged data if stats were preserved
        if (mergedPlayer.totalScore != latestPlayer.totalScore ||
            mergedPlayer.gamesPlayed != latestPlayer.gamesPlayed) {
          await PlayerAuthService.updateStoredPlayer(mergedPlayer);
        }

        _updateState(AuthState.authenticated, mergedPlayer);
      } else {
        SecureLogger.logDebug(
          'AuthStateService: Player refresh returned null, keeping existing data',
        );
      }
    } catch (e) {
      SecureLogger.logError(
        'AuthStateService: Failed to refresh player from API',
        error: e,
      );
    }
  }
}

enum AuthState { unknown, unauthenticated, authenticated, guest }
