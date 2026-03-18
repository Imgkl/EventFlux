<div align="center"><img src="https://i.ibb.co/tHK94xW/Untitled-2024-01-10-1728.png" width="200"/></div>

# EventFlux

A Dart package for Server-Sent Events done right — WHATWG spec-compliant parsing, auto-reconnect with exponential backoff, request/response interceptors, mid-flight abort, idle timeout detection, and web platform support out of the box.

## Platform Support

| Android | iOS | Web | MacOS | Windows | Linux |
|---------|-----|-----|-------|---------|-------|
| ✅ | ✅ | ✅ | ✅ | ❓ | ❓ |

Windows and Linux should work but haven't been battle-tested yet — PRs welcome if you get there first.

## Features 🌟

- 📜 **WHATWG SSE spec-compliant** event stream parsing with persistent `lastEventId` and `retry:` field support
- 🔄 **Auto-reconnect** with linear or exponential backoff, random jitter, and configurable `maxBackoff` cap
- 🔗 **Interceptor chain** — hook into request, response, and error lifecycle stages
- 🛑 **Mid-flight abort** via a `Future<void>` trigger
- ⏱️ **Idle timeout detection** — drops the connection if no data arrives within a configured duration
- 🌐 **Web platform support** with CORS, credentials, and caching configuration via `WebConfig`
- 🔍 **Event filtering** by type using `response.where()`
- 📎 **Multipart request** support
- 🏗️ **Singleton** (`EventFlux.instance`) and **multiple independent connections** (`EventFlux.spawn()`)
- 🔌 **Pluggable HTTP clients** via `HttpClientAdapter`
- 🧠 **Smart error classification** — only 5xx, 408, and 429 trigger auto-reconnect

## Migrating from v2? FYI. 🔄
<details>
<summary>Here</summary>

If you're upgrading from v2, here's what changed:

#### Breaking
- `onReconnect` callback signature changed from `()` to `(int attempt, Duration delay)`
- Default request headers now include `Cache-Control: no-store`
- Minimum Dart SDK raised to `>=3.4.0`, Flutter `>=3.0.0`
- `webConfig` is now required when running on web

#### New in v3
- `EventFluxStatus.reconnecting` status value
- `originalError` and `stackTrace` fields on `EventFluxException`
- Request/response/error interceptor chain via `interceptors` parameter
- Mid-flight abort support via `abortTrigger` parameter
- Idle timeout detection via `connectionTimeout` on `ReconnectConfig`
- `maxBackoff` on `ReconnectConfig` to cap exponential backoff
- WHATWG-compliant SSE parser with persistent `lastEventId`, `retry:` field support, and U+2028 sanitization

</details>

## Installation 📦

```yaml
dependencies:
  eventflux: ^3.0.1-dev
```

Requires Dart SDK `>=3.4.0` and Flutter `>=3.0.0`.

## Usage 🔧

<details>
<summary><b>Basic Connection</b> — Connect to an SSE endpoint in a few lines</summary>

```dart
import 'package:eventflux/eventflux.dart';

void main() {
  EventFlux.instance.connect(
    EventFluxConnectionType.get,
    'https://example.com/events',
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((EventFluxData data) {
        print('Event: ${data.event}');
        print('Data: ${data.data}');
      });
    },
    onError: (EventFluxException error) {
      print('Error: $error');
    },
    onConnectionClose: () {
      print('Connection closed');
    },
  );
}
```

</details>

<details>
<summary><b>Auto-Reconnect</b> — Exponential backoff with jitter and token refresh</summary>

```dart
import 'package:eventflux/eventflux.dart';

void main() {
  EventFlux.instance.connect(
    EventFluxConnectionType.get,
    'https://example.com/events',
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((data) {
        print('Data: ${data.data}');
      });
    },
    onError: (error) {
      print('Error: $error');
    },
    autoReconnect: true,
    reconnectConfig: ReconnectConfig(
      mode: ReconnectMode.exponential,
      interval: Duration(seconds: 2),
      maxAttempts: 10,
      maxBackoff: Duration(seconds: 30),
      connectionTimeout: Duration(seconds: 60),
      onReconnect: (int attempt, Duration delay) {
        print('Reconnect attempt $attempt after $delay');
      },
      reconnectHeader: () async {
        String newToken = await refreshAccessToken();
        return {
          'Authorization': 'Bearer $newToken',
          'Accept': 'text/event-stream',
        };
      },
    ),
  );
}
```

</details>

<details>
<summary><b>Interceptors</b> — Inject auth headers, log responses, suppress errors</summary>

