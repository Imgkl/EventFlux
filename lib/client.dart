/// Imports
library;

import 'dart:async';
import 'dart:convert';

import 'package:eventflux/enum.dart';
import 'package:eventflux/extensions/fetch_client_extension.dart';
import 'package:eventflux/http_client_adapter.dart';
import 'package:eventflux/models/base.dart';
import 'package:eventflux/models/data.dart';
import 'package:eventflux/models/exception.dart';
import 'package:eventflux/models/interceptor.dart';
import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/models/response.dart';
import 'package:eventflux/models/web_config/web_config.dart';
import 'package:eventflux/src/connection_config.dart';
import 'package:eventflux/src/interceptor_runner.dart';
import 'package:eventflux/src/reconnect_strategy.dart';
import 'package:eventflux/src/request_builder.dart';
import 'package:eventflux/src/sse_parser.dart';
import 'package:eventflux/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

/// A class for managing event-driven data streams using Server-Sent Events (SSE).
///
/// `EventFlux` facilitates the connection, disconnection, and management of SSE streams.
/// It implements the Singleton pattern to ensure a single instance handles SSE streams throughout the application.
class EventFlux extends EventFluxBase {
  EventFlux._();

  static final EventFlux _instance = EventFlux._();

  static EventFlux get instance => _instance;
  @visibleForTesting
  Client? client;
  StreamController<EventFluxData>? _streamController;
  bool _isExplicitDisconnect = false;
  StreamSubscription? _streamSubscription;
  EventFluxStatus _status = EventFluxStatus.disconnected;
  String? _tag;
  Function()? _onConnectionClose;
  Timer? _idleTimer;

  final SseParser _sseParser = SseParser();
  final ReconnectStrategy _reconnectStrategy = ReconnectStrategy();

  /// Factory method for spawning new instances of `EventFlux`.
  static EventFlux spawn() {
    return EventFlux._();
  }

  @override
  void connect(
    EventFluxConnectionType type,
    String url, {
    Map<String, String> header = const {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-store'
    },
    Function()? onConnectionClose,
    bool autoReconnect = false,
    ReconnectConfig? reconnectConfig,
    required Function(EventFluxResponse?) onSuccessCallback,
    Function(EventFluxException)? onError,
    HttpClientAdapter? httpClient,
    Map<String, dynamic>? body,
    String? tag,
    bool logReceivedData = false,
    List<MultipartFile>? files,
    bool multipartRequest = false,
    WebConfig? webConfig,
    List<EventFluxInterceptor>? interceptors,
    Future<void>? abortTrigger,
  }) {
    if (kIsWeb && webConfig == null) {
      throw ArgumentError('WebConfig must be provided on web');
    }
    // This check prevents redundant connection requests when a connection is already in progress.
    if (_status == EventFluxStatus.connected ||
        _status == EventFluxStatus.connectionInitiated ||
        _status == EventFluxStatus.reconnecting) {
      eventFluxLog('Already Connection in Progress, Skipping redundant request',
          LogEvent.info, _tag);
      return;
    }
    _status = EventFluxStatus.connectionInitiated;

    /// Set the tag for logging purposes.
    _tag = tag;

    /// If autoReconnect is enabled and reconnectConfig is not provided, log an error and return.
    if (autoReconnect && reconnectConfig == null) {
      eventFluxLog(
        "ReconnectConfig is required when autoReconnect is enabled",
        LogEvent.error,
        tag,
      );
      return;
    }

    eventFluxLog("$_status", LogEvent.info, _tag);

    if (reconnectConfig != null) {
      _reconnectStrategy.initialize(reconnectConfig);
    }

    _isExplicitDisconnect = false;

    final config = ConnectionConfig(
      type: type,
      url: url,
      header: header,
      autoReconnect: autoReconnect,
      reconnectConfig: reconnectConfig,
      onSuccessCallback: onSuccessCallback,
      onError: onError,
      onConnectionClose: onConnectionClose,
      httpClient: httpClient,
      body: body,
      tag: tag,
      logReceivedData: logReceivedData,
      files: files,
      multipartRequest: multipartRequest,
      webConfig: webConfig,
      interceptors: interceptors,
      abortTrigger: abortTrigger,
    );

    _start(config);
  }

