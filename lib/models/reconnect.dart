/// Reconnect configuration for the client.
/// Reconnect config takes three parameters:
/// - mode: ReconnectMode, which can be linear or exponential.
/// - interval: Duration, the time interval between reconnection attempts. If mode is linear, the interval is fixed.
/// If mode is exponential, the interval is multiplied by 2 after each attempt.
/// - maxAttempts: int, the maximum number of reconnection attempts.
/// - onReconnect: Function, a callback function that is called when the client reconnects.
class ReconnectConfig {
  final ReconnectMode mode;
  final Duration interval;
  final Function()? onReconnect;
  final int maxAttempts;
  final Future<Map<String, String>> Function()? reconnectHeader;

  ReconnectConfig({
    required this.mode,
    this.interval = const Duration(seconds: 2),
    this.maxAttempts = 5,
    this.reconnectHeader,
    this.onReconnect,
  });
}

/// Enum for reconnect mode.
enum ReconnectMode { linear, exponential }
