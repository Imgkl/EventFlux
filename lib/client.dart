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
import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/models/response.dart';
import 'package:eventflux/models/web_config/web_config.dart';
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
  ReconnectConfig? _reconnectConfig;
  EventFluxStatus _status = EventFluxStatus.disconnected;
  int _maxAttempts = 0;
  int _interval = 0;
  String? _tag;

  /// Factory method for spawning new instances of `EventFlux`.
  ///
  /// This method creates and returns a new instance of `EventFlux`. It's useful
  /// for scenarios where multiple, separate `EventFlux` instances are needed,
  /// each operating independently from one another. This allows for different
  /// SSE connections or functionalities to be managed separately within the same application.
  ///
  /// Returns:
  ///   - A new `EventFlux` instance.
  ///
  /// Usage Example:
  /// ```dart
  /// EventFlux eventFluxInstance1 = EventFlux.spawn();
  /// EventFlux eventFluxInstance2 = EventFlux.spawn();
  ///
  ///
  /// eventFluxInstance1.connect(/* connection parameters */);
  /// eventFluxInstance2.connect(/* connection parameters */);
  /// ```
  ///
  /// This method is ideal when distinct, isolated instances of `EventFlux` are required,
  /// offering more control over multiple SSE connections.
  static EventFlux spawn() {
    return EventFlux._();
  }

  /// Establishes a connection to a server-sent event (SSE) stream.
  ///
  /// This method sets up a connection to an SSE stream based on the provided URL and connection type.
  /// It handles the data stream, manages errors, and implements an auto-reconnection mechanism.
  ///
  /// Parameters:
  ///   - `type`: The type of HTTP connection to be used (GET or POST).
  ///   - `url`: The URL of the SSE stream to connect to.
  ///   - `header`: HTTP headers for the request. Defaults to accepting 'text/event-stream'.
  ///   - `onConnectionClose`: Callback function that is called when the connection is closed.
  ///   - `autoReconnect`: Boolean value that determines if the connection should be
  ///     automatically reestablished when interrupted. Defaults to `false`.
  ///   - `reconnectConfig`: Optional configuration for reconnection attempts. Required if `autoReconnect` is enabled.
  ///   - `onSuccessCallback`: Required callback function that is called upon a successful
  ///     connection. It provides an `EventFluxResponse` object containing the connection status and data stream.
  ///   - `onError`: Callback function for handling errors that occur during the connection
  ///     or data streaming process. It receives an `EventFluxException` object.
  ///   - `body`: Optional body for POST request types.
  ///   - `tag`: Optional tag to identify the connection.
  ///   - `logReceivedData`: Boolean value that determines if received data should be logged. Defaults to `false`.
  ///   - `files`: Optional list of files to be sent with the request.
  ///   - `multipartRequest`: Boolean value that determines if the request is a multipart request. Defaults to `false`.
  ///   - `httpClient`: Optional HTTP client adapter to be used for the connection.
  ///
  ///
  /// The method initializes an HTTP client and a StreamController for managing the SSE data.
  /// It creates an HTTP request based on the specified `type`, `url`, `header`, and `body`.
  /// Upon receiving the response, it checks the status code for success (200) and proceeds
  /// to listen to the stream. It parses each line of the incoming data to construct `EventFluxData` objects
  /// which are then added to the stream controller.
  ///
  /// The method includes error handling within the stream's `onError` callback, which involves
  /// invoking the provided `onError` function, adding the error to the stream controller, and
  /// potentially triggering a reconnection attempt if `autoReconnect` is `true`.
  ///
  /// In the case of stream closure (`onDone`), it disconnects the client, triggers the `onConnectionClose`
  /// callback, and, if `autoReconnect` is enabled, schedules a reconnection attempt after a delay.
  ///
  /// Usage Example:
  /// ```dart
  /// EventFlux eventFlux = EventFlux.instance;
  /// eventFlux.connect(
  ///   EventFluxConnectionType.get,
  ///   'https://example.com/events',
  ///   onSuccessCallback: (response) {
  ///     response.stream?.listen((data) {
  ///       // Handle incoming data
  ///     });
  ///   },
  ///   onError: (exception) {
  ///     // Handle error
  ///   },
  ///   autoReconnect: true
  ///   reconnectConfig: ReconnectConfig(
  ///   mode: ReconnectMode.linear || ReconnectMode.exponential,
  ///   interval: const Duration(seconds: 2),
  ///   maxAttempts: 5,
  ///   reconnectCallback: () {},
  /// ),
  /// );
  /// ```
  ///
  /// This method is crucial for establishing and maintaining a stable connection to an SSE stream,
  /// handling data and errors efficiently, and providing a resilient connection experience with
  /// its auto-reconnect capability.
  @override
  void connect(
    EventFluxConnectionType type,
    String url, {
    Map<String, String> header = const {'Accept': 'text/event-stream'},
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

    /// Optional web config to be used for the connection. Must be provided on web.
    /// Will be ignored on non-web platforms.
    WebConfig? webConfig,
  }) {

    assert(!(kIsWeb && webConfig == null), 'WebConfig must be provided on web');
    // This check prevents redundant connection requests when a connection is already in progress.
    // This does not prevent reconnection attempts if autoReconnect is enabled.

    // When using `spawn`, the `_status` is `disconnected` by default. so this check will always be false.
    if (_status == EventFluxStatus.connected ||
        _status == EventFluxStatus.connectionInitiated) {
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

    /// If autoReconnect is enabled, set the maximum attempts and interval based on the reconnect configuration.
    if (reconnectConfig != null) {
      _reconnectConfig = reconnectConfig;
      _maxAttempts = reconnectConfig.maxAttempts;
      _interval = reconnectConfig.interval.inSeconds;
    }

    _isExplicitDisconnect = false;

    _start(
      type,
      url,
      header: header,
      autoReconnect: autoReconnect,
      onSuccessCallback: onSuccessCallback,
      onError: onError,
      onConnectionClose: onConnectionClose,
      body: body,
      httpClient: httpClient,
      logReceivedData: logReceivedData,
      files: files,
      multipartRequest: multipartRequest,
      webConfig: webConfig,
    );
  }

  /// An internal method to handle the connection process.
  /// this is abstracted out to set the `_isExplicitDisconnect` variable to `false` before connecting.
  void _start(
    EventFluxConnectionType type,
    String url, {
    Map<String, String> header = const {'Accept': 'text/event-stream'},
    Function()? onConnectionClose,
    bool autoReconnect = false,
    required Function(EventFluxResponse?) onSuccessCallback,
    Function(EventFluxException)? onError,
    Map<String, dynamic>? body,
    HttpClientAdapter? httpClient,
    bool logReceivedData = false,
    List<MultipartFile>? files,
    bool multipartRequest = false,
    WebConfig? webConfig,
  }) {
    /// Initalise variables
    /// Create a new HTTP client based on the platform
    /// Uses and internal http client if no http client adapter is present
    if (httpClient == null) {
      client =
          kIsWeb ? FetchClientExtension.fromWebConfig(webConfig!) : Client();
    }

    /// Set `_isExplicitDisconnect` to `false` before connecting.
    _isExplicitDisconnect = false;

    _streamController = StreamController<EventFluxData>();
    RegExp lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');
    EventFluxData currentEventFluxData =
        EventFluxData(data: '', id: '', event: '');

    BaseRequest request = switch ((multipartRequest, files?.isNotEmpty)) {
      (true, _) || (_, true) => () {
          final request = MultipartRequest(
            type == EventFluxConnectionType.get ? 'GET' : 'POST',
            Uri.parse(url),
          );
          if (header.isNotEmpty) {
            request.headers.addAll(header);
          }
          if (body != null) {
            request.fields.addAll(
              body.map(
                (key, value) => MapEntry(key, value),
              ),
            );
          }
          if (files != null) {
            for (final file in files) {
              request.files.add(file);
            }
          }
          return request;
        }(),
      _ => () {
          final request = Request(
            type == EventFluxConnectionType.get ? 'GET' : 'POST',
            Uri.parse(url),
          );
          if (header.isNotEmpty) {
            request.headers.addAll(header);
          }
          if (body != null) {
            request.body = jsonEncode(body);
          }
          return request;
        }(),
    };

    eventFluxLog('Connection Initiated', LogEvent.info, _tag);

    Future<StreamedResponse> response;

    if (httpClient != null) {
      // Use external HTTP client
      response = httpClient.send(request);
    } else {
      // Use internal HTTP client
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

      if (data.statusCode < 200 || data.statusCode >= 300) {
        _status = EventFluxStatus.connected;
        String responseBody = await data.stream.bytesToString();
        if (onError != null) {
          Map<String, dynamic>? errorDetails;
          try {
            errorDetails = jsonDecode(responseBody);
          } catch (e) {
            errorDetails = {'rawBody': responseBody};
          }

          onError(
            EventFluxException(
              statusCode: data.statusCode,
              reasonPhrase: data.reasonPhrase,
              message: errorDetails.toString().isEmpty
                  ? data.reasonPhrase
                  : errorDetails.toString(),
            ),
          );
        }
        return;
      }

      if (autoReconnect && data.statusCode != 200) {
        _attemptReconnectIfNeeded(
          _isExplicitDisconnect,
          autoReconnect,
          type,
          url,
          header,
          onSuccessCallback,
          onError: onError,
          onConnectionClose: onConnectionClose,
          httpClient: httpClient,
          body: body,
          files: files,
          multipartRequest: multipartRequest,
        );
        return;
      }

      // Applying transforms and listening to it
      _streamSubscription = data.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
            (dataLine) {
              if (dataLine.isEmpty) {
                /// When the data line is empty, it indicates that the complete event set has been read.
                /// The event is then added to the stream.
                if (!_streamController!.isClosed) {
                  _streamController!.add(currentEventFluxData);
                }
                if (logReceivedData) {
                  eventFluxLog(
                    currentEventFluxData.data.toString(),
                    LogEvent.info,
                    _tag,
                  );
                }
                currentEventFluxData =
                    EventFluxData(data: '', id: '', event: '');
                return;
              }

              // Parsing each line through the regex.
              Match match = lineRegex.firstMatch(dataLine)!;
              var field = match.group(1);
              if (field!.isEmpty) {
                return;
              }
              var value = '';
              if (field == 'data') {
                // If the field is data, we get the data through the substring
                value = dataLine.substring(5);
              } else {
                value = match.group(2) ?? '';
              }
              switch (field) {
                case 'event':
                  currentEventFluxData.event = value;
                  break;
                case 'data':
                  currentEventFluxData.data =
                      '${currentEventFluxData.data}$value\n';
                  break;
                case 'id':
                  currentEventFluxData.id = value;
                  break;
                case 'retry':
                  break;
              }
            },
            cancelOnError: true,
            onDone: () async {
              eventFluxLog('Stream Closed', LogEvent.info, _tag);
              await _stop();

              // When the stream is closed, onClose can be called to execute a function.
              if (onConnectionClose != null) onConnectionClose();

              _attemptReconnectIfNeeded(
                _isExplicitDisconnect,
                autoReconnect,
                type,
                url,
                header,
                onSuccessCallback,
                onError: onError,
                onConnectionClose: onConnectionClose,
                httpClient: httpClient,
                body: body,
                files: files,
                multipartRequest: multipartRequest,
              );
            },
            onError: (error, s) async {
              eventFluxLog(
                'Data Stream Listen Error: ${data.statusCode}: $error ',
                LogEvent.error,
                _tag,
              );

              // Executes the onError function if it is not null
              if (onError != null) {
                onError(EventFluxException(
                  message: error.toString(),
                  statusCode: data.statusCode,
                  reasonPhrase: data.reasonPhrase,
                ));
              }

              _attemptReconnectIfNeeded(
                _isExplicitDisconnect,
                autoReconnect,
                type,
                url,
                header,
                onSuccessCallback,
                onError: onError,
                onConnectionClose: onConnectionClose,
                httpClient: httpClient,
                body: body,
                files: files,
                multipartRequest: multipartRequest,
              );
            },
          );

      if (data.statusCode == 200) {
        onSuccessCallback(
          EventFluxResponse(
            status: EventFluxStatus.connected,
            stream: _streamController!.stream,
          ),
        );
      }
    }).catchError((e) async {
      if (onError != null) {
        onError(EventFluxException(message: e.toString()));
      }
      await _stop();
      _attemptReconnectIfNeeded(
        _isExplicitDisconnect,
        autoReconnect,
        type,
        url,
        header,
        onSuccessCallback,
        onError: onError,
        onConnectionClose: onConnectionClose,
        httpClient: httpClient,
        body: body,
        files: files,
        multipartRequest: multipartRequest,
      );
    });
  }

  /// Disconnects from the event stream.
  ///
  /// Closes the HTTP client and the stream controller.
  /// Returns the disconnection status enum.
  ///
  /// Usage Example:
  /// ```dart
  /// EventFluxStatus disconnectStatus = await EventFlux.instance.disconnect();
  /// print(disconnectStatus.name);
  /// ```
  @override
  Future<EventFluxStatus> disconnect() async {
    _isExplicitDisconnect = true;
    _reconnectConfig = null;
    return await _stop();
  }

  /// Internal method to handle disconnection.
  /// this is abstracted out to set the `_isExplicitDisconnect` variable to `true` while disconnecting.
  /// This is to prevent reconnection if the user has explicitly disconnected.
  /// This returns the disconnection status enum.
  Future<EventFluxStatus> _stop() async {
    eventFluxLog('Disconnecting', LogEvent.info, _tag);
    try {
      _streamSubscription?.cancel();
      _streamController?.close();
      client?.close();
      Future.delayed(const Duration(seconds: 1), () {});
      eventFluxLog('Disconnected', LogEvent.info, _tag);
      _status = EventFluxStatus.disconnected;
      return _status;
    } catch (error) {
      eventFluxLog('Disconnected $error', LogEvent.info, _tag);
      return EventFluxStatus.error;
    }
  }

  /// Internal method to handle reconnection with a delay.
  ///
  /// This method is triggered in case of disconnection, especially
  /// when `autoReconnect` is enabled. It waits for a specified duration (2 seconds),
  /// before attempting to reconnect.
  void _attemptReconnectIfNeeded(
    /// If _isExplicitDisconnect is `true`, it does not attempt to reconnect. This is to prevent reconnection if the user has explicitly disconnected.
    /// This is an internal variable, this doen't mean anything to the user.
    bool isExplicitDisconnect,
    bool autoReconnect,
    EventFluxConnectionType type,
    String url,
    Map<String, String> header,
    Function(EventFluxResponse?) onSuccessCallback, {
    Function(EventFluxException)? onError,
    Function()? onConnectionClose,
    HttpClientAdapter? httpClient,
    Map<String, dynamic>? body,
    List<MultipartFile>? files,
    bool multipartRequest = false,
  }) async {
    /// If autoReconnect is enabled and the user has not explicitly disconnected, it attempts to reconnect.
    if (autoReconnect && !isExplicitDisconnect && _reconnectConfig != null) {
      /// If the reconnection mode is linear, the interval remains constant.

      /// If the maximum attempts is -1, it means there is no limit to the number of attempts.
      if (_maxAttempts != -1) {
        /// If the maximum attempts are exhausted, it stops the connection.
        if (_maxAttempts == 0) {
          _stop();
          return;
        }

        /// _maxAttempts is decremented after each attempt.
        _maxAttempts--;
      }

      // If a reconnectHeader is provided, it is executed to get the header.
      if (_reconnectConfig!.reconnectHeader != null) {
        header = await _reconnectConfig!.reconnectHeader!();
      }

      if (isExplicitDisconnect) {
        eventFluxLog("Explicit disconnection. Aborting retry attempts",
            LogEvent.info, _tag);
        return; // Exit early if an explicit disconnect occurred.
      }

      switch (_reconnectConfig!.mode) {
        case ReconnectMode.linear:

          /// It waits for the specified constant interval before attempting to reconnect.
          await Future.delayed(_reconnectConfig!.interval, () {
            if (!isExplicitDisconnect) {
              eventFluxLog("Trying again in ${_interval.toString()} seconds",
                  LogEvent.reconnect, _tag);
              _status = EventFluxStatus.connectionInitiated;
              _start(
                type,
                url,
                onSuccessCallback: onSuccessCallback,
                autoReconnect: autoReconnect,
                onError: onError,
                header: header,
                onConnectionClose: onConnectionClose,
                httpClient: httpClient,
                body: body,
                files: files,
                multipartRequest: multipartRequest,
              );
            }
          });
          break;

        case ReconnectMode.exponential:

          /// It waits for the specified interval before attempting to reconnect.
          await Future.delayed(Duration(seconds: _interval), () {
            _interval = _interval * 2;
            if (!isExplicitDisconnect) {
              eventFluxLog("Trying again in ${_interval.toString()} seconds",
                  LogEvent.reconnect, _tag);

              _status = EventFluxStatus.connectionInitiated;
              _start(
                type,
                url,
                onSuccessCallback: onSuccessCallback,
                autoReconnect: autoReconnect,
                onError: onError,
                header: header,
                onConnectionClose: onConnectionClose,
                httpClient: httpClient,
                body: body,
                files: files,
                multipartRequest: multipartRequest,
              );
            }

          });
          break;
      }
      if (_reconnectConfig != null && _reconnectConfig?.onReconnect != null) {
        _reconnectConfig!.onReconnect!();
      }
    }
  }
}