```dart
import 'package:eventflux/eventflux.dart';
import 'package:http/http.dart';

class AuthInterceptor extends EventFluxInterceptor {
  @override
  Future<BaseRequest> onRequest(BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer my-token';
    return request;
  }

  @override
  Future<StreamedResponse> onResponse(StreamedResponse response) async {
    print('Response status: ${response.statusCode}');
    return response;
  }

  @override
  Future<EventFluxException?> onError(EventFluxException exception) async {
    print('Intercepted error: $exception');
    // Return null to suppress the error, or return exception to propagate it
    return exception;
  }
}

void main() {
  EventFlux.instance.connect(
    EventFluxConnectionType.get,
    'https://example.com/events',
    interceptors: [AuthInterceptor()],
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((data) {
        print('Data: ${data.data}');
      });
    },
    onError: (error) {
      print('Error: $error');
    },
  );
}
```

</details>

<details>
<summary><b>Abort a Connection</b> — Cancel an in-flight request at any time</summary>

```dart
import 'dart:async';
import 'package:eventflux/eventflux.dart';

void main() {
  final completer = Completer<void>();

  EventFlux.instance.connect(
    EventFluxConnectionType.get,
    'https://example.com/events',
    abortTrigger: completer.future,
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((data) {
        print('Data: ${data.data}');
      });
    },
    onError: (error) {
      print('Error: $error');
    },
  );

  // Cancel the connection at any time
  Future.delayed(Duration(seconds: 10), () {
    completer.complete();
  });
}
```

</details>

<details>
<summary><b>Web Platform</b> — Configure CORS and credentials for browser SSE</summary>

```dart
import 'package:eventflux/eventflux.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  EventFlux.instance.connect(
    EventFluxConnectionType.get,
    'https://example.com/events',
    webConfig: kIsWeb
        ? WebConfig(
            mode: WebConfigRequestMode.cors,
            credentials: WebConfigRequestCredentials.omit,
          )
        : null,
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((data) {
        print('Data: ${data.data}');
      });
    },
    onError: (error) {
      print('Error: $error');
    },
  );
}
```

</details>

<details>
<summary><b>Multiple Connections</b> — Run independent SSE streams in parallel</summary>

```dart
import 'package:eventflux/eventflux.dart';

void main() {
  EventFlux e1 = EventFlux.spawn();
  EventFlux e2 = EventFlux.spawn();

  e1.connect(
    EventFluxConnectionType.get,
    'https://example.com/stream-1',
    tag: 'Stream 1',
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((data) {
        print('Stream 1: ${data.data}');
      });
    },
    onError: (error) {
      print('Stream 1 error: $error');
    },
  );

  e2.connect(
    EventFluxConnectionType.get,
    'https://example.com/stream-2',
    tag: 'Stream 2',
    onSuccessCallback: (EventFluxResponse? response) {
      response?.stream?.listen((data) {
        print('Stream 2: ${data.data}');
      });
    },
    onError: (error) {
      print('Stream 2 error: $error');
    },
  );

  // Disconnect both when done
  // await e1.disconnect();
  // await e2.disconnect();
}
```

</details>

**Event Filtering** — filter events by type using `where()`:

```dart
response?.where('message').listen((data) {
  print('Message event: ${data.data}');
});
```

<details>
<summary><b>API Reference 📚</b></summary>

### Connect

Connects to a server-sent event stream.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `type` | `EventFluxConnectionType` | HTTP method (`get` or `post`) | — |
| `url` | `String` | SSE stream URL | — |
| `onSuccessCallback` | `Function(EventFluxResponse?)` | Callback on successful connection (required) | — |
| `header` | `Map<String, String>` | HTTP headers | `{'Accept': 'text/event-stream', 'Cache-Control': 'no-store'}` |
| `onConnectionClose` | `Function()?` | Called when the connection closes | — |
| `autoReconnect` | `bool` | Auto-reconnect on disconnection | `false` |
| `reconnectConfig` | `ReconnectConfig?` | Reconnection settings (required if `autoReconnect` is true) | — |
| `onError` | `Function(EventFluxException)?` | Error callback | — |
| `body` | `Map<String, dynamic>?` | Request body for POST | — |
| `files` | `List<MultipartFile>?` | Files for multipart requests | — |
| `multipartRequest` | `bool` | Send as multipart | `false` |
| `tag` | `String?` | Debug tag (appears in logs) | — |
| `logReceivedData` | `bool` | Log received SSE data | `false` |
| `httpClient` | `HttpClientAdapter?` | Custom HTTP client | — |
| `webConfig` | `WebConfig?` | Web platform configuration (required on web) | — |
| `interceptors` | `List<EventFluxInterceptor>?` | Request/response/error interceptors | — |
| `abortTrigger` | `Future<void>?` | Future that aborts the connection when completed | — |

