import 'dart:developer';

/// Enum to represent different types of EventFlux Log.
enum LogEvent {
  info,
  error,
  reconnect,
}

/// Returns the emoji corresponding to the given [event].
_getEmoji(LogEvent event) {
  switch (event) {
    case LogEvent.info:
      return 'ℹ️';
    case LogEvent.error:
      return '❌';
    case LogEvent.reconnect:
      return '🔄';
  }
}

/// Logs the given [message] with the corresponding [event] and [tag].
void eventFluxLog(String message, LogEvent event, String? tag) {
  log('${_getEmoji(event)} $message',
      name: tag ?? 'EventFlux');
}
