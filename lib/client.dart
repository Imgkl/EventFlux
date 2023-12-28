/// Imports

import 'dart:async';
import 'dart:convert';

import 'package:eventflux/enum.dart';
import 'package:eventflux/models/base.dart';
import 'package:eventflux/models/data.dart';
import 'package:eventflux/models/exception.dart';
import 'package:eventflux/models/response.dart';
import 'package:eventflux/utils.dart';
import 'package:http/http.dart';

/// A class for managing event-driven data streams using Server-Sent Events (SSE).
///
/// `EventFlux` facilitates the connection, disconnection, and management of SSE streams.
/// It implements the Singleton pattern to ensure a single instance handles SSE streams throughout the application.
class EventFlux extends EventFluxBase {
  EventFlux._();
  static final EventFlux _instance = EventFlux._();

  static EventFlux get instance => _instance;
  Client? _client;
  StreamController<EventFluxData>? _streamController;

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
  ///   - `onSuccessCallback`: Required callback function that is called upon a successful
  ///     connection. It provides an `EventFluxResponse` object containing the connection status and data stream.
  ///   - `onError`: Callback function for handling errors that occur during the connection
  ///     or data streaming process. It receives an `EventFluxException` object.
  ///   - `body`: Optional body for POST request types.
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
  /// );
  /// ```
  ///
  /// This method is crucial for establishing and maintaining a stable connection to an SSE stream,
  /// handling data and errors efficiently, and providing a resilient connection experience with
  /// its auto-reconnect capability.
  @override
  void connect(EventFluxConnectionType type, String url,
      {Map<String, String> header = const {'Accept': 'text/event-stream'},
      Function()? onConnectionClose,
      bool autoReconnect = false,
      required Function(EventFluxResponse?) onSuccessCallback,
      Function(EventFluxException)? onError,
      Map<String, dynamic>? body}) {
    /// Initalise variables
    _client = Client();

    _streamController = StreamController<EventFluxData>();
    RegExp lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');
    EventFluxData currentEventFluxData =
        EventFluxData(data: '', id: '', event: '');

    Request request = Request(
      type == EventFluxConnectionType.get ? 'GET' : 'POST',
      Uri.parse(url),
    );
    if (header.isNotEmpty) {
      request.headers.addAll(header);
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }
    eventFluxLog('Connection Initiated', LogEvent.info);

    Future<StreamedResponse> response = _client!.send(request);

    eventFluxLog("Somthing printing here", LogEvent.info);

    response.then((data) async {
      eventFluxLog('Connected', LogEvent.info);

      eventFluxLog("Status code: ${data.statusCode.toString()}", LogEvent.info);

      if (autoReconnect && data.statusCode != 200) {
        _reconnectWithDelay(autoReconnect, type, url, onSuccessCallback,
            onError: onError, onConnectionClose: onConnectionClose, body: body);
        return;
      }

      ///Applying transforms and listening to it
      data.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
            (dataLine) {
              if (dataLine.isEmpty) {
                /// When the data line is empty, it indicates that the complete event set has been read.
                /// The event is then added to the stream.
                _streamController!.add(currentEventFluxData);
                currentEventFluxData =
                    EventFluxData(data: '', id: '', event: '');
                return;
              }

              /// Parsing each line through the regex.
              Match match = lineRegex.firstMatch(dataLine)!;
              var field = match.group(1);
              if (field!.isEmpty) {
                return;
              }
              var value = '';
              if (field == 'data') {
                /// If the field is data, we get the data through the substring
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
                      '${currentEventFluxData.data ?? ''}$value\n';
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
              await disconnect();
              eventFluxLog('Stream Closed', LogEvent.info);

              /// When the stream is closed, onClose can be called to execute a function.
              if (onConnectionClose != null) onConnectionClose();

              _reconnectWithDelay(autoReconnect, type, url, onSuccessCallback,
                  onError: onError,
                  onConnectionClose: onConnectionClose,
                  body: body);
            },
            onError: (error, s) async {
              disconnect();

              eventFluxLog(
                  'Data Stream Listen Error: ${data.statusCode}: $error ',
                  LogEvent.error);

              // /// Executes the onError function if it is not null
              // if (onError != null) {
              //   onError(EventFluxException(message: error.toString()));
              // }

              /// returns the error and the status
              // _streamController
              //     ?.addError(EventFluxException(message: error.toString()));
              _reconnectWithDelay(autoReconnect, type, url, onSuccessCallback,
                  onError: onError,
                  onConnectionClose: onConnectionClose,
                  body: body);
            },
          );
      onSuccessCallback(EventFluxResponse(
          status: EventFluxStatus.connected,
          stream: _streamController!.stream));
    }).catchError((e) async {
      await disconnect();
      _reconnectWithDelay(autoReconnect, type, url, onSuccessCallback,
          onError: onError, onConnectionClose: onConnectionClose, body: body);
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
    eventFluxLog('Disconnecting', LogEvent.info);
    try {
      _streamController!.close();
      _client!.close();
      Future.delayed(const Duration(seconds: 1), () {});
      eventFluxLog('Disconnected', LogEvent.info);
      return EventFluxStatus.disconnected;
    } catch (error) {
      eventFluxLog('Disconnected $error', LogEvent.info);
      return EventFluxStatus.error;
    }
  }

  /// Internal method to handle reconnection with a delay.
  ///
  /// This method is triggered in case of disconnection, especially
  /// when `autoReconnect` is enabled. It waits for a specified duration (2 seconds),
  /// before attempting to reconnect.
  void _reconnectWithDelay(bool autoReconnect, EventFluxConnectionType type,
      String url, Function(EventFluxResponse?) onSuccessCallback,
      {Function(EventFluxException)? onError,
      Function()? onConnectionClose,
      Map<String, dynamic>? body}) async {
    if (autoReconnect) {
      await Future.delayed(const Duration(seconds: 2), () {
        connect(type, url,
            onSuccessCallback: onSuccessCallback,
            autoReconnect: autoReconnect,
            onError: onError,
            onConnectionClose: onConnectionClose,
            body: body);
      });
    }
  }
}
