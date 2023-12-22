import 'dart:developer';

enum LogEvent {
  info,
  error,
}

void eventFluxLog(String message, LogEvent event) {
  log(event == LogEvent.info ? 'ℹ️ $message' : '❌ $message', name: "EventFlux");
}
