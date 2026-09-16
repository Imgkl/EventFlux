import 'dart:math';

import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/utils.dart';
import 'package:flutter/foundation.dart';

/// Stateful reconnection manager.
///
/// Owns backoff state (`_maxAttempts`, `_interval`) and scheduling logic.
/// Accepts closures for actions so it never holds a back-reference to
/// [EventFlux] — keeping the dependency one-directional.
class ReconnectStrategy {
  ReconnectConfig? _config;
  int _maxAttempts = 0;
  int _interval = 0;
  int _currentAttempt = 0;

  /// Random instance — exposed for deterministic testing.
  @visibleForTesting
  static Random random = Random();

  bool get hasConfig => _config != null;
  ReconnectConfig? get config => _config;
  int get currentAttempt => _currentAttempt;

  /// Called in `connect()` to set up reconnection parameters.
  void initialize(ReconnectConfig config) {
    _config = config;
    _maxAttempts = config.maxAttempts;
    _interval = config.interval.inSeconds;
  }

  /// Called on a successful (200) response to reset backoff state.
  void resetOnSuccess() {
    if (_config != null) {
      _interval = _config!.interval.inSeconds;
      _maxAttempts = _config!.maxAttempts;
      _currentAttempt = 0;
    }
  }

  /// Called in `disconnect()` to prevent further reconnection.
  void clear() {
    _config = null;
  }

  /// Updates the retry interval — used to apply server-sent `retry:` values.
  void updateRetryInterval(Duration interval) {
    _interval = interval.inSeconds;
  }

  /// Adds random jitter of 0–25% to a base duration.
  Duration _withJitter(Duration base) {
    final jitterFraction = random.nextDouble() * 0.25;
    return base +
        Duration(milliseconds: (base.inMilliseconds * jitterFraction).round());
  }

  /// Schedules a reconnect attempt if conditions are met.
  ///
  /// Returns `true` if a reconnect was scheduled, `false` otherwise.
  ///
  /// Parameters are closures to avoid coupling to EventFlux:
  /// - [isExplicitDisconnect]: checked at two points (before delay and inside
  ///   the delayed callback) to honour disconnect during the wait.
  /// - [refreshHeaders]: called to get updated headers from `reconnectHeader`.
  /// - [startConnection]: called to re-initiate the connection.
  /// - [stopConnection]: called when max attempts are exhausted.
  Future<bool> attemptIfNeeded({
    required bool autoReconnect,
    required bool Function() isExplicitDisconnect,
    required String? tag,
    required Future<void> Function() refreshHeaders,
    required void Function() startConnection,
    required Future<void> Function() stopConnection,
  }) async {
    if (!autoReconnect || isExplicitDisconnect() || _config == null) {
      return false;
    }

    // Check max attempts (-1 means unlimited)
    if (_maxAttempts != -1) {
      if (_maxAttempts == 0) {
        await stopConnection();
        return false;
      }
      _maxAttempts--;
    }

    _currentAttempt++;

    // Refresh headers if configured
    await refreshHeaders();

    // Bail out if disconnect happened during header refresh
    if (isExplicitDisconnect()) {
      eventFluxLog(
        "Explicit disconnection. Aborting retry attempts",
        LogEvent.info,
        tag,
      );
      return false;
    }

    late Duration actualDelay;

    switch (_config!.mode) {
      case ReconnectMode.linear:
        actualDelay = _withJitter(_config!.interval);
        await Future.delayed(actualDelay, () {
          if (!isExplicitDisconnect()) {
            eventFluxLog(
              "Trying again in ${actualDelay.inMilliseconds}ms",
              LogEvent.reconnect,
              tag,
            );
            startConnection();
          }
        });
        break;

      case ReconnectMode.exponential:
        actualDelay = _withJitter(Duration(seconds: _interval));
        await Future.delayed(actualDelay, () {
          if (!isExplicitDisconnect()) {
            eventFluxLog(
              "Trying again in ${actualDelay.inMilliseconds}ms",
              LogEvent.reconnect,
              tag,
            );
            _interval = _interval * 2;
            // Cap at maxBackoff
            if (_interval > _config!.maxBackoff.inSeconds) {
              _interval = _config!.maxBackoff.inSeconds;
            }
            startConnection();
          }
        });
        break;
    }

    _config?.onReconnect?.call(_currentAttempt, actualDelay);
    return true;
  }
}