  /// An internal method to handle the connection process.
  Future<void> _start(ConnectionConfig config) async {
    _onConnectionClose = config.onConnectionClose;

    /// Create a new HTTP client based on the platform if no adapter is present.
    if (config.httpClient == null) {
      client = kIsWeb
          ? FetchClientExtension.fromWebConfig(config.webConfig!)
          : Client();
    }

    _isExplicitDisconnect = false;

    _streamController = StreamController<EventFluxData>();
    _sseParser.reset();

    // On web, remove Cache-Control from request headers. It is not a
    // CORS-safelisted header, so it forces a preflight that most SSE
    // servers reject. On web, caching is controlled by WebConfig.cache
    // via the Fetch API's RequestCache mode instead.
    if (kIsWeb) {
      final h = Map<String, String>.from(config.header);
      h.remove('Cache-Control');
      h.remove('cache-control');
      config = config.copyWithHeader(h);
    }

    BaseRequest request = RequestBuilder.build(config);

    eventFluxLog('Connection Initiated', LogEvent.info, _tag);

    // Run onRequest interceptor chain
    if (config.interceptors != null) {
      try {
        request =
            await InterceptorRunner.runOnRequest(request, config.interceptors);
      } on EventFluxException catch (e) {
        await InterceptorRunner.runOnError(
            e, config.interceptors, config.onError);
        _streamController?.close();
        await _stop();
        return;
      }
    }

    Future<StreamedResponse> response;

    if (config.httpClient != null) {
      response = config.httpClient!.send(request);
    } else {
      response = client!.send(request);
    }

    response.then((data) async {
      eventFluxLog(
        'Connected',
        LogEvent.info,
        _tag,
      );

      eventFluxLog(
        "Status code: ${data.statusCode.toString()}",
        LogEvent.info,
        _tag,
      );

      // Run onResponse interceptor chain
      if (config.interceptors != null) {
        data = await InterceptorRunner.runOnResponse(data, config.interceptors);
      }

      if (data.statusCode != 200) {
        _status = EventFluxStatus.error;
        String responseBody = await data.stream.bytesToString();
        Map<String, dynamic>? errorDetails;
        try {
          errorDetails = jsonDecode(responseBody);
        } catch (e) {
          errorDetails = {'rawBody': responseBody};
        }

        await InterceptorRunner.runOnError(
          EventFluxException(
            statusCode: data.statusCode,
            reasonPhrase: data.reasonPhrase,
            message: errorDetails.toString().isEmpty
                ? data.reasonPhrase
                : errorDetails.toString(),
          ),
          config.interceptors,
          config.onError,
        );

        // Error classification: only reconnect on 5xx, 408, 429
        final shouldRetry = data.statusCode >= 500 ||
            data.statusCode == 408 ||
            data.statusCode == 429;
        if (shouldRetry) {
          _scheduleReconnect(config);
        }
        return;
      }

      // Content-Type validation: must contain text/event-stream
      final contentType = data.headers['content-type'] ?? '';
      if (!contentType.contains('text/event-stream')) {
        await InterceptorRunner.runOnError(
          EventFluxException(
            statusCode: data.statusCode,
            message:
                'Invalid content-type: expected text/event-stream, got $contentType',
          ),
          config.interceptors,
          config.onError,
        );
        await _stop();
        return;
      }

      // Guarded zone for .listen() — defense-in-depth for orphaned stream
      // errors that arrive after subscription cancellation on non-web platforms.
      final guardedZone = Zone.current.fork(
        specification: ZoneSpecification(
          handleUncaughtError: (self, parent, zone, error, stackTrace) {
            if (_isExplicitDisconnect) return;
            eventFluxLog(
                'Unhandled stream error: $error', LogEvent.error, _tag);
          },
        ),
      );

      // Applying transforms and listening to it
      _streamSubscription = guardedZone.run(() => data.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
            (dataLine) {
              // Reset idle timer on every data line (comments count as heartbeats)
              _resetIdleTimer(config);

              final event = _sseParser.processLine(
                dataLine,
                tag: _tag,
                logReceivedData: config.logReceivedData,
                onError: config.onError,
              );

              // Forward server retry interval to reconnect strategy
              final serverRetry = _sseParser.serverRetryInterval;
              if (serverRetry != null) {
                _reconnectStrategy.updateRetryInterval(serverRetry);
              }

              if (event != null &&
                  _streamController != null &&
                  !_streamController!.isClosed) {
                _streamController!.add(event);
              }
            },
            cancelOnError: true,
            onDone: () async {
              eventFluxLog('Stream Closed', LogEvent.info, _tag);
              await _stop();

              // When the stream is closed, onClose can be called to execute a function.
              if (_onConnectionClose != null) {
                _onConnectionClose!();
                _onConnectionClose = null;
              }

              _scheduleReconnect(config);
            },
            onError: (error, s) async {
              // Suppress errors caused by explicit disconnect (e.g., FetchClient
              // abort on web emits a ClientException when the client is closed).
              if (_isExplicitDisconnect) return;

              eventFluxLog(
                'Data Stream Listen Error: ${data.statusCode}: $error ',
                LogEvent.error,
                _tag,
              );

              await InterceptorRunner.runOnError(
                EventFluxException(
                  message: error.toString(),
                  statusCode: data.statusCode,
                  reasonPhrase: data.reasonPhrase,
                  originalError: error,
                  stackTrace: s,
                ),
                config.interceptors,
                config.onError,
              );

              _scheduleReconnect(config);
            },
          ));

      if (data.statusCode == 200) {
        _status = EventFluxStatus.connected;
        _reconnectStrategy.resetOnSuccess();
        _resetIdleTimer(config);
        config.onSuccessCallback(
          EventFluxResponse(
            status: EventFluxStatus.connected,
            stream: _streamController!.stream,
          ),
        );
      }
    }).catchError((e) async {
      eventFluxLog('Connection error: $e', LogEvent.error, _tag);
      await InterceptorRunner.runOnError(
        EventFluxException(
          message: e.toString(),
          originalError: e,
          stackTrace: e is Error ? e.stackTrace : null,
        ),
        config.interceptors,
        config.onError,
      );
      _streamController?.close();
      await _stop();
      _scheduleReconnect(config);
    });
  }

  @override
  Future<EventFluxStatus> disconnect() async {
    _isExplicitDisconnect = true;
    _reconnectStrategy.clear();
    _sseParser.fullReset();
    final status = await _stop();
    if (_onConnectionClose != null) {
      _onConnectionClose!();
      _onConnectionClose = null;
    }
    return status;
  }

  /// Internal method to handle disconnection.
  Future<EventFluxStatus> _stop() async {
    eventFluxLog('Disconnecting', LogEvent.info, _tag);
    try {
      _idleTimer?.cancel();
      _idleTimer = null;
      final sub = _streamSubscription;
      final ctrl = _streamController;
      _streamSubscription = null;
      _streamController = null;
      sub?.cancel();
      ctrl?.close();
      if (!kIsWeb) {
        client?.close();
      }
      client = null;
      eventFluxLog('Disconnected', LogEvent.info, _tag);
      _status = EventFluxStatus.disconnected;
      return _status;
    } catch (error) {
      eventFluxLog('Disconnected $error', LogEvent.info, _tag);
      return EventFluxStatus.error;
    }
  }

  /// Resets the idle timer. If no data arrives within the configured
  /// [connectionTimeout], the connection is stopped and a reconnect
  /// is scheduled.
  void _resetIdleTimer(ConnectionConfig config) {
    _idleTimer?.cancel();
    _idleTimer = null;
    final timeout = config.reconnectConfig?.connectionTimeout;
    if (timeout == null) return;
    _idleTimer = Timer(timeout, () async {
      eventFluxLog('Idle timeout fired', LogEvent.info, _tag);
      await _stop();
      if (_onConnectionClose != null) {
        _onConnectionClose!();
        _onConnectionClose = null;
      }
      _scheduleReconnect(config);
    });
  }

  /// Schedules a reconnect attempt via [ReconnectStrategy] if conditions are met.
  Future<void> _scheduleReconnect(ConnectionConfig config) async {
    ConnectionConfig effectiveConfig = config;
    await _reconnectStrategy.attemptIfNeeded(
      autoReconnect: config.autoReconnect,
      isExplicitDisconnect: () => _isExplicitDisconnect,
      tag: _tag,
      refreshHeaders: () async {
        if (_reconnectStrategy.config?.reconnectHeader != null) {
          final h = await _reconnectStrategy.config!.reconnectHeader!();
          effectiveConfig = config.copyWithHeader(h);
        }
      },
      startConnection: () {
        _status = EventFluxStatus.reconnecting;
        // Inject Last-Event-ID header on reconnect
        final lastId = _sseParser.lastEventId;
        if (lastId.isNotEmpty) {
          final merged = Map<String, String>.from(effectiveConfig.header);
          merged['Last-Event-ID'] = lastId;
          effectiveConfig = effectiveConfig.copyWithHeader(merged);
        }
        _start(effectiveConfig);
      },
      stopConnection: () => _stop(),
    );
  }
}
