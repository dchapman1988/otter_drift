import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_session.dart';
import 'backend.dart';
import 'secure_logger.dart';

enum GameSessionSubmissionStatus { submitted, queuedOffline, failed }

class GameSessionSubmissionResult {
  const GameSessionSubmissionResult({required this.status, this.error});

  final GameSessionSubmissionStatus status;
  final Object? error;
}

class GameSessionSyncEvent {
  const GameSessionSyncEvent({
    required this.session,
    required this.status,
    this.error,
  });

  final GameSession session;
  final GameSessionSubmissionStatus status;
  final Object? error;
}

class GameSessionSyncService {
  GameSessionSyncService._();

  static final GameSessionSyncService instance = GameSessionSyncService._();

  static const String _storageKey = 'pending_game_sessions';

  final Connectivity _connectivity = Connectivity();
  final List<GameSession> _pendingSessions = [];
  final StreamController<GameSessionSyncEvent> _syncEventsController =
      StreamController<GameSessionSyncEvent>.broadcast();

  SharedPreferences? _prefs;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isSyncing = false;

  Stream<GameSessionSyncEvent> get syncEvents => _syncEventsController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    SecureLogger.logDebug('Initializing GameSessionSyncService');

    _prefs = await SharedPreferences.getInstance();
    await _loadPendingSessions();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      if (result != ConnectivityResult.none) {
        SecureLogger.logDebug('Connectivity restored, attempting sync');
        await syncPendingSessions();
      }
    });

    _isInitialized = true;

    if (!await _isOffline()) {
      await syncPendingSessions();
    }
  }

  Future<GameSessionSubmissionResult> submit(GameSession session) async {
    await initialize();

    if (await _isOffline()) {
      SecureLogger.logInfo(
        'Device offline, queueing game session ${session.sessionId}',
      );
      await _queueSession(session);
      return const GameSessionSubmissionResult(
        status: GameSessionSubmissionStatus.queuedOffline,
      );
    }

    final attemptResult = await _trySubmit(session);
    if (attemptResult.status == GameSessionSubmissionStatus.submitted) {
      SecureLogger.logInfo(
        'Game session ${session.sessionId} submitted successfully',
      );
      _syncEventsController.add(
        GameSessionSyncEvent(
          session: session,
          status: GameSessionSubmissionStatus.submitted,
        ),
      );
      return attemptResult;
    }

    if (await _isOffline()) {
      SecureLogger.logInfo(
        'Submission failed due to connectivity, queueing session ${session.sessionId}',
      );
      await _queueSession(session);
      return const GameSessionSubmissionResult(
        status: GameSessionSubmissionStatus.queuedOffline,
      );
    }

    SecureLogger.logError('Failed to submit game session ${session.sessionId}');
    _syncEventsController.add(
      GameSessionSyncEvent(
        session: session,
        status: GameSessionSubmissionStatus.failed,
        error: attemptResult.error,
      ),
    );
    return GameSessionSubmissionResult(
      status: GameSessionSubmissionStatus.failed,
      error: attemptResult.error,
    );
  }

  Future<void> syncPendingSessions() async {
    await initialize();

    if (_pendingSessions.isEmpty) {
      return;
    }

    if (_isSyncing) {
      return;
    }

    if (await _isOffline()) {
      SecureLogger.logDebug(
        'Skipping sync while offline (pending=${_pendingSessions.length})',
      );
      return;
    }

    _isSyncing = true;

    try {
      SecureLogger.logInfo(
        'Attempting to sync ${_pendingSessions.length} queued game sessions',
      );

      final successfulSessions = <GameSession>[];

      for (final session in List<GameSession>.from(_pendingSessions)) {
        final result = await _trySubmit(session);
        if (result.status == GameSessionSubmissionStatus.submitted) {
          successfulSessions.add(session);
          _syncEventsController.add(
            GameSessionSyncEvent(
              session: session,
              status: GameSessionSubmissionStatus.submitted,
            ),
          );
        } else if (await _isOffline()) {
          SecureLogger.logInfo('Connectivity lost during sync, stopping early');
          break;
        } else {
          _syncEventsController.add(
            GameSessionSyncEvent(
              session: session,
              status: GameSessionSubmissionStatus.failed,
              error: result.error,
            ),
          );
        }
      }

      if (successfulSessions.isNotEmpty) {
        _pendingSessions.removeWhere(
          (session) => successfulSessions.contains(session),
        );
        await _persistQueue();
        SecureLogger.logInfo(
          'Successfully synced ${successfulSessions.length} game sessions',
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _syncEventsController.close();
  }

  Future<GameSessionSubmissionResult> _trySubmit(GameSession session) async {
    try {
      final response = await BackendService.saveScore(
        sessionId: session.sessionId,
        playerName: session.playerName,
        seed: session.seed,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        finalScore: session.finalScore,
        gameDuration: session.gameDuration,
        maxSpeedReached: session.maxSpeedReached,
        obstaclesAvoided: session.obstaclesAvoided,
        liliesCollected: session.liliesCollected,
        heartsCollected: session.heartsCollected,
      );
      if (response != null) {
        return const GameSessionSubmissionResult(
          status: GameSessionSubmissionStatus.submitted,
        );
      }

      return const GameSessionSubmissionResult(
        status: GameSessionSubmissionStatus.failed,
        error: 'Empty response from backend',
      );
    } catch (e, stackTrace) {
      SecureLogger.logError(
        'Error submitting game session ${session.sessionId}',
        error: e,
        stackTrace: stackTrace,
      );
      return GameSessionSubmissionResult(
        status: GameSessionSubmissionStatus.failed,
        error: e,
      );
    }
  }

  Future<void> _queueSession(GameSession session) async {
    final alreadyQueued = _pendingSessions.any(
      (pending) => pending.sessionId == session.sessionId,
    );

    if (!alreadyQueued) {
      _pendingSessions.add(session);
      await _persistQueue();
    }

    _syncEventsController.add(
      GameSessionSyncEvent(
        session: session,
        status: GameSessionSubmissionStatus.queuedOffline,
      ),
    );
  }

  Future<void> _loadPendingSessions() async {
    final storedSessions = _prefs?.getStringList(_storageKey) ?? <String>[];
    _pendingSessions
      ..clear()
      ..addAll(
        storedSessions
            .map(GameSession.fromStorageString)
            .toList(growable: true),
      );

    if (_pendingSessions.isNotEmpty) {
      SecureLogger.logInfo(
        'Loaded ${_pendingSessions.length} pending game sessions from storage',
      );
    }
  }

  Future<void> _persistQueue() async {
    final serialized = _pendingSessions
        .map((s) => s.toStorageString())
        .toList();
    await _prefs?.setStringList(_storageKey, serialized);
  }

  Future<bool> _isOffline() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.none;
  }
}
