---
name: eventflux-usage
description: Integrate, debug, or migrate EventFlux SSE connections in Dart and Flutter apps.
---

# EventFlux usage

This skill covers the public EventFlux v3 API. Check the app's resolved `eventflux` version before applying migration guidance. Keep the app's existing ownership and state-management patterns.

## Connection ownership and subscriptions

- Import `package:eventflux/eventflux.dart`.
- Use `EventFlux.spawn()` when a screen, service, or request owns an independent connection. Use `EventFlux.instance` only when callers intentionally share one connection and its lifecycle.
- `connect()` returns `void`. Receive the stream through `onSuccessCallback`; report connection failures through `onError`.
- Subscribe inside `onSuccessCallback`, which runs again after a successful reconnect. Cancel the previous subscription when replacing it.
- Each response stream is single-subscription. Choose either `response.stream` or `response.where('event-name')` for that listener; do not independently listen to both. Filtering matches the server's explicit event name.
- Close the owned connection with `disconnect()` and cancel the consumer subscription when its owner is disposed. Cancelling the consumer subscription alone does not disconnect EventFlux.
- Repeated `connect()` calls on an active or pending instance are ignored. For a different endpoint, disconnect first or create another instance.

## Example: a feed with an explicit lifetime

The caller supplies `stop`, completing it when the feed is no longer needed. In Flutter, complete it from the owning lifecycle and guard UI callbacks with `mounted` as appropriate.

```dart
import 'dart:async';

import 'package:eventflux/eventflux.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> consumeEvents({
  required String url,
  required Future<void> stop,
  required void Function(EventFluxData) onData,
  required void Function(EventFluxException) onError,
}) async {
  final client = EventFlux.spawn();
  StreamSubscription<EventFluxData>? subscription;

  try {
    client.connect(
      EventFluxConnectionType.get,
      url,
      webConfig: kIsWeb ? WebConfig() : null,
      autoReconnect: true,
      reconnectConfig: ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: const Duration(seconds: 2),
        maxAttempts: 5,
        maxBackoff: const Duration(seconds: 30),
      ),
      onSuccessCallback: (response) {
        unawaited(subscription?.cancel());
        subscription = response?.stream?.listen(onData);
      },
      onError: onError,
    );
    await stop;
  } finally {
    await client.disconnect();
    await subscription?.cancel();
  }
}
```

Use `autoReconnect: false` for intentionally finite streams, such as a single generated answer, unless repeating the request is intended. With automatic reconnect enabled, normal server EOF can open another connection.

## Reconnect and error handling

- `autoReconnect: true` requires a `ReconnectConfig`. Retry attempts and backoff reset after a successful connection; `maxAttempts` is not a lifetime connection limit.
- `onReconnect` accepts `(int attempt, Duration delay)`. Select linear or exponential mode for the endpoint; exponential delay includes jitter.
- `reconnectHeader` is asynchronous and returns replacement headers. Include required headers such as `Accept`, plus refreshed authorization. It does not merge the original headers for you.
- The client carries the last SSE event ID into `Last-Event-ID` on reconnect. Explicit disconnect clears that state for the next connection.
- Among HTTP error responses, 5xx, 408, and 429 are retryable; other statuses go to `onError` without automatic retry. Connection/stream failures and EOF also enter the reconnect path when enabled.
- Optional `ReconnectConfig.connectionTimeout` detects idle connections. Heartbeat comments reset it. Choose a timeout compatible with the server's heartbeat or expected silence.
- `EventFluxException` exposes `message`, `statusCode`, `originalError`, and `stackTrace`. An interceptor returning `null` from `onError` suppresses the consumer error callback; it does not by itself disable reconnection.

## Requests, data, and web

- Successful SSE endpoints must return HTTP 200 and `Content-Type: text/event-stream`. Other successful HTTP status codes are not accepted as SSE connections.
- Every web connection requires `WebConfig`, even when supplying a custom HTTP adapter. Server CORS settings must permit the browser request. Browser caching uses `WebConfig.cache`; EventFlux removes `Cache-Control` request headers on web.
- The `header` argument replaces the default map. Include `Accept: text/event-stream` when supplying custom headers. For a JSON POST, pass a map as `body` and include `Content-Type: application/json` when the endpoint requires it; EventFlux encodes the map.
- `multipartRequest: true` or non-empty `files` selects multipart encoding. Multipart field values must be strings; let the HTTP client generate the boundary/content type.
- `EventFluxData.data` is the payload string. Access `data.json` only for JSON payloads and handle `FormatException`; the getter decodes and caches JSON, it does not validate the server's payload schema.
- `abortTrigger` takes a `Future<void>` to abort a request. Use a fresh trigger for a new operation; use `disconnect()` when the intent is to end the connection lifecycle and prevent retries.
- Interceptor `onResponse` must leave the response body available for SSE parsing. Inspect headers/status without consuming the stream.

## Migrating v2 integrations

- Update zero-argument reconnect callbacks to `(int attempt, Duration delay)`.
- Supply `WebConfig` on web and check the v3 SDK constraints before changing the dependency.
- SSE payloads no longer include the parser-added trailing newline. Check consumers that previously stripped or relied on it.
- Native default headers include `Cache-Control: no-store`; custom header maps replace defaults.
- Exercise the app's disconnect/backgrounding path, reconnection, and event parsing after migration. Consumer subscriptions and application-owned controllers still need their own lifecycle cleanup.
