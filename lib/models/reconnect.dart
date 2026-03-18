/// Reconnect configuration for the client.
/// Reconnect config takes three parameters:
/// - mode: ReconnectMode, which can be linear or exponential.
/// - interval: Duration, the time interval between reconnection attempts. If mode is linear, the interval is fixed.
/// If mode is exponential, the interval is multiplied by 2 after each attempt.
/// - maxAttempts: int, the maximum number of reconnection attempts.
/// - onReconnect: Function, a callback function that is called when the client reconnects.
/// - maxBackoff: Duration, the maximum backoff duration for exponential mode.
/// - connectionTimeout: Duration, idle timeout — connection is dropped if no data received within this duration.
class ReconnectConfig {
  final ReconnectMode mode;
  final Duration interval;
  final void Function(int attempt, Duration delay)? onReconnect;
  final int maxAttempts;
  final Future<Map<String, String>> Function()? reconnectHeader;
  final Duration maxBackoff;
  final Duration? connectionTimeout;

  ReconnectConfig({
    required this.mode,
    this.interval = const Duration(seconds: 2),
    this.maxAttempts = 5,
    this.reconnectHeader,
    this.onReconnect,
    this.maxBackoff = const Duration(seconds: 30),
    this.connectionTimeout,
  });
}

/// Enum for reconnect mode.
enum ReconnectMode { linear, exponential }