### ReconnectConfig

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `mode` | `ReconnectMode` | `linear` or `exponential` (required) | — |
| `interval` | `Duration` | Base retry interval | `Duration(seconds: 2)` |
| `maxAttempts` | `int` | Max reconnect attempts (-1 for unlimited) | `5` |
| `maxBackoff` | `Duration` | Cap for exponential backoff | `Duration(seconds: 30)` |
| `connectionTimeout` | `Duration?` | Idle timeout — drops connection if no data received | — |
| `onReconnect` | `void Function(int attempt, Duration delay)?` | Called on each reconnect attempt | — |
| `reconnectHeader` | `Future<Map<String, String>> Function()?` | Async header refresh for reconnect | — |

### EventFluxInterceptor

Subclass `EventFluxInterceptor` and override any of the following methods:

| Method | Signature | Description |
|--------|-----------|-------------|
| `onRequest` | `Future<BaseRequest> onRequest(BaseRequest request)` | Modify the request before sending (e.g., inject auth headers). Throw `EventFluxException` to abort. |
| `onResponse` | `Future<StreamedResponse> onResponse(StreamedResponse response)` | Inspect the response after receiving. Must not consume the stream body. |
| `onError` | `Future<EventFluxException?> onError(EventFluxException exception)` | Handle or suppress errors. Return `null` to suppress the exception. |

### EventFluxStatus

| Value | Description |
|-------|-------------|
| `connectionInitiated` | Connection process has started |
| `connected` | Successfully connected to the event stream |
| `reconnecting` | Auto-reconnect is in progress |
| `disconnected` | Connection has been closed |
| `error` | An error occurred during connection or disconnection |

### Disconnect

```dart
EventFluxStatus status = await EventFlux.instance.disconnect();
```

Returns a `Future<EventFluxStatus>` indicating the disconnection status.

### Spawn

```dart
EventFlux instance = EventFlux.spawn();
```

Returns a new independent `EventFlux` instance for managing parallel SSE connections.

</details>

## Benchmarks

v3 SSE parsing performance compared against v2.2.1 and [flutter_client_sse](https://pub.dev/packages/flutter_client_sse) 2.0.3.

| Operation | v2.2.1 | v3.0.0 | flutter_client_sse |
|---|--:|--:|--:|
| SSE Parser (1000 events × 20 lines) | 5,274 μs | 5,375 μs | 5,756 μs |
| SSE Parser (100 events × 200 lines) | 11,856 μs | **4,967 μs** | 19,872 μs |
| fromData (10K ops) | 3,618 μs | **1,172 μs** | 1,658 μs |
| Comment/Heartbeat (10K lines) | 649 μs | **565 μs** | 643 μs |
| Single Large Payload (100 × 10KB) | 1,150 μs | 1,175 μs | **892 μs** |
| Mixed Workload (~5K lines) | 2,203 μs | **1,623 μs** | 2,911 μs |

## Contributors 💜

EventFlux wouldn't exist without these people who believed it could be better.

<a href="https://github.com/Peetee06"><img src="https://github.com/Peetee06.png" width="60" style="border-radius:50%" alt="Peetee06"/></a>
<a href="https://github.com/pedrohsampaioo"><img src="https://github.com/pedrohsampaioo.png" width="60" style="border-radius:50%" alt="pedrohsampaioo"/></a>
<a href="https://github.com/krolmic"><img src="https://github.com/krolmic.png" width="60" style="border-radius:50%" alt="krolmic"/></a>
<a href="https://github.com/FelippeNO"><img src="https://github.com/FelippeNO.png" width="60" style="border-radius:50%" alt="FelippeNO"/></a>
<a href="https://github.com/jcarvalho-ptech"><img src="https://github.com/jcarvalho-ptech.png" width="60" style="border-radius:50%" alt="jcarvalho-ptech"/></a>
<a href="https://github.com/aabegg"><img src="https://github.com/aabegg.png" width="60" style="border-radius:50%" alt="aabegg"/></a>
<a href="https://github.com/jangruenwaldt"><img src="https://github.com/jangruenwaldt.png" width="60" style="border-radius:50%" alt="jangruenwaldt"/></a>
<a href="https://github.com/glukose"><img src="https://github.com/glukose.png" width="60" style="border-radius:50%" alt="glukose"/></a>

## Contributing 🤝

Contributions are welcome — open an issue or submit a pull request. Every bit helps.

## License

Licensed under [MIT](LICENSE).
